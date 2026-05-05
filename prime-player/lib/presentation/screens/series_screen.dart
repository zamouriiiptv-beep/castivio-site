import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/content_screen_layout.dart';
import 'player_screen.dart';

class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  final _searchCtrl = TextEditingController();
  bool  _searching  = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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

  @override
  Widget build(BuildContext context) {
    final categories     = ref.watch(seriesCategoriesProvider);
    final activeCategory = ref.watch(activeCategoryProvider) ?? 'All';
    final series         = ref.watch(filteredSeriesChannelsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ContentTopBar(
              section:    'SERIES',
              subSection: '${series.length} shows',
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
                            hint: 'Search series…',
                            onChanged: (q) =>
                                ref.read(searchQueryProvider.notifier).state = q,
                          ),
                        Expanded(
                          child: series.isEmpty
                              ? const _EmptyView()
                              : _PosterGrid(
                                  items: series,
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
                              _PosterFallback(item.name),
                          placeholder: (_, __) =>
                              Container(color: AppColors.surfaceLight),
                        )
                      : _PosterFallback(item.name),
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
  final String name;
  const _PosterFallback(this.name);

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surfaceLight,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.video_library_rounded,
              color: AppColors.textMuted, size: 28),
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
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ShaderMask(
            shaderCallback: (b) => kPrimeGradient.createShader(b),
            child: const Icon(Icons.video_library_rounded,
                color: Colors.white, size: 52),
          ),
          const SizedBox(height: 12),
          const Text('No series found',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ]),
      );
}
