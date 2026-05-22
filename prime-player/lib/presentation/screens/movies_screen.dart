import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_localizations.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../../data/models/playlist.dart';
import '../providers/locale_provider.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/tmdb_provider.dart';
import '../widgets/content_screen_layout.dart';
import '../widgets/top_search_bar.dart';
import 'movie_detail_screen.dart';
import 'player_screen.dart';

enum _ContentTab { all, favorites, watchlist }

class MoviesScreen extends ConsumerStatefulWidget {
  const MoviesScreen({super.key});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen> {
  final _searchCtrl  = TextEditingController();
  bool         _lazyLoading = false;
  bool         _refreshing  = false;
  String?      _lazyError;
  _ContentTab  _tab         = _ContentTab.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onBack() {
    ref.read(playerProvider.notifier).stop();
    Navigator.pop(context);
  }

  Future<void> _loadIfNeeded() async {
    final id = ref.read(activePlaylistIdProvider);
    if (id == null) return;
    final storage = ref.read(storageServiceProvider);
    if (storage.isTypeLoaded(id, 'vod')) return;

    final playlist = ref.read(playlistRepositoryProvider)
        .getSavedPlaylists()
        .cast<Playlist?>()
        .firstWhere((p) => p?.id == id, orElse: () => null);
    if (playlist == null || playlist.playlistType != PlaylistType.xtream) return;

    setState(() { _lazyLoading = true; _lazyError = null; });
    try {
      await ref.read(playlistRepositoryProvider).loadXtreamVod(playlist);
      if (mounted) ref.read(playlistRefreshProvider.notifier).state++;
    } catch (e) {
      if (mounted) setState(() => _lazyError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _lazyLoading = false);
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    final id = ref.read(activePlaylistIdProvider);
    if (id == null) return;
    final playlist = ref.read(playlistRepositoryProvider)
        .getSavedPlaylists()
        .cast<Playlist?>()
        .firstWhere((p) => p?.id == id, orElse: () => null);
    if (playlist == null || playlist.playlistType != PlaylistType.xtream) return;

    setState(() => _refreshing = true);
    try {
      await ref.read(playlistRepositoryProvider).loadXtreamVod(playlist);
      if (mounted) ref.read(playlistRefreshProvider.notifier).state++;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lazyLoading) return _buildLoading(context);
    if (_lazyError != null) return _buildError(context);

    final categories     = ref.watch(movieCategoriesProvider);
    final activeCategory = ref.watch(activeCategoryProvider) ?? 'All';
    final tr             = AppLocalizations.of(ref.watch(localeProvider));
    final q              = ref.watch(searchQueryProvider).toLowerCase();

    final List<Channel> movies;
    switch (_tab) {
      case _ContentTab.all:
        movies = ref.watch(filteredMovieChannelsProvider);
      case _ContentTab.favorites:
        final favs = ref.watch(favoriteMovieChannelsProvider);
        movies = q.isEmpty ? favs
            : favs.where((c) => c.name.toLowerCase().contains(q)).toList();
      case _ContentTab.watchlist:
        final wl = ref.watch(watchlistMovieChannelsProvider);
        movies = q.isEmpty ? wl
            : wl.where((c) => c.name.toLowerCase().contains(q)).toList();
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) { if (!didPop) _onBack(); },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ContentTopBar(
              section:      tr.movies.toUpperCase(),
              subSection:   '${movies.length} ${tr.films}',
              onBack:       _onBack,
              onRefresh:    _refresh,
              isRefreshing: _refreshing,
            ),
            Expanded(
              child: Row(
                children: [
                  IconSidebar(onBack: _onBack),
                  CategoriesPanel(
                    categories:     categories,
                    activeCategory: activeCategory,
                    onSelect: (cat) {
                      ref.read(activeCategoryProvider.notifier).state =
                          cat == 'All' ? null : cat;
                    },
                  ),
                  Container(width: 1, color: AppColors.border),
                  Expanded(
                    child: Column(
                      children: [
                        TopSearchBar(
                          controller: _searchCtrl,
                          hint:       tr.searchMovies,
                          onChanged:  (q) =>
                              ref.read(searchQueryProvider.notifier).state = q,
                        ),
                        // Tab row
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          color: AppColors.surface,
                          child: Row(children: [
                            _TabChip(
                              label:  'الكل',
                              active: _tab == _ContentTab.all,
                              onTap:  () => setState(
                                  () => _tab = _ContentTab.all),
                            ),
                            const SizedBox(width: 6),
                            _TabChip(
                              icon:        Icons.favorite_rounded,
                              label:       'المفضلة',
                              active:      _tab == _ContentTab.favorites,
                              activeColor: const Color(0xFFE74C3C),
                              onTap: () => setState(
                                  () => _tab = _ContentTab.favorites),
                            ),
                            const SizedBox(width: 6),
                            _TabChip(
                              icon:        Icons.bookmark_rounded,
                              label:       'لاحقاً',
                              active:      _tab == _ContentTab.watchlist,
                              activeColor: AppColors.primary,
                              onTap: () => setState(
                                  () => _tab = _ContentTab.watchlist),
                            ),
                          ]),
                        ),
                        Expanded(
                          child: movies.isEmpty
                              ? _EmptyView(icon: Icons.movie_rounded, label: tr.noContent)
                              : _PosterGrid(
                                  items: movies,
                                  onTap: (ch) {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, a, __) =>
                                            MovieDetailScreen(movie: ch),
                                        transitionsBuilder: (_, a, __, child) =>
                                            FadeTransition(opacity: a, child: child),
                                        transitionDuration: const Duration(milliseconds: 200),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final tr = AppLocalizations.of(ref.read(localeProvider));
    return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Column(children: [
          ContentTopBar(section: tr.movies.toUpperCase(), subSection: tr.loading, onBack: _onBack),
          Expanded(child: SectionLoader(icon: Icons.movie_rounded, label: tr.loadingMovies, onCancel: _onBack)),
        ])),
      );
  }

  Widget _buildError(BuildContext context) {
    final tr = AppLocalizations.of(ref.read(localeProvider));
    return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Column(children: [
          ContentTopBar(section: tr.movies.toUpperCase(), subSection: tr.error, onBack: _onBack),
          Expanded(child: SectionError(error: _lazyError!, onRetry: () => _loadIfNeeded())),
        ])),
      );
  }
}

// ── Poster grid ──────────────────────────────────────────────────────────────────────────────────────
class _PosterGrid extends StatelessWidget {
  final List<Channel>         items;
  final ValueChanged<Channel> onTap;

  const _PosterGrid({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   5,
        crossAxisSpacing: 6,
        mainAxisSpacing:  6,
        childAspectRatio: 0.68,
      ),
      itemCount:              items.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries:   false,
      itemBuilder: (_, i) {
        final item = items[i];
        return _PosterCard(item: item, onTap: () => onTap(item));
      },
    );
  }
}

class _PosterCard extends ConsumerStatefulWidget {
  final Channel      item;
  final VoidCallback onTap;
  const _PosterCard({required this.item, required this.onTap, super.key});

  @override
  ConsumerState<_PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends ConsumerState<_PosterCard> {
  late bool _isFav;
  late bool _isWl;

  @override
  void initState() {
    super.initState();
    _isFav = widget.item.isFavorite;
    _isWl  = ref.read(storageServiceProvider).isInWatchlist(widget.item.id);
  }

  Future<void> _toggleFav() async {
    await ref.read(storageServiceProvider).toggleFavorite(widget.item);
    if (!mounted) return;
    setState(() => _isFav = widget.item.isFavorite);
    ref.read(favRefreshProvider.notifier).state++;
  }

  Future<void> _toggleWl() async {
    await ref.read(storageServiceProvider).toggleWatchlist(widget.item.id);
    if (!mounted) return;
    setState(() => _isWl = !_isWl);
    ref.read(watchlistRefreshProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    final tmdbPoster = ref.watch(tmdbCachedPosterProvider(widget.item));
    final displayUrl = tmdbPoster ?? widget.item.logoUrl;
    final isWatched  = ref.watch(isWatchedProvider(widget.item.id));
    final watchPct   = isWatched ? null : ref.watch(watchProgressProvider(widget.item.id));

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            displayUrl != null && displayUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl:       displayUrl,
                    fit:            BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    errorWidget:    (_, __, ___) =>
                        _NoImageFallback(widget.item.name, Icons.movie_rounded),
                    placeholder:    (_, __) =>
                        Container(color: AppColors.surfaceLight),
                  )
                : _NoImageFallback(widget.item.name, Icons.movie_rounded),

            if (isWatched)
              Container(color: Colors.black.withOpacity(0.45)),

            // Bottom gradient + title
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(5, 20, 5, 5),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end:   Alignment.topCenter,
                    colors: [Color(0xFF0A0E1A), Color(0xBB0A0E1A), Color(0x000A0E1A)],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: Text(
                  widget.item.name,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 9,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            if (watchPct != null)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: LinearProgressIndicator(
                  value:           watchPct,
                  minHeight:       3,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFF39C12)),
                ),
              ),

            // Rating badge — top-left
            if (widget.item.rating != null)
              Positioned(
                top: 5, left: 5,
                child: _RatingBadge(widget.item.rating!),
              ),

            // Quick action icons — top-right
            Positioned(
              top: 4, right: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QuickIcon(
                    icon:        _isWl
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    active:      _isWl,
                    activeColor: AppColors.primary,
                    onTap:       _toggleWl,
                  ),
                  const SizedBox(width: 3),
                  _QuickIcon(
                    icon:        _isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    active:      _isFav,
                    activeColor: const Color(0xFFE74C3C),
                    onTap:       _toggleFav,
                  ),
                ],
              ),
            ),

            // Watched checkmark — bottom-right
            if (isWatched)
              Positioned(
                bottom: 6, right: 5,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF27AE60),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoImageFallback extends StatelessWidget {
  final String   name;
  final IconData icon;
  const _NoImageFallback(this.name, this.icon);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
            colors: [AppColors.surface, AppColors.surfaceLight],
          ),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: AppColors.textMuted.withOpacity(0.5), size: 22),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(name,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 8),
                maxLines: 3,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );
}

class _RatingBadge extends StatelessWidget {
  final String rating;
  const _RatingBadge(this.rating);

  Color get _color {
    final v = double.tryParse(rating) ?? 0;
    if (v >= 7.0) return const Color(0xFF27AE60);
    if (v >= 5.0) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          rating,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _EmptyView({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ShaderMask(
            shaderCallback: (b) => kPrimeGradient.createShader(b),
            child: Icon(icon, color: Colors.white, size: 52),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ]),
      );
}

// ── Tab chip ──────────────────────────────────────────────────────────────────
class _TabChip extends StatelessWidget {
  final String    label;
  final IconData? icon;
  final bool      active;
  final Color     activeColor;
  final VoidCallback onTap;
  const _TabChip({
    required this.label, required this.active, required this.onTap,
    this.icon, this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color:        active ? activeColor.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(
          color: active ? activeColor.withOpacity(0.6) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11,
                color: active ? activeColor : AppColors.textMuted),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color:      active ? activeColor : AppColors.textMuted,
                  fontSize:   11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

// ── Small circular icon button on poster card ─────────────────────────────────
class _QuickIcon extends StatelessWidget {
  final IconData     icon;
  final bool         active;
  final Color        activeColor;
  final VoidCallback onTap;
  const _QuickIcon({
    required this.icon, required this.active,
    required this.activeColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        color:  Colors.black.withOpacity(0.55),
        shape:  BoxShape.circle,
      ),
      child: Icon(icon,
          color: active ? activeColor : Colors.white70,
          size:  12),
    ),
  );
}
