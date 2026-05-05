import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import 'player_screen.dart';

class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({super.key});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching   = false;

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
    final categories     = ref.watch(liveCategoriesProvider);
    final activeCategory = ref.watch(activeCategoryProvider);
    final channels       = ref.watch(filteredLiveChannelsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          children: [
            // Panel 1 — Categories (flex 2)
            Expanded(
              flex: 2,
              child: _CategoriesSidebar(
                categories:     categories,
                activeCategory: activeCategory ?? 'All',
                onSelect: (cat) {
                  ref.read(activeCategoryProvider.notifier).state =
                      cat == 'All' ? null : cat;
                },
              ),
            ),

            // Panel 2 — Channel list (flex 3)
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _TopBar(
                    searching:  _searching,
                    searchCtrl: _searchCtrl,
                    onSearchToggle: () {
                      setState(() {
                        _searching = !_searching;
                        if (!_searching) {
                          _searchCtrl.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        }
                      });
                    },
                    onSearch: (q) =>
                        ref.read(searchQueryProvider.notifier).state = q,
                    onBack: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: channels.isEmpty
                        ? const _EmptyChannels()
                        : _ChannelList(channels: channels),
                  ),
                ],
              ),
            ),

            // Divider
            Container(width: 1, color: AppColors.border),

            // Panel 3 — Embedded player (flex 5)
            const Expanded(
              flex: 5,
              child: _EmbeddedPlayer(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Categories sidebar ────────────────────────────────────────────────────────
class _CategoriesSidebar extends StatelessWidget {
  final List<String> categories;
  final String       activeCategory;
  final ValueChanged<String> onSelect;

  const _CategoriesSidebar({
    required this.categories,
    required this.activeCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D1A),
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat    = categories[i];
          final active = cat == activeCategory;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: active
                    ? AppColors.primary.withOpacity(0.2)
                    : Colors.transparent,
                border: active
                    ? Border.all(color: AppColors.primary.withOpacity(0.5))
                    : null,
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: active
                      ? AppColors.primary
                      : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w400,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool                 searching;
  final TextEditingController searchCtrl;
  final VoidCallback          onSearchToggle;
  final ValueChanged<String>  onSearch;
  final VoidCallback          onBack;

  const _TopBar({
    required this.searching,
    required this.searchCtrl,
    required this.onSearchToggle,
    required this.onSearch,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textSecondary, size: 18),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
          if (searching)
            Expanded(
              child: TextField(
                controller:  searchCtrl,
                autofocus:   true,
                onChanged:   onSearch,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText:  'Search…',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border:    InputBorder.none,
                  isDense:   true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            )
          else
            const Expanded(
              child: Text('Live TV',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          IconButton(
            icon: Icon(
              searching ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
            onPressed: onSearchToggle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
        ],
      ),
    );
  }
}

// ── Channel list ──────────────────────────────────────────────────────────────
class _ChannelList extends ConsumerWidget {
  final List<Channel> channels;
  const _ChannelList({required this.channels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChannel = ref.watch(playerProvider).channel;

    return ListView.builder(
      itemCount:              channels.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries:   false,
      itemBuilder: (ctx, i) {
        final ch       = channels[i];
        final isActive = ch.streamUrl == activeChannel?.streamUrl;

        return Listener(
          onPointerDown: (_) {
            final next = i < channels.length - 1 ? i + 1 : i;
            ref
                .read(playerProvider.notifier)
                .preConnect(channels[next].streamUrl);
          },
          child: GestureDetector(
            onTap: () => ref.read(playerProvider.notifier).openChannel(ch),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              color: isActive
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.transparent,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.surfaceLight,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ch.logoUrl != null && ch.logoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ch.logoUrl!,
                            fit: BoxFit.contain,
                            fadeInDuration:
                                const Duration(milliseconds: 150),
                            errorWidget: (_, __, ___) =>
                                _ChannelInitials(ch.name),
                            placeholder: (_, __) => const SizedBox(),
                          )
                        : _ChannelInitials(ch.name),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ch.name,
                      style: TextStyle(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isActive)
                    const Icon(Icons.play_arrow_rounded,
                        color: AppColors.primary, size: 14),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChannelInitials extends StatelessWidget {
  final String name;
  const _ChannelInitials(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── Embedded player ───────────────────────────────────────────────────────────
class _EmbeddedPlayer extends ConsumerStatefulWidget {
  const _EmbeddedPlayer();

  @override
  ConsumerState<_EmbeddedPlayer> createState() => _EmbeddedPlayerState();
}

class _EmbeddedPlayerState extends ConsumerState<_EmbeddedPlayer> {
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _toggleControls() {
    if (_showControls) {
      _hideTimer?.cancel();
      setState(() => _showControls = false);
    } else {
      _hideTimer?.cancel();
      setState(() => _showControls = true);
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showControls = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final ctrl        = playerState.controller;
    final channel     = playerState.channel;

    // Show controls briefly when channel changes
    ref.listen(playerProvider.select((s) => s.channel), (_, __) {
      _hideTimer?.cancel();
      setState(() => _showControls = true);
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showControls = false);
      });
    });

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Video surface
            if (ctrl != null && ctrl.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: ctrl.value.aspectRatio,
                  child: VideoPlayer(ctrl),
                ),
              )
            else if (channel == null)
              const _NoChannelPlaceholder()
            else
              const SizedBox.expand(),

            // Buffering
            if (playerState.isBuffering)
              const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.accent,
                  ),
                ),
              ),

            // Error
            if (playerState.hasError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 36),
                    const SizedBox(height: 8),
                    const Text('Stream error',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        if (channel != null) {
                          ref
                              .read(playerProvider.notifier)
                              .openChannel(channel);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.primary,
                        ),
                        child: const Text('Retry',
                            style: TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),

            // Controls overlay
            AnimatedOpacity(
              opacity:  _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Stack(
                  children: [
                    // Top gradient
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: Container(
                        height: 70,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // Channel name + fullscreen
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            if (channel?.logoUrl != null &&
                                channel!.logoUrl!.isNotEmpty)
                              Container(
                                width: 28, height: 28,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: AppColors.surfaceLight,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl: channel.logoUrl!,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) =>
                                      const SizedBox(),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                channel?.name ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black54,
                                        blurRadius: 4)
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, a, __) =>
                                      const PlayerScreen(),
                                  transitionsBuilder: (_, a, __, child) =>
                                      FadeTransition(
                                          opacity: a, child: child),
                                  transitionDuration:
                                      const Duration(milliseconds: 200),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.black38,
                                ),
                                child: const Icon(
                                    Icons.fullscreen_rounded,
                                    color: Colors.white,
                                    size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _NoChannelPlaceholder extends StatelessWidget {
  const _NoChannelPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.live_tv_rounded,
              color: AppColors.textMuted, size: 52),
          SizedBox(height: 12),
          Text('Select a channel',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}

class _EmptyChannels extends StatelessWidget {
  const _EmptyChannels();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No channels',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
    );
  }
}
