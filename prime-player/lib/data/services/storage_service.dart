import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/channel.dart';
import '../models/playlist.dart';

class StorageService {
  static const String _playlistBox = 'playlists';
  static const String _channelBox  = 'channels';
  static const String _prefsBox    = 'prefs';

  static const _uuid = Uuid();

  late Box<Playlist> _playlists;
  late Box<Channel>  _channels;
  late Box<dynamic>  _prefs;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(PlaylistAdapter());
    Hive.registerAdapter(ChannelAdapter());

    _playlists = await Hive.openBox<Playlist>(_playlistBox);
    _channels  = await Hive.openBox<Channel>(_channelBox);
    _prefs     = await Hive.openBox<dynamic>(_prefsBox);
  }

  // ── Playlists ──────────────────────────────────────────────────────────────

  List<Playlist> getPlaylists() => _playlists.values.toList();

  Future<void> savePlaylist(Playlist p) => _playlists.put(p.id, p);

  Future<void> deletePlaylist(String id) async {
    await _playlists.delete(id);
    final keys = _channels.keys.where((k) => k.toString().startsWith('$id|'));
    await _channels.deleteAll(keys);
  }

  // ── Channels ───────────────────────────────────────────────────────────────

  List<Channel> getChannels(String playlistId) => _channels.values
      .where((c) => c.key?.toString().startsWith('$playlistId|') ?? false)
      .toList();

  /// Saves [channels] for [playlistId].
  /// Pass [typePrefix] (e.g. `'live_'`) to replace only that content type,
  /// leaving other types untouched. Omit to replace all channels.
  Future<void> saveChannels(
    String playlistId,
    List<Channel> channels, {
    String? typePrefix,
  }) async {
    final prefix = typePrefix != null
        ? '$playlistId|$typePrefix'
        : '$playlistId|';
    final oldKeys = _channels.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList();
    if (oldKeys.isNotEmpty) await _channels.deleteAll(oldKeys);

    const chunkSize = 500;
    for (var i = 0; i < channels.length; i += chunkSize) {
      final chunk = channels.sublist(i, (i + chunkSize).clamp(0, channels.length));
      final map   = { for (final c in chunk) '$playlistId|${c.id}': c };
      await _channels.putAll(map);
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

  List<Channel> getFavorites() =>
      _channels.values.where((c) => c.isFavorite).toList();

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

  // ── MAC Address (derived from deviceId, stable per install) ───────────────

  String get macAddress {
    final hex = deviceId.replaceAll('-', '').substring(0, 12).toUpperCase();
    return '${hex.substring(0,2)}:${hex.substring(2,4)}:${hex.substring(4,6)}'
        ':${hex.substring(6,8)}:${hex.substring(8,10)}:${hex.substring(10,12)}';
  }

  // ── Device Key — short 6-digit numeric code ────────────────────────────────

  String get deviceKey {
    final id = deviceId.replaceAll('-', '');
    int hash = 0;
    for (final c in id.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return (hash % 900000 + 100000).toString();
  }
}
