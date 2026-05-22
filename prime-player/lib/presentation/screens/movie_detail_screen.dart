import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/name_cleaner.dart';
import '../../data/models/channel.dart';
import '../../data/models/tmdb_result.dart';
import '../../data/models/playlist.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/tmdb_provider.dart';
import '../widgets/content_screen_layout.dart';
import 'player_screen.dart';

class MovieDetailScreen extends ConsumerStatefulWidget {
  final Channel movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  Map<String, dynamic>? _xtreamInfo;
  bool _xtreamLoading = true;
  late bool _isFavorite;
  late bool _isInWatchlist;

  @override
  void initState() {
    super.initState();
    _isFavorite    = widget.movie.isFavorite;
    _isInWatchlist = ref.read(storageServiceProvider).isInWatchlist(widget.movie.id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchXtream());
  }

  Future<void> _fetchXtream() async {
    final id = ref.read(activePlaylistIdProvider);
    if (id == null) { setState(() => _xtreamLoading = false); return; }
    final playlist = ref.read(playlistRepositoryProvider)
        .getSavedPlaylists()
        .cast<Playlist?>()
        .firstWhere((p) => p?.id == id, orElse: () => null);
    if (playlist == null || playlist.playlistType != PlaylistType.xtream) {
      setState(() => _xtreamLoading = false);
      return;
    }
    final vodId = widget.movie.id.replaceFirst('vod_', '');
    try {
      final data = await ref.read(playlistRepositoryProvider).getVodInfo(playlist, vodId);
      if (mounted) setState(() { _xtreamInfo = data; _xtreamLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _xtreamLoading = false);
    }
  }

  void _watchNow() {
    ref.read(playerProvider.notifier).openChannel(widget.movie);
    Navigator.push(context, PageRouteBuilder(
      pageBuilder:        (_, a, __) => const PlayerScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    ));
  }

  void _openExternal() =>
      ref.read(playerProvider.notifier).openUrlInExternalPlayer(widget.movie.streamUrl);

  Future<void> _toggleFavorite() async {
    await ref.read(storageServiceProvider).toggleFavorite(widget.movie);
    if (mounted) setState(() => _isFavorite = widget.movie.isFavorite);
  }

  Future<void> _toggleWatchlist() async {
    await ref.read(storageServiceProvider).toggleWatchlist(widget.movie.id);
    if (mounted) setState(() => _isInWatchlist = !_isInWatchlist);
  }

  @override
  Widget build(BuildContext context) {
    // TMDB data (async — shows when ready)
    final tmdbAsync = ref.watch(tmdbProvider(widget.movie));
    final tmdb      = tmdbAsync.valueOrNull;

    // Xtream data
    final xtream = (_xtreamInfo?['info'] as Map<String, dynamic>?) ?? {};

    // ── Merged fields (TMDB takes priority) ─────────────────────────────────
    final posterUrl  = tmdb?.posterUrl
        ?? (xtream['movie_image'] as String?)?.trim()
        ?? widget.movie.logoUrl
        ?? '';
    final title      = tmdb?.title.isNotEmpty == true
        ? tmdb!.title
        : widget.movie.name;
    final plot       = _first([tmdb?.overview, xtream['plot'] as String?]) ?? '';
    final genre      = _first([tmdb?.genres,   xtream['genre'] as String?]) ?? '';
    final director   = _first([tmdb?.director, xtream['director'] as String?]) ?? '';
    final cast       = _first([tmdb?.cast,     xtream['cast'] as String?]) ?? '';
    final release    = _first([tmdb?.releaseDate,
                               xtream['releasedate'] as String?,
                               xtream['release_date'] as String?]) ?? '';
    final duration   = tmdb?.runtime != null
        ? '${tmdb!.runtime} دقيقة'
        : (xtream['duration'] as String?)?.trim() ?? '';
    final age        = (xtream['age'] as String?)?.trim() ?? '';

    // Rating: TMDB is 0–10, Xtream rating_5based is 0–5
    final tmdbRating   = tmdb != null && tmdb.voteAverage > 0 ? tmdb.voteAverage : null;
    final xtreamRaw    = xtream['rating_5based'];
    final xtreamRating = xtreamRaw is num ? xtreamRaw.toDouble() * 2 : null;
    final rating10     = tmdbRating ?? xtreamRating ?? 0.0;
    final hasTmdb      = tmdb != null;

    // Quality badges — scan raw server name + groupTitle, then augment with
    // Xtream technical video/audio fields if available
    final rawSource =
        '${(xtream['name'] as String?) ?? ''} ${widget.movie.groupTitle ?? ''}';
    var badges = extractQualityBadges(rawSource);
    if (_xtreamInfo != null) badges = augmentFromXtream(badges, xtream);

    // Split title: strip trailing "(YYYY)" → displayTitle; keep year as a tag
    final _yearRx     = RegExp(r'\s*\((\d{4})\)\s*$');
    final yearMatch   = _yearRx.firstMatch(title);
    final displayTitle = yearMatch != null
        ? title.substring(0, yearMatch.start).trim()
        : title;
    final titleYear    = yearMatch?.group(1)
        ?? (release.length >= 4 ? release.substring(0, 4) : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          // ── Top bar ────────────────────────────────────────────────────────
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
                child: Text(displayTitle,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (hasTmdb) _TmdbBadge(),
            ]),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          Expanded(child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: Poster + rating ─────────────────────────────────────
              Container(
                width: 240,
                color: AppColors.surface,
                child: Column(children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: posterUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: posterUrl,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 200),
                              errorWidget: (_, __, ___) => _PosterFallback(title),
                              placeholder: (_, __) =>
                                  Container(color: AppColors.surfaceLight),
                            )
                          : _PosterFallback(title),
                    ),
                  ),
                  if (rating10 > 0) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: _RatingBar(value: rating10, fromTmdb: hasTmdb),
                    ),
                  ],
                  const SizedBox(height: 12),
                ]),
              ),

              const VerticalDivider(width: 1, color: AppColors.border),

              // ── Right: Info ───────────────────────────────────────────────
              Expanded(
                child: _xtreamLoading && !hasTmdb
                    ? const Center(child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2.5))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayTitle,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),

                            // Inline rating
                            if (rating10 > 0) ...[
                              _InlineRating(value: rating10, fromTmdb: hasTmdb),
                              const SizedBox(height: 8),
                            ],

                            // Year tag + quality badges
                            if (titleYear != null || badges.isNotEmpty) ...[
                              Wrap(
                                spacing: 6, runSpacing: 5,
                                children: [
                                  if (titleYear != null) _YearTag(titleYear),
                                  ...badges.map((b) => _QualityChip(b)),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ] else
                              const SizedBox(height: 8),

                            if (release.isNotEmpty)  _MetaRow(label: 'تاريخ الإصدار', value: release),
                            if (duration.isNotEmpty) _MetaRow(label: 'المدة',         value: duration),
                            if (age.isNotEmpty)      _MetaRow(label: 'التصنيف',       value: age),
                            if (genre.isNotEmpty)    _MetaRow(label: 'النوع',         value: genre),
                            if (director.isNotEmpty) _MetaRow(label: 'المخرج',        value: director),
                            if (cast.isNotEmpty)     _MetaRow(label: 'طاقم التمثيل',  value: cast),

                            if (plot.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(height: 2, width: 48,
                                  decoration: BoxDecoration(gradient: kPrimeGradient,
                                      borderRadius: BorderRadius.circular(1))),
                              const SizedBox(height: 12),
                              Text(plot,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13, height: 1.6)),
                            ],

                            // Loading TMDB shimmer row
                            if (tmdbAsync.isLoading) ...[
                              const SizedBox(height: 16),
                              Row(children: [
                                const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('جاري جلب بيانات TMDB…',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11)),
                              ]),
                            ],

                            const SizedBox(height: 32),

                            // Action buttons
                            Row(children: [
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

                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(
                                child: _ActionToggleButton(
                                  icon:        _isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  label:       _isFavorite ? 'في المفضلة' : 'المفضلة',
                                  active:      _isFavorite,
                                  activeColor: const Color(0xFFE74C3C),
                                  onTap:       _toggleFavorite,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ActionToggleButton(
                                  icon:        _isInWatchlist
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  label:       _isInWatchlist
                                      ? 'في قائمتي'
                                      : 'المشاهدة لاحقاً',
                                  active:      _isInWatchlist,
                                  activeColor: AppColors.primary,
                                  onTap:       _toggleWatchlist,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
              ),
            ],
          )),
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String? _first(List<String?> vals) {
  for (final v in vals) {
    final s = v?.trim();
    if (s != null && s.isNotEmpty) return s;
  }
  return null;
}

// ── TMDB badge ────────────────────────────────────────────────────────────────
class _TmdbBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF01D277).withOpacity(0.15),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFF01D277).withOpacity(0.5)),
        ),
        child: const Text('TMDB',
            style: TextStyle(
                color: Color(0xFF01D277),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5)),
      );
}

// ── Rating bar (0–10) ─────────────────────────────────────────────────────────
class _RatingBar extends StatelessWidget {
  final double value;   // 0–10
  final bool   fromTmdb;
  const _RatingBar({required this.value, required this.fromTmdb});

  Color get _color {
    if (value >= 7) return const Color(0xFF27AE60);
    if (value >= 5) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_rounded, color: _color, size: 16),
          const SizedBox(width: 4),
          Text(value.toStringAsFixed(1),
              style: TextStyle(
                  color: _color, fontSize: 16, fontWeight: FontWeight.w800)),
          const Text(' / 10',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          if (fromTmdb) ...[
            const SizedBox(width: 6),
            const Text('TMDB',
                style: TextStyle(
                    color: Color(0xFF01D277),
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ],
        ],
      );
}

// ── Metadata row ──────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12, fontWeight: FontWeight.w600)),
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

// ── Year tag ──────────────────────────────────────────────────────────────────
class _YearTag extends StatelessWidget {
  final String year;
  const _YearTag(this.year);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color:        AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(5),
      border:       Border.all(color: AppColors.border),
    ),
    child: Text(year,
        style: const TextStyle(
            color:      AppColors.textSecondary,
            fontSize:   10,
            fontWeight: FontWeight.w700)),
  );
}

// ── Inline rating (right panel, below title) ──────────────────────────────────
class _InlineRating extends StatelessWidget {
  final double value;    // 0–10
  final bool   fromTmdb;
  const _InlineRating({required this.value, required this.fromTmdb});

  Color get _color {
    if (value >= 7) return const Color(0xFF27AE60);
    if (value >= 5) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.star_rounded, color: _color, size: 16),
      const SizedBox(width: 4),
      Text(value.toStringAsFixed(1),
          style: TextStyle(
              color: _color, fontSize: 15, fontWeight: FontWeight.w800)),
      Text(' / 10',
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 11)),
      if (fromTmdb) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF01D277).withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: const Color(0xFF01D277).withOpacity(0.4)),
          ),
          child: const Text('TMDB',
              style: TextStyle(
                  color: Color(0xFF01D277),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4)),
        ),
      ],
    ],
  );
}

// ── Quality chip (4K, HDR, 5.1 …) ────────────────────────────────────────────
class _QualityChip extends StatelessWidget {
  final QualityBadge badge;
  const _QualityChip(this.badge);

  static const _videoColor = Color(0xFF2980B9);
  static const _hdrColor   = Color(0xFFF39C12);
  static const _audioColor = Color(0xFF27AE60);
  static const _codecColor = Color(0xFF8E44AD);

  Color get _color => switch (badge.type) {
    QualityBadgeType.video => _videoColor,
    QualityBadgeType.hdr   => _hdrColor,
    QualityBadgeType.audio => _audioColor,
    QualityBadgeType.codec => _codecColor,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color:        _color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(5),
      border:       Border.all(color: _color.withOpacity(0.5)),
    ),
    child: Text(badge.label,
        style: TextStyle(
            color:       _color,
            fontSize:    10,
            fontWeight:  FontWeight.w700,
            letterSpacing: 0.3)),
  );
}

// ── Favorite / Watchlist toggle button ───────────────────────────────────────
class _ActionToggleButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         active;
  final Color        activeColor;
  final VoidCallback onTap;
  const _ActionToggleButton({
    required this.icon, required this.label, required this.active,
    required this.activeColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 44,
      decoration: BoxDecoration(
        color:         active ? activeColor.withOpacity(0.12) : AppColors.surfaceLight,
        borderRadius:  BorderRadius.circular(10),
        border:        Border.all(
          color: active ? activeColor.withOpacity(0.55) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: active ? activeColor : AppColors.textSecondary,
              size:  18),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color:      active ? activeColor : AppColors.textSecondary,
                  fontSize:   12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

// ── Poster fallback ───────────────────────────────────────────────────────────
class _PosterFallback extends StatelessWidget {
  final String name;
  const _PosterFallback(this.name);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
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
