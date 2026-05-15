import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/content_type.dart';
import '../../data/models/channel.dart';
import '../../data/models/playlist.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../data/services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Override in main() after init');
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepository(ref.watch(storageServiceProvider));
});

// ── Refresh trigger ───────────────────────────────────────────────────────────
final playlistRefreshProvider = StateProvider<int>((ref) => 0);

// ── Active playlist ───────────────────────────────────────────────────────────
final activePlaylistIdProvider = StateProvider<String?>((ref) => null);

final playlistsProvider = Provider<List<Playlist>>((ref) {
  ref.watch(playlistRefreshProvider);
  return ref.watch(playlistRepositoryProvider).getSavedPlaylists();
});

// ── Active playlist object ────────────────────────────────────────────────────
final activePlaylistProvider = Provider<Playlist?>((ref) {
  final id       = ref.watch(activePlaylistIdProvider);
  final playlists = ref.watch(playlistsProvider);
  if (id == null) return null;
  for (final p in playlists) {
    if (p.id == id) return p;
  }
  return playlists.isEmpty ? null : playlists.first;
});

// ── M3U channel list (for ChannelListScreen / general filtering) ──────────────
final channelsProvider = Provider<List<Channel>>((ref) {
  ref.watch(playlistRefreshProvider);
  final id = ref.watch(activePlaylistIdProvider);
  if (id == null) return [];
  // Reads from m3u box — for Xtream playlists this is empty (they use typed providers)
  return ref.watch(storageServiceProvider).getChannels(id);
});

// ── Type-specific channel providers ──────────────────────────────────────────
// For Xtream: reads directly from the type-specific Hive box (no full-scan needed).
// For M3U: filters the m3u box with detectContentType.

List<Channel> _getTyped(
  String? id,
  PlaylistType? type,
  StorageService storage,
  ContentType contentType,
  String xtreamPrefix,
) {
  if (id == null) return [];
  if (type == PlaylistType.xtream) {
    return storage.getChannels(id, typePrefix: xtreamPrefix);
  }
  // M3U: filter by content-type detection
  return storage.getChannels(id)
      .where((c) => detectContentType(c.groupTitle, c.streamUrl) == contentType)
      .toList();
}

final liveChannelsProvider = Provider<List<Channel>>((ref) {
  ref.watch(playlistRefreshProvider);
  final playlist = ref.watch(activePlaylistProvider);
  final storage  = ref.watch(storageServiceProvider);
  return _getTyped(playlist?.id, playlist?.playlistType, storage,
      ContentType.live, 'live_');
});

final movieChannelsProvider = Provider<List<Channel>>((ref) {
  ref.watch(playlistRefreshProvider);
  final playlist = ref.watch(activePlaylistProvider);
  final storage  = ref.watch(storageServiceProvider);
  return _getTyped(playlist?.id, playlist?.playlistType, storage,
      ContentType.movie, 'vod_');
});

final seriesChannelsProvider = Provider<List<Channel>>((ref) {
  ref.watch(playlistRefreshProvider);
  final playlist = ref.watch(activePlaylistProvider);
  final storage  = ref.watch(storageServiceProvider);
  return _getTyped(playlist?.id, playlist?.playlistType, storage,
      ContentType.series, 'series_');
});

final radioChannelsProvider = Provider<List<Channel>>((ref) {
  ref.watch(playlistRefreshProvider);
  final playlist = ref.watch(activePlaylistProvider);
  final storage  = ref.watch(storageServiceProvider);
  if (playlist?.id == null) return [];
  // Radios live inside the live channels box for Xtream, m3u box for M3U
  final prefix = playlist?.playlistType == PlaylistType.xtream ? 'live_' : null;
  return storage.getChannels(playlist!.id, typePrefix: prefix)
      .where((c) => detectContentType(c.groupTitle, c.streamUrl) == ContentType.radio)
      .toList();
});

// ── Fast channel counts (key-only iteration — no object deserialization) ──────
final liveCountProvider = Provider<int>((ref) {
  ref.watch(playlistRefreshProvider);
  final playlist = ref.watch(activePlaylistProvider);
  if (playlist == null) return 0;
  final storage = ref.watch(storageServiceProvider);
  if (playlist.playlistType == PlaylistType.xtream) {
    return storage.countChannels(playlist.id, typePrefix: 'live_');
  }
  return ref.watch(liveChannelsProvider).length;
});

final movieCountProvider = Provider<int>((ref) {
  ref.watch(playlistRefreshProvider);
  final playlist = ref.watch(activePlaylistProvider);
  if (playlist == null) return 0;
  final storage = ref.watch(storageServiceProvider);
  if (playlist.playlistType == PlaylistType.xtream) {
    return storage.countChannels(playlist.id, typePrefix: 'vod_');
  }
  return ref.watch(movieChannelsProvider).length;
});

final seriesCountProvider = Provider<int>((ref) {
  ref.watch(playlistRefreshProvider);
  final playlist = ref.watch(activePlaylistProvider);
  if (playlist == null) return 0;
  final storage = ref.watch(storageServiceProvider);
  if (playlist.playlistType == PlaylistType.xtream) {
    return storage.countChannels(playlist.id, typePrefix: 'series_');
  }
  return ref.watch(seriesChannelsProvider).length;
});

// ── Category filters ──────────────────────────────────────────────────────────
final activeCategoryProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider    = StateProvider<String>((ref) => '');

List<String> _buildCategories(List<Channel> channels) {
  final cats = channels
      .map((c) => c.groupTitle ?? 'Uncategorized')
      .toSet()
      .toList()
    ..sort();
  return ['All', ...cats];
}

List<Channel> _applyFilter(List<Channel> channels, String? cat, String q) {
  var result = channels;
  if (cat != null && cat != 'All') {
    result = result.where((c) => c.groupTitle == cat).toList();
  }
  if (q.isNotEmpty) {
    final lq = q.toLowerCase();
    result = result.where((c) => c.name.toLowerCase().contains(lq)).toList();
  }
  return result;
}

final categoriesProvider = Provider<List<String>>((ref) =>
    _buildCategories(ref.watch(channelsProvider)));

final liveCategoriesProvider = Provider<List<String>>((ref) =>
    _buildCategories(ref.watch(liveChannelsProvider)));

final movieCategoriesProvider = Provider<List<String>>((ref) =>
    _buildCategories(ref.watch(movieChannelsProvider)));

final seriesCategoriesProvider = Provider<List<String>>((ref) =>
    _buildCategories(ref.watch(seriesChannelsProvider)));

final radioCategoriesProvider = Provider<List<String>>((ref) =>
    _buildCategories(ref.watch(radioChannelsProvider)));

// ── Filtered channel providers ────────────────────────────────────────────────

final filteredChannelsProvider = Provider<List<Channel>>((ref) =>
    _applyFilter(ref.watch(channelsProvider),
        ref.watch(activeCategoryProvider), ref.watch(searchQueryProvider)));

final filteredLiveChannelsProvider = Provider<List<Channel>>((ref) =>
    _applyFilter(ref.watch(liveChannelsProvider),
        ref.watch(activeCategoryProvider), ref.watch(searchQueryProvider)));

final filteredMovieChannelsProvider = Provider<List<Channel>>((ref) =>
    _applyFilter(ref.watch(movieChannelsProvider),
        ref.watch(activeCategoryProvider), ref.watch(searchQueryProvider)));

final filteredSeriesChannelsProvider = Provider<List<Channel>>((ref) =>
    _applyFilter(ref.watch(seriesChannelsProvider),
        ref.watch(activeCategoryProvider), ref.watch(searchQueryProvider)));

final filteredRadioChannelsProvider = Provider<List<Channel>>((ref) =>
    _applyFilter(ref.watch(radioChannelsProvider),
        ref.watch(activeCategoryProvider), ref.watch(searchQueryProvider)));

// ── Favorites ─────────────────────────────────────────────────────────────────
final favoritesProvider = Provider<List<Channel>>((ref) {
  return ref.watch(playlistRepositoryProvider).getFavorites();
});

// ── Loading state ─────────────────────────────────────────────────────────────
final playlistLoadingProvider = StateProvider<bool>((ref) => false);
final playlistErrorProvider   = StateProvider<String?>((ref) => null);
