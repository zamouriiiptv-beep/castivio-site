import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';

// ignore_for_file: use_build_context_synchronously

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with WidgetsBindingObserver {
  bool     _showControls    = true;
  Timer?   _hideTimer;
  bool     _isSeeking       = false;
  Duration _dragPosition    = Duration.zero;
  BoxFit   _videoFit        = BoxFit.contain;
  bool     _showFitToast    = false;

  @override
  void initState() {
    super.initState();
    _resetHideTimer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(playerProvider.notifier).stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    ref.read(playerProvider.notifier).stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    setState(() => _showControls = true);
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_isSeeking) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    if (_isSeeking) return;
    if (_showControls) {
      _hideTimer?.cancel();
      setState(() => _showControls = false);
    } else {
      _resetHideTimer();
    }
  }

  void _onDoubleTap() {
    setState(() {
      _videoFit     = _videoFit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
      _showFitToast = true;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showFitToast = false);
    });
    _resetHideTimer();
  }

  void _onSeekStart(double val) {
    _hideTimer?.cancel();
    setState(() {
      _isSeeking    = true;
      _dragPosition = Duration(seconds: val.toInt());
      _showControls = true;
    });
  }

  void _onSeekUpdate(double val) {
    setState(() => _dragPosition = Duration(seconds: val.toInt()));
  }

  void _onSeekEnd(double val) {
    ref.read(playerProvider.notifier).seek(Duration(seconds: val.toInt()));
    setState(() => _isSeeking = false);
    _resetHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final ps         = ref.watch(playerProvider);
    final ctrl       = ps.controller;
    final displayPos = _isSeeking ? _dragPosition : ps.position;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap:       _toggleControls,
        onDoubleTap: _onDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned.fill(
              child: ctrl != null
                  ? Video(
                      controller: ctrl,
                      controls:   NoVideoControls,
                      fill:       Colors.black,
                      fit:        _videoFit,
                    )
                  : const SizedBox(),
            ),

            if (ps.isBuffering)
              const Center(child: _BufferingIndicator()),

            if (_showFitToast)
              Center(
                child: AnimatedOpacity(
                  opacity: _showFitToast ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _videoFit == BoxFit.cover
                              ? Icons.crop_free_rounded
                              : Icons.fit_screen_rounded,
                          color: Colors.white, size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _videoFit == BoxFit.cover ? 'ملء الشاشة' : 'حجم عادي',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (ps.hasError && !ps.isPlaying)
              _ErrorOverlay(
                message:    ps.errorMessage,
                onRetry:    () {
                  if (ps.channel != null) {
                    ref.read(playerProvider.notifier).openChannel(ps.channel!);
                  }
                },
                onBack:     () => Navigator.pop(context),
                onExternal: () =>
                    ref.read(playerProvider.notifier).openInExternalPlayer(),
              ),

            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity:  _showControls ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_showControls,
                child: _ControlsOverlay(
                  channel:       ps.channel,
                  isPlaying:     ps.isPlaying,
                  position:      displayPos,
                  duration:      ps.duration,
                  onBack:        () => Navigator.pop(context),
                  onPlayPause:   () =>
                      ref.read(playerProvider.notifier).togglePlay(),
                  onFavorite: () {
                    final ch = ps.channel;
                    if (ch != null) {
                      ref.read(playlistRepositoryProvider).toggleFavorite(ch);
                    }
                  },
                  onExternal:    () =>
                      ref.read(playerProvider.notifier).openInExternalPlayer(),
                  onSkipBack: () {
                    final pos = (ps.position - const Duration(seconds: 10))
                        .clamp(Duration.zero, ps.duration);
                    ref.read(playerProvider.notifier).seek(pos);
                    _resetHideTimer();
                  },
                  onSkipForward: () {
                    final pos = (ps.position + const Duration(seconds: 10))
                        .clamp(Duration.zero, ps.duration);
                    ref.read(playerProvider.notifier).seek(pos);
                    _resetHideTimer();
                  },
                  onSeekStart:   _onSeekStart,
                  onSeekUpdate:  _onSeekUpdate,
                  onSeekEnd:     _onSeekEnd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Buffering indicator ───────────────────────────────────────────────────────
class _BufferingIndicator extends StatelessWidget {
  const _BufferingIndicator();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.accent.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Loading…',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      );
}

// ── Error overlay ─────────────────────────────────────────────────────────────
class _ErrorOverlay extends StatelessWidget {
  final String?       message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  final VoidCallback? onExternal;
  const _ErrorOverlay({this.message, this.onRetry, this.onBack, this.onExternal});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 52),
              const SizedBox(height: 12),
              const Text('Stream Error',
                  style: TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w700)),
              if (message != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(message!,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                      textAlign: TextAlign.center),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 10, runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (onBack != null)
                    OutlinedButton.icon(
                      onPressed: onBack,
                      icon:  const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                      ),
                    ),
                  if (onRetry != null)
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon:  const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (onExternal != null)
                    ElevatedButton.icon(
                      onPressed: onExternal,
                      icon:  const Icon(Icons.open_in_new_rounded),
                      label: const Text('مشغل خارجي'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}

// ── Controls overlay ──────────────────────────────────────────────────────────
class _ControlsOverlay extends StatelessWidget {
  final Channel?   channel;
  final bool       isPlaying;
  final Duration   position;
  final Duration   duration;
  final VoidCallback onBack, onPlayPause, onFavorite, onExternal;
  final VoidCallback onSkipBack, onSkipForward;
  final ValueChanged<double> onSeekStart, onSeekUpdate, onSeekEnd;

  const _ControlsOverlay({
    required this.channel,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onBack,
    required this.onPlayPause,
    required this.onFavorite,
    required this.onExternal,
    required this.onSkipBack,
    required this.onSkipForward,
    required this.onSeekStart,
    required this.onSeekUpdate,
    required this.onSeekEnd,
  });

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          // Top gradient
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // Bottom gradient
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 130,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // Top bar: back / title / external / favorite
          Positioned(
            top: 0, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 22),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      channel?.name ?? '',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded,
                        color: Colors.white70),
                    onPressed: onExternal,
                    tooltip: 'External Player',
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border_rounded,
                        color: Colors.white70),
                    onPressed: onFavorite,
                  ),
                ],
              ),
            ),
          ),

          // Center: skip-10 / play-pause / skip+10
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SkipButton(
                  icon: Icons.replay_10_rounded,
                  onTap: onSkipBack,
                ),
                const SizedBox(width: 36),
                GestureDetector(
                  onTap: onPlayPause,
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                      border: Border.all(color: Colors.white30, width: 1.5),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white, size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 36),
                _SkipButton(
                  icon: Icons.forward_10_rounded,
                  onTap: onSkipForward,
                ),
              ],
            ),
          ),

          // Bottom: seek bar + time (VOD only)
          if (duration > Duration.zero)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          _fmt(position),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          _fmt(duration),
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight:        3,
                        thumbShape:         const RoundSliderThumbShape(
                            enabledThumbRadius: 7),
                        overlayShape:       const RoundSliderOverlayShape(
                            overlayRadius: 16),
                        activeTrackColor:   AppColors.primary,
                        inactiveTrackColor: Colors.white30,
                        thumbColor:         Colors.white,
                        overlayColor:       AppColors.primary.withOpacity(0.25),
                      ),
                      child: Slider(
                        value: position.inSeconds
                            .toDouble()
                            .clamp(0, duration.inSeconds.toDouble()),
                        max:            duration.inSeconds.toDouble(),
                        onChangeStart:  onSeekStart,
                        onChanged:      onSeekUpdate,
                        onChangeEnd:    onSeekEnd,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
}

// ── Skip button ───────────────────────────────────────────────────────────────
class _SkipButton extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _SkipButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.35),
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      );
}
