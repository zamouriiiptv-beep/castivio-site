import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/name_cleaner.dart';
import '../../data/models/channel.dart';
import '../../data/models/tmdb_result.dart';
import '../../data/services/tmdb_service.dart';
import 'playlist_provider.dart';

// ── TMDB service (null when no API key) ────────────────────────────────────────
final tmdbServiceProvider = Provider<TmdbService?>((ref) {
  final key = ref.watch(storageServiceProvider).tmdbApiKey;
  return key.isEmpty ? null : TmdbService(key);
});

// ── Cache-key helper ────────────────────────────────────────────────────────────
String tmdbCacheKey(Channel ch) {
  final clean = cleanChannelName(ch.name).toLowerCase().trim();
  final year  = _extractYear(ch.name);
  return year != null ? '${clean}_$year' : clean;
}

int? _extractYear(String name) {
  final m = RegExp(r'\((\d{4})\)').firstMatch(name);
  return m != null ? int.tryParse(m.group(1)!) : null;
}

// ── Fetch provider ────────────────────────────────────────────────────────────
// Returns TmdbResult or null (from cache or API)
final tmdbProvider = FutureProvider.autoDispose.family<TmdbResult?, Channel>(
  (ref, channel) async {
    final service = ref.watch(tmdbServiceProvider);
    if (service == null) return null;

    final storage  = ref.read(storageServiceProvider);
    final cacheKey = tmdbCacheKey(channel);

    // Serve from cache if fresh
    final cached = storage.getTmdbCache(cacheKey);
    if (cached != null) return TmdbResult.fromMap(cached);

    // Determine search params
    final cleanName = cleanChannelName(channel.name);
    final year      = _extractYear(channel.name);
    final isTv      = channel.id.startsWith('series_');

    // Fetch from API
    final result = await service.fetch(cleanName, year: year, isTv: isTv);
    if (result == null) return null;

    // Save to cache
    await storage.setTmdbCache(cacheKey, result.toMap());
    return result;
  },
);

// ── Synchronous poster URL from cache (for grid cards) ─────────────────────────
final tmdbCachedPosterProvider = Provider.autoDispose.family<String?, Channel>(
  (ref, channel) {
    final storage = ref.watch(storageServiceProvider);
    return storage.getTmdbPosterUrl(tmdbCacheKey(channel));
  },
);
