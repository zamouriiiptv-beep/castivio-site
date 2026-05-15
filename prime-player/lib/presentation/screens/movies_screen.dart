import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../../data/models/playlist.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/content_screen_layout.dart';
import 'player_screen.dart';

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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ContentTopBar(
              section:    'MOVIES',
              subSection: '${movies.length} films',
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
                  Expanded(
                    child: Column(
                      children: [
                        if (_searching)
                          _SearchBar(
                            ctrl: _searchCtrl,
                            hint: 'Search movies…',
                            onChanged: (q) =>
                                ref.read(searchQueryProvider.notifier).state = q,
                          ),
                        Expanded(
                          child: movies.isEmpty
                              ? _EmptyView(icon: Icons.movie_rounded)
                              : _PosterGrid(
                                  items: movies,
                                  onTap: (ch) {
                                    ref.read(playerProvider.notifier).openChannel(ch);
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, a, __) =>
                                            const PlayerScreen(),
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
    );
  }

  Widget _buildLoading(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Column(children: [
          ContentTopBar(section: 'MOVIES', subSection: 'Loading…', onBack: () => Navigator.pop(context)),
          Expanded(child: SectionLoader(icon: Icons.movie_rounded, label: 'Loading movies…', onCancel: () => Navigator.pop(context))),
        ])),
      );

  Widget _buildError(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Column(children: [
          ContentTopBar(section: 'MOVIES', subSection: 'Error', onBack: () => Navigator.pop(context)),
          Expanded(child: SectionError(error: _lazyError!, onRetry: () => _loadIfNeeded())),
        ])),
      );
}

// ── Shared search bar ─────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   5,
        crossAxisSpacing: 8,
        mainAxisSpacing:  8,
        childAspectRatio: 0.67,
      ),
      itemCount:              items.length,
      addAutomaticKeepAlives: false,
      itemBuilder: (_, i) {
        final item = items[i];
        return GestureDetector(
          onTap: () => onTap(item),
          child: Container(
            decoration: BoxDecoration(
              color:        AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border:       Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: item.logoUrl != null && item.logoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl:       item.logoUrl!,
                          fit:            BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 200),
                          errorWidget: (_, __, ___) =>
                              _PosterFallback(item.name, Icons.movie_rounded),
                          placeholder: (_, __) =>
                              Container(color: AppColors.surfaceLight),
                        )
                      : _PosterFallback(item.name, Icons.movie_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 6),
                  child: Text(item.name,
                      style: const TextStyle(
                        color:      AppColors.textPrimary,
                        fontSize:   10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PosterFallback extends StatelessWidget {
  final String   name;
  final IconData icon;
  const _PosterFallback(this.name, this.icon);

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surfaceLight,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: AppColors.textMuted, size: 28),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(name,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 9),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  const _EmptyView({required this.icon});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ShaderMask(
            shaderCallback: (b) => kPrimeGradient.createShader(b),
            child: Icon(icon, color: Colors.white, size: 52),
          ),
          const SizedBox(height: 12),
          const Text('No content found',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ]),
      );
}
