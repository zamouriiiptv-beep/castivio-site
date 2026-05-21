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

class MoviesScreen extends ConsumerStatefulWidget {
  const MoviesScreen({super.key});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen> {
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

  @override
  Widget build(BuildContext context) {
    if (_lazyLoading) return _buildLoading(context);
    if (_lazyError != null) return _buildError(context);

    final categories     = ref.watch(movieCategoriesProvider);
    final activeCategory = ref.watch(activeCategoryProvider) ?? 'All';
    final movies         = ref.watch(filteredMovieChannelsProvider);
    final tr             = AppLocalizations.of(ref.watch(localeProvider));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ContentTopBar(
              section:    tr.movies.toUpperCase(),
              subSection: '${movies.length} ${tr.films}',
              onBack:     () => Navigator.pop(context),
            ),
            Expanded(
              child: Row(
                children: [
                  IconSidebar(
                    onBack: () => Navigator.pop(context),
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
                  SizedBox(
                    width: 290,
                    child: Column(
                      children: [
                        if (_searching)
                          _SearchBar(
                            ctrl: _searchCtrl,
                            hint: tr.searchMovies,
                            onChanged: (q) =>
                                ref.read(searchQueryProvider.notifier).state = q,
                          ),
                        Expanded(
                          child: movies.isEmpty
                              ? _EmptyView(icon: Icons.movie_rounded, label: tr.noContent)
                              : _PosterGrid(
                                  items: movies,
                                  onTap: (ch) {
                                    ref.read(playerProvider.notifier).openChannel(ch);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, color: AppColors.border),
                  const VideoPlayerPanel(
                    idleIcon:  Icons.movie_rounded,
                    idleLabel: 'Select a movie',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final tr = AppLocalizations.of(ref.read(localeProvider));
    return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Column(children: [
          ContentTopBar(section: tr.movies.toUpperCase(), subSection: tr.loading, onBack: () => Navigator.pop(context)),
          Expanded(child: SectionLoader(icon: Icons.movie_rounded, label: tr.loadingMovies, onCancel: () => Navigator.pop(context))),
        ])),
      );
  }

  Widget _buildError(BuildContext context) {
    final tr = AppLocalizations.of(ref.read(localeProvider));
    return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Column(children: [
          ContentTopBar(section: tr.movies.toUpperCase(), subSection: tr.error, onBack: () => Navigator.pop(context)),
          Expanded(child: SectionError(error: _lazyError!, onRetry: () => _loadIfNeeded())),
        ])),
      );
  }
}

// ── Shared search bar ────────────────────────────────────────────────────────────────────────────────
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

// ── Poster grid ──────────────────────────────────────────────────────────────────────────────────────
class _PosterGrid extends StatelessWidget {
  final List<Channel>         items;
  final ValueChanged<Channel> onTap;

  const _PosterGrid({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = (constraints.maxWidth / 120).floor().clamp(2, 8);
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   cols,
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
      },
    );
  }
}

class _PosterCard extends StatelessWidget {
  final Channel      item;
  final VoidCallback onTap;
  const _PosterCard({required this.item, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            item.logoUrl != null && item.logoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl:       item.logoUrl!,
                    fit:            BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    errorWidget:    (_, __, ___) =>
                        _NoImageFallback(item.name, Icons.movie_rounded),
                    placeholder:    (_, __) =>
                        Container(color: AppColors.surfaceLight),
                  )
                : _NoImageFallback(item.name, Icons.movie_rounded),

            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(5, 16, 5, 5),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end:   Alignment.topCenter,
                    colors: [Color(0xDD0A0E1A), Color(0x000A0E1A)],
                  ),
                ),
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 9,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Center(
              child: Icon(Icons.play_circle_outline_rounded,
                  color: Colors.white24, size: 22),
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
