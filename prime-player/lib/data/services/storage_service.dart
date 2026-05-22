import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/channel.dart';
import '../models/playlist.dart';

class StorageService {
  static const _playlistBox = 'playlists';
  // One box per content type — avoids scanning all 460k channels on every read
  static const _liveBox     = 'channels_live';
  static const _vodBox      = 'channels_vod';
  static const _seriesBox   = 'channels_series';
  static const _m3uBox      = 'channels_m3u';
  static const _prefsBox    = 'prefs';
  static const _tmdbBox     = 'tmdb_cache';
  static const _posBox      = 'watch_positions'; // int ms; 0 = watched sentinel

  static const _uuid = Uuid();

  late Box<Playlist>              _playlists;
  late Box<Channel>               _live;
  late Box<Channel>               _vod;
  late Box<Channel>               _series;
  late Box<Channel>               _m3u;
  late Box<dynamic>               _prefs;
  late Box<Map<dynamic, dynamic>> _tmdb;
  late Box<int>                   _pos;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(PlaylistAdapter());
    Hive.registerAdapter(ChannelAdapter());

    _playlists = await Hive.openBox<Playlist>(_playlistBox);
    _live      = await Hive.openBox<Channel>(_liveBox);
    _vod       = await Hive.openBox<Channel>(_vodBox);
    _series    = await Hive.openBox<Channel>(_seriesBox);
    _m3u       = await Hive.openBox<Channel>(_m3uBox);
    _prefs     = await Hive.openBox<dynamic>(_prefsBox);
    _tmdb      = await Hive.openBox<Map<dynamic, dynamic>>(_tmdbBox);
    _pos       = await Hive.openBox<int>(_posBox);
  }

  // ── Playlists ──────────────────────────────────────────────────────────────

  List<Playlist> getPlaylists() => _playlists.values.toList();
  Future<void> savePlaylist(Playlist p) => _playlists.put(p.id, p);

  Future<void> deletePlaylist(String id) async {
    await _playlists.delete(id);
    for (final box in [_live, _vod, _series, _m3u]) {
      final keys = box.keys.where((k) => k.toString().startsWith('$id|')).toList();
      if (keys.isNotEmpty) await box.deleteAll(keys);
    }
  }

  // ── Channels ───────────────────────────────────────────────────────────────

  Box<Channel> _boxFor(String? typePrefix) {
    if (typePrefix == 'live_')   return _live;
    if (typePrefix == 'vod_')    return _vod;
    if (typePrefix == 'series_') return _series;
    return _m3u;
  }

  /// Returns channels from the type-specific box.
  /// Pass [typePrefix] ('live_', 'vod_', 'series_') for Xtream.
  /// Omit for M3U playlists (reads from the m3u box).
  List<Channel> getChannels(String playlistId, {String? typePrefix}) {
    final prefix = '$playlistId|';
    final box = _boxFor(typePrefix);
    // Use box.keys instead of c.key — HiveObject.key is only set at write time,
    // not when objects are deserialized from disk on restart.
    return box.keys
        .where((k) => k.toString().startsWith(prefix))
        .map((k) => box.get(k))
        .whereType<Channel>()
        .toList();
  }

  /// Fast channel count using key-only iteration (no object deserialization).
  int countChannels(String playlistId, {String? typePrefix}) {
    final prefix = '$playlistId|';
    return _boxFor(typePrefix).keys
        .where((k) => k.toString().startsWith(prefix))
        .length;
  }

  Future<void> saveChannels(
    String playlistId,
    List<Channel> channels, {
    String? typePrefix,
  }) async {
    final box    = _boxFor(typePrefix);
    final prefix = '$playlistId|';
    final oldKeys = box.keys.where((k) => k.toString().startsWith(prefix)).toList();
    if (oldKeys.isNotEmpty) await box.deleteAll(oldKeys);
    if (channels.isEmpty) return;
    // Write in chunks of 500 — keeps the event loop responsive for large lists
    const chunkSize = 500;
    for (int i = 0; i < channels.length; i += chunkSize) {
      final chunk = channels.skip(i).take(chunkSize);
      await box.putAll({ for (final c in chunk) '$playlistId|${c.id}': c });
    }
  }

  // ── Type-loaded tracking ────────────────────────────────────────────────────

  bool isTypeLoaded(String playlistId, String type) =>
      _prefs.get('loaded_${playlistId}_$type') as bool? ?? false;

  Future<void> markTypeLoaded(String playlistId, String type) =>
      _prefs.put('loaded_${playlistId}_$type', true);

  Future<void> clearLoadedTypes(String playlistId) async {
    await _prefs.delete('loaded_${playlistId}_live');
    await _prefs.delete('loaded_${playlistId}_vod');
    await _prefs.delete('loaded_${playlistId}_series');
  }

  List<Channel> getFavorites() => [
    ..._live.values,
    ..._vod.values,
    ..._series.values,
    ..._m3u.values,
  ].where((c) => c.isFavorite).toList();

  Future<void> toggleFavorite(Channel c) async {
    c.isFavorite = !c.isFavorite;
    await c.save();
  }

  // ── Preferences ────────────────────────────────────────────────────────────

  String? get activePlaylistId => _prefs.get('activePlaylistId') as String?;
  Future<void> setActivePlaylistId(String id) =>
      _prefs.put('activePlaylistId', id);

  String? get lastChannelId => _prefs.get('lastChannelId') as String?;
  Future<void> setLastChannelId(String id) =>
      _prefs.put('lastChannelId', id);

  String get appLanguage =>
      (_prefs.get('language') as String?) ?? 'en';
  Future<void> setAppLanguage(String lang) =>
      _prefs.put('language', lang);

  bool get pinEnabled =>
      (_prefs.get('pinEnabled') as bool?) ?? false;
  Future<void> setPinEnabled(bool v) =>
      _prefs.put('pinEnabled', v);

  String get pinCode =>
      (_prefs.get('pinCode') as String?) ?? '';
  Future<void> setPinCode(String code) =>
      _prefs.put('pinCode', code);

  // ── Device ID ──────────────────────────────────────────────────────────────

  String get deviceId {
    var id = _prefs.get('deviceId') as String?;
    if (id == null) {
      id = _uuid.v4();
      _prefs.put('deviceId', id);
    }
    return id;
  }

  String get macAddress {
    final hex = deviceId.replaceAll('-', '').substring(0, 12).toUpperCase();
    return '${hex.substring(0,2)}:${hex.substring(2,4)}:${hex.substring(4,6)}'
        ':${hex.substring(6,8)}:${hex.substring(8,10)}:${hex.substring(10,12)}';
  }

  String get deviceKey {
    final id = deviceId.replaceAll('-', '');
    int hash = 0;
    for (final c in id.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return (hash % 900000 + 100000).toString();
  }

  // ── TMDB API key ───────────────────────────────────────────────────────────

  String get tmdbApiKey => (_prefs.get('tmdbApiKey') as String?) ?? '';
  Future<void> setTmdbApiKey(String key) => _prefs.put('tmdbApiKey', key.trim());

  // ── TMDB cache ─────────────────────────────────────────────────────────────

  static const _tmdbCacheTtlDays = 30;

  Map<dynamic, dynamic>? getTmdbCache(String key) {
    final entry = _tmdb.get(key);
    if (entry == null) return null;
    // Check TTL
    final ts = entry['_ts'] as int?;
    if (ts != null) {
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > const Duration(days: _tmdbCacheTtlDays).inMilliseconds) {
        _tmdb.delete(key);
        return null;
      }
    }
    return entry;
  }

  Future<void> setTmdbCache(String key, Map<String, dynamic> data) {
    return _tmdb.put(key, {...data, '_ts': DateTime.now().millisecondsSinceEpoch});
  }

  String? getTmdbPosterUrl(String cacheKey) {
    final entry = getTmdbCache(cacheKey);
    if (entry == null) return null;
    final path = entry['posterPath'] as String?;
    if (path == null) return null;
    return 'https://image.tmdb.org/t/p/w500$path';
  }

  // ── Watch positions & watched status ────────────────────────────────────────
  // Convention: 0 = watched (sentinel), >0 = in-progress ms, absent = never

  /// true if the user has watched ≥80% or reached near the end.
  bool isWatched(String channelId)    => _pos.get(channelId) == 0;

  /// true if there is a saved mid-point position (not finished).
  bool hasProgress(String channelId)  {
    final v = _pos.get(channelId);
    return v != null && v > 0;
  }

  /// Returns saved position in ms, or null.
  int? getSavedPositionMs(String channelId) {
    final v = _pos.get(channelId);
    return (v != null && v > 0) ? v : null;
  }

  Future<void> savePositionMs(String channelId, int ms) =>
      _pos.put(channelId, ms);

  Future<void> saveDurationMs(String channelId, int ms) =>
      _pos.put('${channelId}_dur', ms);

  /// Returns progress as 0.0–1.0, or null if no saved in-progress position.
  double? getWatchProgressFraction(String channelId) {
    final pos = _pos.get(channelId);
    if (pos == null || pos <= 0) return null;
    final dur = _pos.get('${channelId}_dur');
    if (dur == null || dur <= 0) return null;
    return (pos / dur).clamp(0.0, 1.0);
  }

  Future<void> markWatched(String channelId) =>
      _pos.put(channelId, 0);       // sentinel

  Future<void> clearWatchData(String channelId) async {
    await _pos.delete(channelId);
    await _pos.delete('${channelId}_dur');
  }

  // ── Watchlist ───────────────────────────────────────────────────────────────
  static const _watchlistKey = 'watchlist_ids';

  List<String> getWatchlistIds() {
    final raw = _prefs.get(_watchlistKey);
    if (raw is List) return List<String>.from(raw);
    return [];
  }

  bool isInWatchlist(String channelId) => getWatchlistIds().contains(channelId);

  Future<void> toggleWatchlist(String channelId) async {
    final ids = getWatchlistIds();
    if (ids.contains(channelId)) ids.remove(channelId); else ids.add(channelId);
    await _prefs.put(_watchlistKey, ids);
  }
}
