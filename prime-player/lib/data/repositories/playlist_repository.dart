import 'package:flutter/foundation.dart';
import '../models/channel.dart';
import '../models/playlist.dart';
import '../services/m3u_parser.dart';
import '../services/storage_service.dart';
import '../services/xtream_service.dart';

class PlaylistRepository {
  final StorageService _storage;
  PlaylistRepository(this._storage);

  List<Playlist> getSavedPlaylists() => _storage.getPlaylists();

  /// Adds a playlist from an M3U URL.
  /// If the URL is an Xtream Codes URL and M3U fails, automatically falls back
  /// to the Xtream Codes API (which handles 884/885 errors more gracefully).
  Future<void> addM3uPlaylist({
    required String name,
    required String url,
  }) async {
    // Try M3U first
    try {
      final channels = await M3uParser.fromUrl(url);
      if (channels.isEmpty) {
        throw Exception('No channels found in M3U playlist.');
      }
      await _saveM3uPlaylist(name: name, url: url, channels: channels);
      return;
    } catch (m3uError) {
      debugPrint('[Repo] M3U failed: $m3uError');

      // Auto-fallback: try Xtream Codes API if URL has credentials
      final creds = M3uParser.extractXtreamCredentials(url);
      if (creds == null) {
        rethrow; // Not an Xtream URL — no fallback available
      }

      debugPrint('[Repo] Detected Xtream URL — trying API fallback...');
      debugPrint('[Repo] Host: ${creds[\'host\']}  User: ${creds[\'username\']}');

      final svc = XtreamService(
        host:     creds['host']!,
        username: creds['username']!,
        password: creds['password']!,
      );

      final authError = await svc.authenticate();
      if (authError != null) {
        throw Exception(
            'M3U URL failed:\n'
            '${m3uError.toString().replaceFirst("Exception: ", "")}\n\n'
            'Xtream Codes API also failed:\n'
            '$authError');
      }

      debugPrint('[Repo] Xtream auth OK — fetching all channels...');
      final channels = await svc.getAllChannels();

      if (channels.isEmpty) {
        throw Exception(
            'Connected to server but found 0 channels.\n'
            'The account may have no active streams.');
      }

      debugPrint('[Repo] Xtream API returned ${channels.length} channels');

      final playlist = Playlist(
        id:             DateTime.now().millisecondsSinceEpoch.toString(),
        name:           name,
        type:           'xtream',
        xtreamHost:     creds['host']!,
        xtreamUsername: creds['username']!,
        xtreamPassword: creds['password']!,
        lastUpdated:    DateTime.now(),
        channelCount:   channels.length,
      );
      await _storage.savePlaylist(playlist);
      await _storage.saveChannels(playlist.id, channels);
    }
  }

  Future<void> _saveM3uPlaylist({
    required String name,
    required String url,
    required List<Channel> channels,
  }) async {
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

    final authError = await svc.authenticate();
    if (authError != null) throw Exception(authError);

    final channels = await svc.getAllChannels();
    if (channels.isEmpty) {
      throw Exception('Connected but found 0 channels.');
    }

    final playlist = Playlist(
      id:             DateTime.now().millisecondsSinceEpoch.toString(),
      name:           name,
      type:           'xtream',
      xtreamHost:     host,
      xtreamUsername: username,
      xtreamPassword: password,
      lastUpdated:    DateTime.now(),
      channelCount:   channels.length,
    );
    await _storage.savePlaylist(playlist);
    await _storage.saveChannels(playlist.id, channels);
  }

  /// Refreshes a playlist by re-downloading its channels.
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
      channels = await svc.getAllChannels();
    }

    if (channels.isEmpty) return;

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
