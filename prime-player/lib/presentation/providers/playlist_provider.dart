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

// ── Channel list ──────────────────────────────────────────────────────────────
final channelsProvider = Provider<List<Channel>>((ref) {
  final id = ref.watch(activePlaylistIdProvider);
  if (id == null) return [];
  return ref.watch(playlistRepositoryProvider).getChannels(id);
});

// ── Content-type filtered channels ───────────────────────────────────────────
final liveChannelsProvider = Provider<List<Channel>>((ref) {
  return ref
      .watch(channelsProvider)
      .where((c) =>
          detectContentType(c.groupTitle, c.streamUrl) == ContentType.live)
      .toList();
});

final movieChannelsProvider = Provider<List<Channel>>((ref) {
  return ref
      .watch(channelsProvider)
      .where((c) =>
          detectContentType(c.groupTitle, c.streamUrl) == ContentType.movie)
      .toList();
});

final seriesChannelsProvider = Provider<List<Channel>>((ref) {
  return ref
      .watch(channelsProvider)
      .where((c) =>
          detectContentType(c.groupTitle, c.streamUrl) == ContentType.series)
      .toList();
});

final radioChannelsProvider = Provider<List<Channel>>((ref) {
  return ref
      .watch(channelsProvider)
      .where((c) =>
          detectContentType(c.groupTitle, c.streamUrl) == ContentType.radio)
      .toList();
});

// ── Category filters ──────────────────────────────────────────────────────────
final activeCategoryProvider = StateProvider<String?>((ref) => null);

final categoriesProvider = Provider<List<String>>((ref) {
  final cats = ref
      .watch(channelsProvider)
      .map((c) => c.groupTitle ?? 'Uncategorized')
      .toSet()
      .toList()
    ..sort();
  return ['All', ...cats];
});

final liveCategoriesProvider = Provider<List<String>>((ref) {
  final cats = ref
      .watch(liveChannelsProvider)
      .map((c) => c.groupTitle ?? 'Uncategorized')
      .toSet()
      .toList()
    ..sort();
  return ['All', ...cats];
});

// ── Filtered channels ─────────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredChannelsProvider = Provider<List<Channel>>((ref) {
  final channels = ref.watch(channelsProvider);
  final category = ref.watch(activeCategoryProvider);
  final query    = ref.watch(searchQueryProvider);

  var result = channels;
  if (category != null && category != 'All') {
    result = result.where((c) => c.groupTitle == category).toList();
  }
  if (query.isNotEmpty) {
    final q = query.toLowerCase();
    result = result.where((c) => c.name.toLowerCase().contains(q)).toList();
  }
  return result;
});

final filteredLiveChannelsProvider = Provider<List<Channel>>((ref) {
  final channels = ref.watch(liveChannelsProvider);
  final category = ref.watch(activeCategoryProvider);
  final query    = ref.watch(searchQueryProvider);

  var result = channels;
  if (category != null && category != 'All') {
    result = result.where((c) => c.groupTitle == category).toList();
  }
  if (query.isNotEmpty) {
    final q = query.toLowerCase();
    result = result.where((c) => c.name.toLowerCase().contains(q)).toList();
  }
  return result;
});

// ── Favorites ─────────────────────────────────────────────────────────────────
final favoritesProvider = Provider<List<Channel>>((ref) {
  return ref.watch(playlistRepositoryProvider).getFavorites();
});

// ── Loading state ─────────────────────────────────────────────────────────────
final playlistLoadingProvider = StateProvider<bool>((ref) => false);
final playlistErrorProvider   = StateProvider<String?>((ref) => null);
