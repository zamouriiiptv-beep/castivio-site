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
import '../widgets/content_screen_layout.dart';
import 'series_detail_screen.dart';

class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  final _searchCtrl = TextEditingController();
  bool    _searching   = false;
  bool    _lazyLoading = false;
  String? _lazyError;

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
    if (storage.isTypeLoaded(id, 'series')) return;

    final playlist = ref.read(playlistRepositoryProvider)
        .getSavedPlaylists()
        .cast<Playlist?>()
        .firstWhere((p) => p?.id == id, orElse: () => null);
    if (playlist == null || playlist.playlistType != PlaylistType.xtream) return;

    setState(() { _lazyLoading = true; _lazyError = null; });
    try {
      await ref.read(playlistRepositoryProvider).loadXtreamSeries(playlist);
      if (mounted) ref.read(playlistRefreshProvider.notifier).state++;
    } catch (e) {
      if (mounted) setState(() => _lazyError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _lazyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lazyLoading) return _buildLoading(context);
    if (_lazyError != null) return _buildError(context);

    final categories     = ref.watch(seriesCategoriesProvider);
    final activeCategory = ref.watch(activeCategoryProvider) ?? 'All';
    final series         = ref.watch(filteredSeriesChannelsProvider);
    final tr             = AppLocalizations.of(ref.watch(localeProvider));

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) { if (!didPop) _onBack(); },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ContentTopBar(
              section:    tr.series.toUpperCase(),
              subSection: '${series.length} ${tr.shows}',
              onBack:     _onBack,
            ),
            Expanded(
              child: Row(
                children: [
                  IconSidebar(
                    onBack: _onBack,
                    onSearch: () {
                      setState(() {
                        _searching = !_searching;
                        if (!_searching) {
                          _searchCtrl.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        }
                      });
                    },
                    isSearching: _searching,
                  ),
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
                        if (_searching)
                          _SearchBar(
                            ctrl: _searchCtrl,
                            hint: tr.searchSeries,
                            onChanged: (q) =>
                                ref.read(searchQueryProvider.notifier).state = q,
                          ),
                        Expanded(
                          child: series.isEmpty
                              ? _EmptyView(label: tr.noSeries)
                              : _PosterGrid(
                                  items: series,
                                  onTap: (ch) {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, a, __) =>
                                            SeriesDetailScreen(series: ch),
                                        transitionsBuilder: (_, a, __, child) =>
                                            FadeTransition(opacity: a, child: child),
                                        transitionDuration:
                                            const Duration(milliseconds: 200),
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
          ContentTopBar(section: tr.series.toUpperCase(), subSection: tr.loading, onBack: _onBack),
          Expanded(child: SectionLoader(icon: Icons.video_library_rounded, label: tr.loadingSeries, onCancel: _onBack)),
        ])),
      );
  }

  Widget _buildError(BuildContext context) {
    final tr = AppLocalizations.of(ref.read(localeProvider));
    return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Column(children: [
          ContentTopBar(section: tr.series.toUpperCase(), subSection: tr.error, onBack: _onBack),
          Expanded(child: SectionError(error: _lazyError!, onRetry: () => _loadIfNeeded())),
        ])),
      );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final String               hint;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.ctrl,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 15),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: ctrl,
            autofocus:  true,
            onChanged:  onChanged,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              border:         InputBorder.none,
              isDense:        true,
              contentPadding: EdgeInsets.zero,
              hintText:       hint,
              hintStyle:      const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Poster grid ───────────────────────────────────────────────────────────────
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
      itemBuilder: (_, i) {
        final item = items[i];
        return _PosterCard(item: item, onTap: () => onTap(item));
      },
    );
  }
}

class _PosterCard extends StatefulWidget {
  final Channel      item;
  final VoidCallback onTap;
  const _PosterCard({required this.item, required this.onTap});

  @override
  State<_PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends State<_PosterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? AppColors.primary : AppColors.border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 3))]
                : [],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster image
              widget.item.logoUrl != null && widget.item.logoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl:       widget.item.logoUrl!,
                      fit:            BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 150),
                      errorWidget:    (_, __, ___) => _NoImageFallback(widget.item.name),
                      placeholder:    (_, __) => Container(color: AppColors.surfaceLight),
                    )
                  : _NoImageFallback(widget.item.name),

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
                      color:      Colors.white,
                      fontSize:   9,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Rating badge top-left
              if (widget.item.rating != null)
                Positioned(
                  top: 5, left: 5,
                  child: _RatingBadge(widget.item.rating!),
                ),

              // Play icon on hover
              if (_hovered)
                Center(
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: kPrimeGradient,
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.5), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoImageFallback extends StatelessWidget {
  final String name;
  const _NoImageFallback(this.name);

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
          Icon(Icons.video_library_rounded,
              color: AppColors.textMuted.withOpacity(0.5), size: 22),
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
  final String label;
  const _EmptyView({required this.label});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ShaderMask(
            shaderCallback: (b) => kPrimeGradient.createShader(b),
            child: const Icon(Icons.video_library_rounded,
                color: Colors.white, size: 52),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ]),
      );
}
