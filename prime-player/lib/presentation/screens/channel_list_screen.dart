import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import 'player_screen.dart';

class ChannelListScreen extends ConsumerStatefulWidget {
  const ChannelListScreen({super.key});

  @override
  ConsumerState<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends ConsumerState<ChannelListScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories       = ref.watch(categoriesProvider);
    final activeCategory   = ref.watch(activeCategoryProvider);
    final filteredChannels = ref.watch(filteredChannelsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────
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
            ),
            // ── Body: sidebar + channel list ──────────────────────────────
            Expanded(
              child: Row(
                children: [
                  // Category sidebar
                  _CategorySidebar(
                    categories:     categories,
                    activeCategory: activeCategory ?? 'All',
                    onSelect: (cat) {
                      ref.read(activeCategoryProvider.notifier).state =
                          cat == 'All' ? null : cat;
                    },
                  ),
                  // Channel list — uses ListView.builder (virtual scroll)
                  Expanded(
                    child: filteredChannels.isEmpty
                        ? const _EmptyChannels()
                        : _ChannelList(channels: filteredChannels),
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

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool searching;
  final TextEditingController searchCtrl;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearch;

  const _TopBar({
    required this.searching,
    required this.searchCtrl,
    required this.onSearchToggle,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (searching)
            Expanded(
              child: TextField(
                controller: searchCtrl,
                autofocus: true,
                onChanged: onSearch,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: const InputDecoration(
                  hintText:  'Search channels…',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border:    InputBorder.none,
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.textMuted),
                ),
              ),
            )
          else ...[
            const Icon(Icons.play_circle_rounded,
                color: AppColors.primary, size: 28),
            const SizedBox(width: 10),
            const Text('Prime Player',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                )),
          ],
          const Spacer(),
          IconButton(
            icon: Icon(
              searching ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: onSearchToggle,
          ),
          Consumer(builder: (context, ref, _) {
            return IconButton(
              icon: const Icon(Icons.playlist_play_rounded,
                  color: AppColors.textSecondary),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Switch playlist',
            );
          }),
        ],
      ),
    );
  }
}

// ── Category sidebar ──────────────────────────────────────────────────────────
class _CategorySidebar extends StatelessWidget {
  final List<String> categories;
  final String activeCategory;
  final ValueChanged<String> onSelect;

  const _CategorySidebar({
    required this.categories,
    required this.activeCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      color: AppColors.surface,
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat    = categories[i];
          final active = cat == activeCategory ||
              (activeCategory == 'All' && cat == 'All');
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: active
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.transparent,
                border: active
                    ? Border.all(color: AppColors.primary.withOpacity(0.6))
                    : null,
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: active ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500,
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

// ── Channel list (virtual scroll = fast with 30k channels) ───────────────────
class _ChannelList extends ConsumerWidget {
  final List<Channel> channels;
  const _ChannelList({required this.channels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: channels.length,
      // addAutomaticKeepAlives: false & addRepaintBoundaries: false
      // avoids heavy widget trees — crucial for 30,000-channel lists
      addAutomaticKeepAlives: false,
      addRepaintBoundaries:   false,
      itemBuilder: (ctx, i) {
        final ch = channels[i];
        return _ChannelTile(
          channel: ch,
          onTap: () => _openPlayer(ctx, ref, ch),
          // Pre-warm next channel connection on pointer-down
          onPointerDown: () => ref.read(playerProvider.notifier).preConnect(
              channels[i < channels.length - 1 ? i + 1 : i].streamUrl),
        );
      },
    );
  }

  void _openPlayer(BuildContext ctx, WidgetRef ref, Channel ch) {
    ref.read(playerProvider.notifier).openChannel(ch);
    Navigator.push(
      ctx,
      PageRouteBuilder(
        pageBuilder:        (_, a, __) => const PlayerScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;
  final VoidCallback onPointerDown;

  const _ChannelTile({
    required this.channel,
    required this.onTap,
    required this.onPointerDown,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onPointerDown(),
      child: ListTile(
        onTap:           onTap,
        tileColor:        Colors.transparent,
        contentPadding:   const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: _ChannelLogo(url: channel.logoUrl, name: channel.name),
        title: Text(
          channel.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: channel.groupTitle != null
            ? Text(
                channel.groupTitle!,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
                maxLines: 1,
              )
            : null,
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textMuted, size: 20),
      ),
    );
  }
}

class _ChannelLogo extends StatelessWidget {
  final String? url;
  final String  name;
  const _ChannelLogo({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';

    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.surfaceLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl:    url!,
              fit:         BoxFit.contain,
              fadeInDuration: const Duration(milliseconds: 200),
              errorWidget: (_, __, ___) => _Initials(initials),
              placeholder: (_, __) => const SizedBox(),
            )
          : _Initials(initials),
    );
  }
}

class _Initials extends StatelessWidget {
  final String letter;
  const _Initials(this.letter);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.2),
      child: Center(
        child: Text(letter,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            )),
      ),
    );
  }
}

class _EmptyChannels extends StatelessWidget {
  const _EmptyChannels();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No channels found',
          style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
    );
  }
}
