import 'package:hive_flutter/hive_flutter.dart';
import '../models/channel.dart';
import '../models/playlist.dart';

class StorageService {
  static const String _playlistBox = 'playlists';
  static const String _channelBox  = 'channels';
  static const String _prefsBox    = 'prefs';

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
    // Remove channels that belong to this playlist
    final keys = _channels.keys.where((k) => k.toString().startsWith('$id|'));
    await _channels.deleteAll(keys);
  }

  // ── Channels ───────────────────────────────────────────────────────────────

  List<Channel> getChannels(String playlistId) => _channels.values
      .where((c) => c.key?.toString().startsWith('$playlistId|') ?? false)
      .toList();

  Future<void> saveChannels(String playlistId, List<Channel> channels) async {
    final map = { for (final c in channels) '$playlistId|${c.id}': c };
    await _channels.putAll(map);
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
}
