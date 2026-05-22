import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../../data/models/playlist.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/content_screen_layout.dart';
import 'player_screen.dart';

class MovieDetailScreen extends ConsumerStatefulWidget {
  final Channel movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  Map<String, dynamic>? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchInfo());
  }

  Future<void> _fetchInfo() async {
    final id = ref.read(activePlaylistIdProvider);
    if (id == null) { setState(() => _loading = false); return; }

    final playlist = ref.read(playlistRepositoryProvider)
        .getSavedPlaylists()
        .cast<Playlist?>()
        .firstWhere((p) => p?.id == id, orElse: () => null);

    if (playlist == null || playlist.playlistType != PlaylistType.xtream) {
      setState(() => _loading = false);
      return;
    }

    // Extract numeric VOD id from channel id (format: "vod_12345")
    final vodId = widget.movie.id.replaceFirst('vod_', '');
    try {
      final data = await ref.read(playlistRepositoryProvider)
          .getVodInfo(playlist, vodId);
      if (mounted) setState(() { _info = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _watchNow() {
    ref.read(playerProvider.notifier).openChannel(widget.movie);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const PlayerScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void _openExternal() {
    ref.read(playerProvider.notifier).openUrlInExternalPlayer(
        widget.movie.streamUrl);
  }

  @override
  Widget build(BuildContext context) {
    final info = (_info?['info'] as Map<String, dynamic>?) ?? {};

    final posterUrl  = (info['movie_image'] as String?)?.trim()
        ?? widget.movie.logoUrl ?? '';
    final title      = widget.movie.name;
    final plot       = (info['plot'] as String?)?.trim() ?? '';
    final director   = (info['director'] as String?)?.trim() ?? '';
    final cast       = (info['cast'] as String?)?.trim() ?? '';
    final release    = (info['releasedate'] as String?)?.trim()
        ?? (info['release_date'] as String?)?.trim() ?? '';
    final duration   = (info['duration'] as String?)?.trim() ?? '';
    final age        = (info['age'] as String?)?.trim() ?? '';
    final genre      = (info['genre'] as String?)?.trim() ?? '';
    final ratingRaw  = info['rating_5based'];
    final rating     = ratingRaw is num
        ? ratingRaw.toDouble()
        : double.tryParse(ratingRaw?.toString() ?? '') ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          // ── Top bar ──────────────────────────────────────────────────────
          Container(
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textSecondary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2.5))
                : _buildContent(
                    posterUrl: posterUrl,
                    title: title,
                    plot: plot,
                    director: director,
                    cast: cast,
                    release: release,
                    duration: duration,
                    age: age,
                    genre: genre,
                    rating: rating,
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent({
    required String posterUrl,
    required String title,
    required String plot,
    required String director,
    required String cast,
    required String release,
    required String duration,
    required String age,
    required String genre,
    required double rating,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: Poster ─────────────────────────────────────────────────
        Container(
          width: 240,
          color: AppColors.surface,
          child: Column(
            children: [
              // Poster
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.4),
                          blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: posterUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 200),
                          errorWidget: (_, __, ___) =>
                              _PosterFallback(title),
                          placeholder: (_, __) =>
                              Container(color: AppColors.surfaceLight),
                        )
                      : _PosterFallback(title),
                ),
              ),

              // Star rating
              if (rating > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _StarRating(value: rating),
                ),
            ],
          ),
        ),

        const VerticalDivider(width: 1, color: AppColors.border),

        // ── Right: Info ──────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),

                // Metadata rows
                if (release.isNotEmpty)
                  _MetaRow(label: 'تاريخ الإصدار', value: release),
                if (duration.isNotEmpty)
                  _MetaRow(label: 'المدة', value: duration),
                if (age.isNotEmpty)
                  _MetaRow(label: 'العمر', value: age),
                if (genre.isNotEmpty)
                  _MetaRow(label: 'النوع', value: genre),
                if (director.isNotEmpty)
                  _MetaRow(label: 'المخرج', value: director),
                if (cast.isNotEmpty)
                  _MetaRow(label: 'طاقم التمثيل', value: cast),

                if (plot.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(height: 2, width: 48,
                      decoration: BoxDecoration(
                          gradient: kPrimeGradient,
                          borderRadius: BorderRadius.circular(1))),
                  const SizedBox(height: 12),
                  Text(plot,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.6)),
                ],

                const SizedBox(height: 32),

                // Action buttons
                Row(children: [
                  // Watch Now
                  Expanded(
                    child: GestureDetector(
                      onTap: _watchNow,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: kPrimeGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 22),
                            SizedBox(width: 6),
                            Text('شاهد الآن',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // External player
                  GestureDetector(
                    onTap: _openExternal,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new_rounded,
                              color: AppColors.textSecondary, size: 16),
                          SizedBox(width: 6),
                          Text('مشغل خارجي',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Metadata row ──────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Star rating ───────────────────────────────────────────────────────────────
class _StarRating extends StatelessWidget {
  final double value; // 0–5
  const _StarRating({required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = value >= i + 1;
        final half   = !filled && value >= i + 0.5;
        return Icon(
          filled ? Icons.star_rounded
              : half ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          color: filled || half ? const Color(0xFFFFB300) : Colors.white24,
          size: 18,
        );
      }),
    );
  }
}

// ── Poster fallback ───────────────────────────────────────────────────────────
class _PosterFallback extends StatelessWidget {
  final String name;
  const _PosterFallback(this.name);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface, AppColors.surfaceLight],
          ),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.movie_rounded,
              color: AppColors.textMuted.withOpacity(0.4), size: 40),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(name,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
                maxLines: 3,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );
}
