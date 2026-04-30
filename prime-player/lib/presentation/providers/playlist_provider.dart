import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// ── Active playlist ───────────────────────────────────────────────────────────
final activePlaylistIdProvider = StateProvider<String?>((ref) => null);

final playlistsProvider = Provider<List<Playlist>>((ref) {
  return ref.watch(playlistRepositoryProvider).getSavedPlaylists();
});

// ── Channel list ──────────────────────────────────────────────────────────────
final channelsProvider = Provider<List<Channel>>((ref) {
  final id = ref.watch(activePlaylistIdProvider);
  if (id == null) return [];
  return ref.watch(playlistRepositoryProvider).getChannels(id);
});

// ── Category filter ───────────────────────────────────────────────────────────
final activeCategoryProvider = StateProvider<String?>((ref) => null);

final categoriesProvider = Provider<List<String>>((ref) {
  final channels = ref.watch(channelsProvider);
  final cats = channels
      .map((c) => c.groupTitle ?? 'Uncategorized')
      .toSet()
      .toList()
    ..sort();
  return ['All', ...cats];
});

final filteredChannelsProvider = Provider<List<Channel>>((ref) {
  final channels  = ref.watch(channelsProvider);
  final category  = ref.watch(activeCategoryProvider);
  final query     = ref.watch(searchQueryProvider);

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

// ── Search ────────────────────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

// ── Favorites ─────────────────────────────────────────────────────────────────
final favoritesProvider = Provider<List<Channel>>((ref) {
  return ref.watch(playlistRepositoryProvider).getFavorites();
});

// ── Loading state ─────────────────────────────────────────────────────────────
final playlistLoadingProvider = StateProvider<bool>((ref) => false);
final playlistErrorProvider   = StateProvider<String?>((ref) => null);
