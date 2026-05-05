import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../../data/models/playlist.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import 'add_playlist_screen.dart';
import 'live_tv_screen.dart';
import 'movies_screen.dart';
import 'player_screen.dart';
import 'radios_screen.dart';
import 'series_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists  = ref.watch(playlistsProvider);
    final activeId   = ref.watch(activePlaylistIdProvider);
    final favorites  = ref.watch(favoritesProvider);

    // Auto-select first playlist if none active
    if (activeId == null && playlists.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final id = playlists.first.id;
        ref.read(activePlaylistIdProvider.notifier).state = id;
        ref.read(storageServiceProvider).setActivePlaylistId(id);
      });
    }

    final activePlaylist = playlists.isEmpty
        ? null
        : playlists.firstWhere(
            (p) => p.id == activeId,
            orElse: () => playlists.first,
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(
              playlist: activePlaylist,
              onSettings: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
              onManage: playlists.isEmpty
                  ? null
                  : () => _showPlaylistPicker(context, ref, playlists),
            ),
            Expanded(
              child: playlists.isEmpty
                  ? _EmptyState(
                      onAdd: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const AddPlaylistScreen()));
                        ref.read(playlistRefreshProvider.notifier).state++;
                      },
                    )
                  : _HomeBody(
                      playlist:  activePlaylist,
                      favorites: favorites,
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: playlists.isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const AddPlaylistScreen()));
                ref.read(playlistRefreshProvider.notifier).state++;
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  void _showPlaylistPicker(
      BuildContext context, WidgetRef ref, List<Playlist> playlists) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PlaylistPickerSheet(playlists: playlists, ref: ref),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final Playlist?    playlist;
  final VoidCallback onSettings;
  final VoidCallback? onManage;

  const _AppBar({
    required this.playlist,
    required this.onSettings,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      color: AppColors.surface,
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            child: const Icon(Icons.play_circle_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prime Player',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    )),
                if (playlist != null)
                  GestureDetector(
                    onTap: onManage,
                    child: Row(
                      children: [
                        Text(
                          playlist!.name,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (onManage != null) ...[
                          const SizedBox(width: 2),
                          const Icon(Icons.unfold_more_rounded,
                              size: 14, color: AppColors.accent),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: AppColors.textSecondary),
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

// ── Home body ─────────────────────────────────────────────────────────────────
class _HomeBody extends ConsumerWidget {
  final Playlist?      playlist;
  final List<Channel>  favorites;

  const _HomeBody({required this.playlist, required this.favorites});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveCount   = ref.watch(liveChannelsProvider).length;
    final movieCount  = ref.watch(movieChannelsProvider).length;
    final seriesCount = ref.watch(seriesChannelsProvider).length;
    final radioCount  = ref.watch(radioChannelsProvider).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats bar
          if (playlist != null) _StatsBar(playlist: playlist!),
          const SizedBox(height: 20),

          // Section label
          const Text('Content',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              )),
          const SizedBox(height: 12),

          // 2×2 tile grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ContentTile(
                icon:  Icons.live_tv_rounded,
                label: 'Live TV',
                count: liveCount,
                color: AppColors.primary,
                gradient: const [Color(0xFF4F46E5), Color(0xFF6D63FF)],
                onTap: () {
                  ref.read(activeCategoryProvider.notifier).state = null;
                  ref.read(searchQueryProvider.notifier).state = '';
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LiveTvScreen()));
                },
              ),
              _ContentTile(
                icon:  Icons.movie_rounded,
                label: 'Movies',
                count: movieCount,
                color: const Color(0xFFEF4444),
                gradient: const [Color(0xFFEF4444), Color(0xFFF97316)],
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MoviesScreen())),
              ),
              _ContentTile(
                icon:  Icons.video_library_rounded,
                label: 'Series',
                count: seriesCount,
                color: AppColors.success,
                gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SeriesScreen())),
              ),
              _ContentTile(
                icon:  Icons.radio_rounded,
                label: 'Radios',
                count: radioCount,
                color: const Color(0xFF06B6D4),
                gradient: const [Color(0xFF06B6D4), Color(0xFF38BDF8)],
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RadiosScreen())),
              ),
            ],
          ),

          // Favorites section
          if (favorites.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text('Favorites',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                )),
            const SizedBox(height: 12),
            _FavoritesRow(favorites: favorites),
          ],
        ],
      ),
    );
  }
}

// ── Stats bar ─────────────────────────────────────────────────────────────────
class _StatsBar extends ConsumerWidget {
  final Playlist playlist;
  const _StatsBar({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${playlist.channelCount} channels loaded',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _lastUpdated(playlist.lastUpdated),
            style: const TextStyle(
              color: AppColors.textMuted, fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _lastUpdated(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1)   return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)    return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Content tile ──────────────────────────────────────────────────────────────
class _ContentTile extends StatelessWidget {
  final IconData       icon;
  final String         label;
  final int            count;
  final Color          color;
  final List<Color>    gradient;
  final VoidCallback   onTap;

  const _ContentTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradient[0].withOpacity(0.15),
              gradient[1].withOpacity(0.08),
            ],
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(colors: gradient),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: color.withOpacity(0.7)),
                ],
              ),
              const Spacer(),
              Text(label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 2),
              Text(
                count > 0 ? '$count channels' : 'No content',
                style: TextStyle(
                  color: count > 0 ? color : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Favorites row ─────────────────────────────────────────────────────────────
class _FavoritesRow extends ConsumerWidget {
  final List<Channel> favorites;
  const _FavoritesRow({required this.favorites});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: favorites.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final ch = favorites[i];
          return GestureDetector(
            onTap: () {
              ref.read(playerProvider.notifier).openChannel(ch);
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, a, __) => const PlayerScreen(),
                  transitionsBuilder: (_, a, __, child) =>
                      FadeTransition(opacity: a, child: child),
                  transitionDuration: const Duration(milliseconds: 200),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.surfaceLight,
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ch.logoUrl != null && ch.logoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ch.logoUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) =>
                              _ChannelInitial(ch.name),
                          placeholder: (_, __) => const SizedBox(),
                        )
                      : _ChannelInitial(ch.name),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 56,
                  child: Text(
                    ch.name,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChannelInitial extends StatelessWidget {
  final String name;
  const _ChannelInitial(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Icon(Icons.playlist_play_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('No playlist yet',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 8),
            const Text(
              'Add your M3U link or Xtream Codes\nto start watching',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Add Playlist',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Playlist picker sheet ─────────────────────────────────────────────────────
class _PlaylistPickerSheet extends ConsumerWidget {
  final List<Playlist> playlists;
  final WidgetRef      ref;

  const _PlaylistPickerSheet({required this.playlists, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef watchRef) {
    final activeId = watchRef.watch(activePlaylistIdProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('Switch Playlist',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...playlists.map((p) {
          final isActive = p.id == activeId;
          return ListTile(
            onTap: () {
              watchRef.read(activePlaylistIdProvider.notifier).state = p.id;
              watchRef.read(storageServiceProvider).setActivePlaylistId(p.id);
              Navigator.pop(context);
            },
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.surfaceLight,
              ),
              child: Icon(
                p.playlistType == PlaylistType.xtream
                    ? Icons.dns_rounded
                    : Icons.playlist_play_rounded,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ),
            title: Text(p.name,
                style: TextStyle(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                )),
            subtitle: Text('${p.channelCount} channels',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
            trailing: isActive
                ? const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 20)
                : null,
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
