import '../models/channel.dart';
import '../models/playlist.dart';
import '../services/m3u_parser.dart';
import '../services/storage_service.dart';
import '../services/xtream_service.dart';

class PlaylistRepository {
  final StorageService _storage;
  PlaylistRepository(this._storage);

  List<Playlist> getSavedPlaylists() => _storage.getPlaylists();

  Future<void> addM3uPlaylist({
    required String name,
    required String url,
  }) async {
    final channels = await M3uParser.fromUrl(url);
    if (channels.isEmpty) {
      throw Exception('No channels found. Check the URL or credentials.');
    }

    final playlist = Playlist(
      id:           DateTime.now().millisecondsSinceEpoch.toString(),
      name:         name,
      type:         'm3u',
      m3uUrl:       url,
      lastUpdated:  DateTime.now(),
      channelCount: channels.length,
    );
    await _storage.savePlaylist(playlist);
    await _storage.saveChannels(playlist.id, channels);
  }

  Future<void> addXtreamPlaylist({
    required String name,
    required String host,
    required String username,
    required String password,
  }) async {
    final svc = XtreamService(
      host: host, username: username, password: password,
    );

    final ok = await svc.authenticate();
    if (!ok) throw Exception('Invalid Xtream Codes credentials');

    final channels = await svc.getLiveChannels();
    final playlist = Playlist(
      id:               DateTime.now().millisecondsSinceEpoch.toString(),
      name:             name,
      type:             'xtream',
      xtreamHost:       host,
      xtreamUsername:   username,
      xtreamPassword:   password,
      lastUpdated:      DateTime.now(),
      channelCount:     channels.length,
    );
    await _storage.savePlaylist(playlist);
    await _storage.saveChannels(playlist.id, channels);
  }

  /// Refreshes a playlist — re-downloads and updates channels.
  Future<void> refreshPlaylist(Playlist playlist) async {
    List<Channel> channels;

    if (playlist.playlistType == PlaylistType.m3u) {
      channels = await M3uParser.fromUrl(playlist.m3uUrl!);
    } else {
      final svc = XtreamService(
        host:     playlist.xtreamHost!,
        username: playlist.xtreamUsername!,
        password: playlist.xtreamPassword!,
      );
      channels = await svc.getLiveChannels();
    }

    playlist.lastUpdated  = DateTime.now();
    playlist.channelCount = channels.length;
    await _storage.savePlaylist(playlist);
    await _storage.saveChannels(playlist.id, channels);
  }

  List<Channel> getChannels(String playlistId) =>
      _storage.getChannels(playlistId);

  List<Channel> getFavorites() => _storage.getFavorites();

  Future<void> toggleFavorite(Channel c) => _storage.toggleFavorite(c);

  Future<void> deletePlaylist(String id) => _storage.deletePlaylist(id);
}
