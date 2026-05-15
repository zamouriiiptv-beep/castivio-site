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

  // ── M3U ────────────────────────────────────────────────────────────────────

  /// Adds an M3U playlist. If the URL looks like an Xtream Codes URL,
  /// skips the M3U download entirely and saves lazily via the API.
  Future<void> addM3uPlaylist({
    required String name,
    required String url,
  }) async {
    // Detect Xtream URL up-front — skip M3U download, go straight to API
    final creds = M3uParser.extractXtreamCredentials(url);
    if (creds != null) {
      debugPrint('[Repo] Xtream URL detected — skipping M3U download');
      await addXtreamPlaylist(
        name:     name.isEmpty ? 'My Playlist' : name,
        host:     creds['host']!,
        username: creds['username']!,
        password: creds['password']!,
      );
      return;
    }

    // Plain M3U — download and parse as usual
    final channels = await M3uParser.fromUrl(url);
    if (channels.isEmpty) throw Exception('No channels found in M3U playlist.');
    await _saveM3uPlaylist(name: name, url: url, channels: channels);
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

  // ── Xtream ─────────────────────────────────────────────────────────────────

  /// Adds an Xtream playlist. Only authenticates — channels load lazily.
  Future<void> addXtreamPlaylist({
    required String name,
    required String host,
    required String username,
    required String password,
  }) async {
    final svc = XtreamService(host: host, username: username, password: password);
    final authError = await svc.authenticate();
    if (authError != null) throw Exception(authError);

    final playlist = Playlist(
      id:             DateTime.now().millisecondsSinceEpoch.toString(),
      name:           name,
      type:           'xtream',
      xtreamHost:     host,
      xtreamUsername: username,
      xtreamPassword: password,
      lastUpdated:    DateTime.now(),
      channelCount:   0,
    );
    await _storage.savePlaylist(playlist);
  }

  /// Lazily loads live channels for an Xtream playlist.
  Future<void> loadXtreamLive(Playlist playlist) async {
    final channels = await _svcFor(playlist).getLiveChannels();
    await _storage.saveChannels(playlist.id, channels, typePrefix: 'live_');
    await _storage.markTypeLoaded(playlist.id, 'live');
    await _refreshCount(playlist);
  }

  /// Lazily loads VOD (movies) channels for an Xtream playlist.
  Future<void> loadXtreamVod(Playlist playlist) async {
    final channels = await _svcFor(playlist).getVodChannels();
    await _storage.saveChannels(playlist.id, channels, typePrefix: 'vod_');
    await _storage.markTypeLoaded(playlist.id, 'vod');
    await _refreshCount(playlist);
  }

  /// Lazily loads series channels for an Xtream playlist.
  Future<void> loadXtreamSeries(Playlist playlist) async {
    final channels = await _svcFor(playlist).getSeriesChannels();
    await _storage.saveChannels(playlist.id, channels, typePrefix: 'series_');
    await _storage.markTypeLoaded(playlist.id, 'series');
    await _refreshCount(playlist);
  }

  // ── Refresh ────────────────────────────────────────────────────────────────

  Future<void> refreshPlaylist(Playlist playlist) async {
    if (playlist.playlistType == PlaylistType.m3u) {
      final channels = await M3uParser.fromUrl(playlist.m3uUrl!);
      if (channels.isEmpty) return;
      await _storage.saveChannels(playlist.id, channels);
      playlist.lastUpdated  = DateTime.now();
      playlist.channelCount = channels.length;
      await _storage.savePlaylist(playlist);
      return;
    }

    // Xtream: refresh only what has been loaded already
    final futures = <Future>[];
    if (_storage.isTypeLoaded(playlist.id, 'live'))   futures.add(loadXtreamLive(playlist));
    if (_storage.isTypeLoaded(playlist.id, 'vod'))    futures.add(loadXtreamVod(playlist));
    if (_storage.isTypeLoaded(playlist.id, 'series')) futures.add(loadXtreamSeries(playlist));
    if (futures.isNotEmpty) await Future.wait(futures);
    playlist.lastUpdated = DateTime.now();
    await _storage.savePlaylist(playlist);
  }

  // ── Misc ───────────────────────────────────────────────────────────────────

  List<Channel> getChannels(String playlistId) =>
      _storage.getChannels(playlistId);

  List<Channel> getFavorites() => _storage.getFavorites();

  Future<void> toggleFavorite(Channel c) => _storage.toggleFavorite(c);

  Future<void> deletePlaylist(String id) async {
    await _storage.clearLoadedTypes(id);
    await _storage.deletePlaylist(id);
  }

  XtreamService _svcFor(Playlist p) => XtreamService(
        host:     p.xtreamHost!,
        username: p.xtreamUsername!,
        password: p.xtreamPassword!,
      );

  Future<void> _refreshCount(Playlist playlist) async {
    playlist.channelCount = _storage.getChannels(playlist.id).length;
    await _storage.savePlaylist(playlist);
  }
}
