/// Shared widgets for Live TV, Movies, Series, Radios screens.
/// Layout concept inspired by Hot Player — design elevated for Prime.
library;

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/app_localizations.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../providers/locale_provider.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../screens/player_screen.dart';

// ── Top bar ───────────────────────────────────────────────────────────────────
class ContentTopBar extends ConsumerWidget {
  final String section;
  final String? subSection;
  final VoidCallback onBack;

  const ContentTopBar({
    super.key,
    required this.section,
    this.subSection,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists  = ref.watch(playlistsProvider);
    final activeId   = ref.watch(activePlaylistIdProvider);
    final playlist   = playlists.isEmpty ? null
        : playlists.firstWhere((p) => p.id == activeId,
            orElse: () => playlists.first);
    final tr = AppLocalizations.of(ref.watch(localeProvider));

    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Logo + name (tappable → go back)
          GestureDetector(
            onTap: onBack,
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', width: 28, height: 28,
                    errorBuilder: (_, __, ___) => Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        gradient: kPrimeGradient,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 18),
                    )),
                const SizedBox(width: 6),
                ShaderMask(
                  shaderCallback: (b) => kPrimeGradient.createShader(b),
                  child: const Text('Prime',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      )),
                ),
                const Text(' Player',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Section badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: kPrimeGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(section,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                )),
          ),
          if (subSection != null && subSection!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(subSection!,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
          const Spacer(),
          if (playlist != null) ...[
            const Icon(Icons.playlist_play_rounded,
                color: AppColors.textMuted, size: 14),
            const SizedBox(width: 4),
            Text('${tr.playlist}: ',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            Text(playlist.name,
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(width: 12),
          ],
          // Info badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red.shade800,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.info_rounded, color: Colors.white, size: 12),
              const SizedBox(width: 3),
              Text(tr.info, style: const TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Left icon sidebar ─────────────────────────────────────────────────────────
class IconSidebar extends ConsumerWidget {
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final bool isSearching;

  const IconSidebar({
    super.key,
    required this.onBack,
    required this.onSearch,
    this.isSearching = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = AppLocalizations.of(ref.watch(localeProvider));
    return Container(
      width: 50,
      color: AppColors.sidebar,
      child: Column(
        children: [
          const SizedBox(height: 4),
          _SideIcon(icon: Icons.home_rounded,    onTap: onBack,     tip: tr.home),
          _SideIcon(icon: Icons.favorite_border_rounded, onTap: () {}, tip: tr.favorites),
          _SideIcon(
            icon: isSearching ? Icons.search_off_rounded : Icons.search_rounded,
            onTap: onSearch,
            tip: tr.search,
            active: isSearching,
          ),
          const Spacer(),
          _SideIcon(icon: Icons.refresh_rounded,            onTap: () {}, tip: tr.refresh),
          _SideIcon(icon: Icons.power_settings_new_rounded, onTap: onBack, tip: tr.exit),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _SideIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tip;
  final bool active;
  const _SideIcon({required this.icon, required this.onTap,
      required this.tip, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50, height: 46,
          decoration: BoxDecoration(
            gradient: active ? kPrimeGradient : null,
          ),
          child: Icon(icon,
              color: active ? Colors.white : AppColors.textMuted, size: 19),
        ),
      ),
    );
  }
}

// ── Categories panel ──────────────────────────────────────────────────────────
class CategoriesPanel extends ConsumerWidget {
  final List<String> categories;
  final String activeCategory;
  final ValueChanged<String> onSelect;

  const CategoriesPanel({
    super.key,
    required this.categories,
    required this.activeCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = AppLocalizations.of(ref.watch(localeProvider));
    return Container(
      width: 200,
      color: AppColors.surface,
      child: Column(
        children: [
          // Favorites header row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            color: AppColors.surfaceLight,
            child: Row(children: [
              Text(tr.favorites,
                  style: const TextStyle(color: AppColors.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              const Icon(Icons.favorite_border_rounded,
                  color: AppColors.textMuted, size: 14),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat    = categories[i];
                final active = cat == activeCategory;
                return GestureDetector(
                  onTap: () => onSelect(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      gradient: active ? kPrimeGradientH : null,
                      color: active ? null : Colors.transparent,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    child: Text(cat,
                        style: TextStyle(
                          color: active ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Channels list panel ───────────────────────────────────────────────────────
class ChannelsListPanel extends ConsumerWidget {
  final List<Channel> channels;
  final bool isSearching;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;

  const ChannelsListPanel({
    super.key,
    required this.channels,
    required this.isSearching,
    required this.searchCtrl,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChannel = ref.watch(playerProvider).channel;
    final tr = AppLocalizations.of(ref.watch(localeProvider));

    return Container(
      width: 290,
      color: AppColors.background,
      child: Column(
        children: [
          if (isSearching)
            Container(
              height: 36,
              color: AppColors.surfaceLight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(children: [
                const Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    onChanged: onSearch,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: tr.searchHint,
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ]),
            ),
          Expanded(
            child: channels.isEmpty
                ? Center(child: Text(tr.noChannels,
                    style: const TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    itemCount: channels.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false,
                    itemBuilder: (_, i) {
                      final ch       = channels[i];
                      final isActive = ch.streamUrl == activeChannel?.streamUrl;
                      return GestureDetector(
                        onTap: () =>
                            ref.read(playerProvider.notifier).openChannel(ch),
                        child: Container(
                          color: isActive
                              ? AppColors.primary.withOpacity(0.12)
                              : (i.isEven
                                  ? AppColors.background
                                  : AppColors.surface),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          child: Row(children: [
                            // Logo
                            Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: AppColors.surfaceLight,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ch.logoUrl != null && ch.logoUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: ch.logoUrl!,
                                      fit: BoxFit.contain,
                                      fadeInDuration: Duration.zero,
                                      errorWidget: (_, __, ___) =>
                                          _Initial(ch.name),
                                      placeholder: (_, __) =>
                                          const SizedBox(),
                                    )
                                  : _Initial(ch.name),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(ch.name,
                                  style: TextStyle(
                                    color: isActive
                                        ? AppColors.primaryLight
                                        : AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            // Number badge
                            Container(
                              width: 30, height: 18,
                              decoration: BoxDecoration(
                                gradient: isActive ? kPrimeGradient : null,
                                color: isActive ? null : AppColors.channelBadge,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  final String name;
  const _Initial(this.name);
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surfaceLight,
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.textMuted,
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      );
}

// ── Video player panel ────────────────────────────────────────────────────────
class VideoPlayerPanel extends ConsumerStatefulWidget {
  final IconData idleIcon;
  final String   idleLabel;

  const VideoPlayerPanel({
    super.key,
    this.idleIcon  = Icons.live_tv_rounded,
    this.idleLabel = 'Select a channel',
  });

  @override
  ConsumerState<VideoPlayerPanel> createState() => _VideoPlayerPanelState();
}

class _VideoPlayerPanelState extends ConsumerState<VideoPlayerPanel> {
  bool   _showControls = false;
  Timer? _hideTimer;

  void _tap() {
    if (_showControls) {
      _hideTimer?.cancel();
      setState(() => _showControls = false);
    } else {
      setState(() => _showControls = true);
      _hideTimer = Timer(const Duration(seconds: 3),
          () { if (mounted) setState(() => _showControls = false); });
    }
  }

  @override
  void dispose() { _hideTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ps      = ref.watch(playerProvider);
    final ctrl    = ps.controller;
    final channel = ps.channel;
    final tr      = AppLocalizations.of(ref.watch(localeProvider));

    return Expanded(
      child: GestureDetector(
        onTap: _tap,
        child: Container(
          color: Colors.black,
          child: Stack(children: [
            // Video surface — always render Video widget; libmpv shows black when idle
            if (channel == null)
              _Idle(icon: widget.idleIcon, label: widget.idleLabel)
            else if (ctrl != null)
              Positioned.fill(child: Video(
                  controller: ctrl, fit: BoxFit.contain,
                  controls: (_) => const SizedBox.shrink())),

            // Buffering
            if (ps.isBuffering)
              const Center(child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2.5)),

            // Error
            if (ps.hasError)
              Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 36),
                const SizedBox(height: 8),
                Text(tr.streamError,
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    if (channel != null)
                      ref.read(playerProvider.notifier).openChannel(channel);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                        gradient: kPrimeGradient,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(tr.retry,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ])),

            // Controls overlay
            if (_showControls && channel != null)
              _Controls(
                isPlaying: ps.isPlaying,
                onPlayPause: () =>
                    ref.read(playerProvider.notifier).togglePlay(),
                onFullscreen: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, a, __) => const PlayerScreen(),
                    transitionsBuilder: (_, a, __, child) =>
                        FadeTransition(opacity: a, child: child),
                    transitionDuration: const Duration(milliseconds: 200),
                  ),
                ),
              ),

            // Bottom info bar
            if (channel != null && !ps.hasError)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  color: Colors.black54,
                  child: Row(children: [
                    Expanded(child: Text(channel.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, a, __) => const PlayerScreen(),
                          transitionsBuilder: (_, a, __, child) =>
                              FadeTransition(opacity: a, child: child),
                        ),
                      ),
                      child: const Icon(Icons.fullscreen_rounded,
                          color: Colors.white70, size: 20),
                    ),
                  ]),
                ),
              ),

            // TV Programs placeholder
            if (channel == null)
              Positioned(
                bottom: 20, left: 0, right: 0,
                child: Column(children: [
                  Icon(Icons.calendar_today_rounded,
                      color: Colors.white.withOpacity(0.15), size: 28),
                  const SizedBox(height: 4),
                  Text(tr.tvPrograms,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.25), fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  Text(tr.selectChannel,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.15), fontSize: 10)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Idle extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _Idle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ShaderMask(
            shaderCallback: (b) => kPrimeGradient.createShader(b),
            child: Icon(icon, color: Colors.white, size: 64),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3), fontSize: 14)),
        ]),
      );
}

class _Controls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause, onFullscreen;
  const _Controls({required this.isPlaying,
      required this.onPlayPause, required this.onFullscreen});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black38,
        child: Center(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: onPlayPause,
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: kPrimeGradient,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: onFullscreen,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.fullscreen_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      );
}

// ── Lazy-load shared widgets ──────────────────────────────────────────────────

class SectionLoader extends ConsumerWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback? onCancel;
  const SectionLoader({super.key, required this.icon, required this.label, this.onCancel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = AppLocalizations.of(ref.watch(localeProvider));
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 56, height: 56,
            child: Stack(alignment: Alignment.center, children: [
              const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
              Icon(icon, color: AppColors.primary, size: 24),
            ]),
          ),
          const SizedBox(height: 18),
          Text(label,
              style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(tr.loadingMoment,
              style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.6), fontSize: 12)),
          if (onCancel != null) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onCancel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tr.cancel,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ),
          ],
        ]),
      );
  }
}

class SectionError extends ConsumerWidget {
  final String       error;
  final VoidCallback onRetry;
  const SectionError({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = AppLocalizations.of(ref.watch(localeProvider));
    return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 14),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 13)),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: kPrimeGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(tr.retry,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      );
  }
}
