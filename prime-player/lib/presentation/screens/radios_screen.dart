import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import 'player_screen.dart';

class RadiosScreen extends ConsumerStatefulWidget {
  const RadiosScreen({super.key});

  @override
  ConsumerState<RadiosScreen> createState() => _RadiosScreenState();
}

class _RadiosScreenState extends ConsumerState<RadiosScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(radioChannelsProvider);
    final query    = ref.watch(searchQueryProvider);

    final filtered = query.isEmpty
        ? channels
        : channels
            .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

    // Group by groupTitle
    final groups = <String, List<Channel>>{};
    for (final ch in filtered) {
      final group = ch.groupTitle ?? 'Radio';
      groups.putIfAbsent(group, () => []).add(ch);
    }
    final groupKeys = groups.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              count:      channels.length,
              searchCtrl: _searchCtrl,
              onBack:     () => Navigator.pop(context),
              onSearch:   (q) =>
                  ref.read(searchQueryProvider.notifier).state = q,
              onClear: () {
                _searchCtrl.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(isFiltered: query.isNotEmpty)
                  : _RadioList(groups: groups, groupKeys: groupKeys),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatefulWidget {
  final int                   count;
  final TextEditingController searchCtrl;
  final VoidCallback          onBack;
  final ValueChanged<String>  onSearch;
  final VoidCallback          onClear;

  const _TopBar({
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
                autofocus:  true,
                onChanged:  widget.onSearch,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 15),
                decoration: const InputDecoration(
                  hintText:  'Search radios…',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border:    InputBorder.none,
                ),
              ),
            )
          else ...[
            const Icon(Icons.radio_rounded,
                color: Color(0xFF06B6D4), size: 22),
            const SizedBox(width: 8),
            const Text('Radios',
                style: TextStyle(
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
                color: const Color(0xFF06B6D4).withOpacity(0.15),
              ),
              child: Text('${widget.count}',
                  style: const TextStyle(
                    color: Color(0xFF06B6D4),
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

// ── Radio list with group headers ─────────────────────────────────────────────
class _RadioList extends ConsumerWidget {
  final Map<String, List<Channel>> groups;
  final List<String>               groupKeys;

  const _RadioList({required this.groups, required this.groupKeys});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState   = ref.watch(playerProvider);
    final activeChannel = playerState.channel;

    // Build flat item list: group header + channels interleaved
    final items = <_ListItem>[];
    for (final key in groupKeys) {
      items.add(_ListItem.header(key));
      for (final ch in groups[key]!) {
        items.add(_ListItem.channel(ch));
      }
    }

    return ListView.builder(
      itemCount:              items.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries:   false,
      itemBuilder: (ctx, i) {
        final item = items[i];
        if (item.isHeader) {
          return _GroupHeader(title: item.header!);
        }
        final ch       = item.channel!;
        final isActive = ch.streamUrl == activeChannel?.streamUrl;

        return _RadioTile(
          channel:  ch,
          isActive: isActive,
          onTap: () {
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
          },
        );
      },
    );
  }
}

// ── Group header ──────────────────────────────────────────────────────────────
class _GroupHeader extends StatelessWidget {
  final String title;
  const _GroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            height: 1,
            width: 40,
            color: AppColors.border,
          ),
        ],
      ),
    );
  }
}

// ── Radio tile ────────────────────────────────────────────────────────────────
class _RadioTile extends StatelessWidget {
  final Channel      channel;
  final bool         isActive;
  final VoidCallback onTap;

  const _RadioTile({
    required this.channel,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive
              ? const Color(0xFF06B6D4).withOpacity(0.1)
              : AppColors.surface,
          border: Border.all(
            color: isActive
                ? const Color(0xFF06B6D4).withOpacity(0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.surfaceLight,
              ),
              clipBehavior: Clip.antiAlias,
              child: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: channel.logoUrl!,
                      fit: BoxFit.contain,
                      fadeInDuration:
                          const Duration(milliseconds: 150),
                      errorWidget: (_, __, ___) =>
                          _RadioInitial(channel.name),
                      placeholder: (_, __) => const SizedBox(),
                    )
                  : _RadioInitial(channel.name),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF06B6D4)
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (channel.groupTitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      channel.groupTitle!,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (isActive)
              _PlayingWave()
            else
              const Icon(Icons.play_circle_outline_rounded,
                  color: AppColors.textMuted, size: 28),
          ],
        ),
      ),
    );
  }
}

class _RadioInitial extends StatelessWidget {
  final String name;
  const _RadioInitial(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF06B6D4).withOpacity(0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFF06B6D4),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PlayingWave extends StatefulWidget {
  @override
  State<_PlayingWave> createState() => _PlayingWaveState();
}

class _PlayingWaveState extends State<_PlayingWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.3;
            final h = 8.0 +
                12.0 * (0.5 + 0.5 * _ctrl.drive(
                  CurveTween(curve: Curves.easeInOut),
                ).value);
            return Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: const Color(0xFF06B6D4),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  const _EmptyState({required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFiltered ? Icons.search_off_rounded : Icons.radio_outlined,
            color: AppColors.textMuted, size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No results found' : 'No radios in this playlist',
            style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── List item helper ──────────────────────────────────────────────────────────
class _ListItem {
  final String?  header;
  final Channel? channel;

  const _ListItem._({this.header, this.channel});
  factory _ListItem.header(String h)    => _ListItem._(header: h);
  factory _ListItem.channel(Channel ch) => _ListItem._(channel: ch);

  bool get isHeader => header != null;
}
