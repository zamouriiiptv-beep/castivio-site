import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import 'player_screen.dart';

class MoviesScreen extends ConsumerStatefulWidget {
  const MoviesScreen({super.key});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(movieChannelsProvider);
    final query    = ref.watch(searchQueryProvider);

    final filtered = query.isEmpty
        ? channels
        : channels
            .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: 'Movies',
              count: channels.length,
              searchCtrl: _searchCtrl,
              onBack: () => Navigator.pop(context),
              onSearch: (q) =>
                  ref.read(searchQueryProvider.notifier).state = q,
              onClear: () {
                _searchCtrl.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(
                      isEmpty: channels.isEmpty,
                      isFiltered: query.isNotEmpty,
                    )
                  : _MovieGrid(movies: filtered),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatefulWidget {
  final String                title;
  final int                   count;
  final TextEditingController searchCtrl;
  final VoidCallback          onBack;
  final ValueChanged<String>  onSearch;
  final VoidCallback          onClear;

  const _TopBar({
    required this.title,
    required this.count,
    required this.searchCtrl,
    required this.onBack,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  bool _searching = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textSecondary),
            onPressed: widget.onBack,
          ),
          if (_searching)
            Expanded(
              child: TextField(
                controller: widget.searchCtrl,
                autofocus: true,
                onChanged: widget.onSearch,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 15),
                decoration: const InputDecoration(
                  hintText:  'Search movies…',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border:    InputBorder.none,
                ),
              ),
            )
          else ...[
            Text(widget.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primary.withOpacity(0.15),
              ),
              child: Text('${widget.count}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  )),
            ),
            const Spacer(),
          ],
          IconButton(
            icon: Icon(
              _searching ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() => _searching = !_searching);
              if (!_searching) widget.onClear();
            },
          ),
        ],
      ),
    );
  }
}

// ── Movie grid ────────────────────────────────────────────────────────────────
class _MovieGrid extends ConsumerWidget {
  final List<Channel> movies;
  const _MovieGrid({required this.movies});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:    3,
        crossAxisSpacing:  10,
        mainAxisSpacing:   10,
        childAspectRatio:  0.65,
      ),
      itemCount:              movies.length,
      addAutomaticKeepAlives: false,
      itemBuilder: (_, i) => _MovieCard(
        movie: movies[i],
        onTap: () {
          ref.read(playerProvider.notifier).openChannel(movies[i]);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:        (_, a, __) => const PlayerScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 200),
            ),
          );
        },
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final Channel      movie;
  final VoidCallback onTap;
  const _MovieCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: movie.logoUrl != null && movie.logoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl:    movie.logoUrl!,
                      fit:         BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 200),
                      errorWidget: (_, __, ___) => _PosterFallback(movie.name),
                      placeholder: (_, __) => const _PosterPlaceholder(),
                    )
                  : _PosterFallback(movie.name),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
              child: Text(
                movie.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  final String name;
  const _PosterFallback(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie_rounded,
              color: AppColors.textMuted, size: 32),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              name,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 10),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(color: AppColors.surfaceLight);
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isEmpty;
  final bool isFiltered;
  const _EmptyState({required this.isEmpty, required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFiltered ? Icons.search_off_rounded : Icons.movie_outlined,
            color: AppColors.textMuted, size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No results found' : 'No movies in this playlist',
            style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!isFiltered) ...[
            const SizedBox(height: 8),
            const Text(
              'Your playlist may be a live-only source',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
