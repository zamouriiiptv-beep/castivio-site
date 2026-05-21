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
  bool      _showControls = true;
  Timer?    _hideTimer;
  bool      _isSeeking    = false;
  Duration  _dragPosition = Duration.zero;
  BoxFit    _videoFit     = BoxFit.contain;
  bool      _showFitToast = false;
  Timer?    _toastTimer;

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
    _toastTimer?.cancel();
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
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showFitToast = false);
    });
  }

  void _onSeekStart(Duration pos) {
    _hideTimer?.cancel();
    setState(() { _isSeeking = true; _dragPosition = pos; });
  }

  void _onSeekUpdate(Duration pos) => setState(() => _dragPosition = pos);

  void _onSeekEnd(Duration pos) {
    ref.read(playerProvider.notifier).seek(pos);
    setState(() => _isSeeking = false);
    _resetHideTimer();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final ps   = ref.watch(playerProvider);
    final ctrl = ps.controller;
    final isVod = ps.duration > Duration.zero;
    final displayPos = _isSeeking ? _dragPosition : ps.position;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap:       _toggleControls,
        onDoubleTap: _onDoubleTap,
        behavior:    HitTestBehavior.opaque,
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
                  channel:     ps.channel,
                  isPlaying:   ps.isPlaying,
                  isVod:       isVod,
                  position:    displayPos,
                  duration:    ps.duration,
                  onBack:      () => Navigator.pop(context),
                  onPlayPause: () =>
                      ref.read(playerProvider.notifier).togglePlay(),
                  onFavorite: () {
                    final ch = ps.channel;
                    if (ch != null) {
                      ref.read(playlistRepositoryProvider).toggleFavorite(ch);
                    }
                  },
                  onExternal: () =>
                      ref.read(playerProvider.notifier).openInExternalPlayer(),
                  onSkipBack: () {
                    final ms = (ps.position.inMilliseconds - 10000)
                        .clamp(0, ps.duration.inMilliseconds);
                    ref.read(playerProvider.notifier)
                        .seek(Duration(milliseconds: ms));
                  },
                  onSkipFwd: () {
                    final ms = (ps.position.inMilliseconds + 10000)
                        .clamp(0, ps.duration.inMilliseconds);
                    ref.read(playerProvider.notifier)
                        .seek(Duration(milliseconds: ms));
                  },
                  onSeekStart:  _onSeekStart,
                  onSeekUpdate: _onSeekUpdate,
                  onSeekEnd:    _onSeekEnd,
                  fmtTime:      _fmt,
                ),
              ),
            ),

            if (_showFitToast)
              Positioned(
                top: 60,
                left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _videoFit == BoxFit.cover ? 'Fill' : 'Fit',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Buffering indicator ────────────────────────────────────────────────────────
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

// ── Error overlay ──────────────────────────────────────────────────────────────
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

// ── Controls overlay ───────────────────────────────────────────────────────────
class _ControlsOverlay extends StatelessWidget {
  final Channel?   channel;
  final bool       isPlaying;
  final bool       isVod;
  final Duration   position;
  final Duration   duration;
  final VoidCallback onBack, onPlayPause, onFavorite, onExternal;
  final VoidCallback onSkipBack, onSkipFwd;
  final void Function(Duration) onSeekStart, onSeekUpdate, onSeekEnd;
  final String Function(Duration) fmtTime;

  const _ControlsOverlay({
    required this.channel,
    required this.isPlaying,
    required this.isVod,
    required this.position,
    required this.duration,
    required this.onBack,
    required this.onPlayPause,
    required this.onFavorite,
    required this.onExternal,
    required this.onSkipBack,
    required this.onSkipFwd,
    required this.onSeekStart,
    required this.onSeekUpdate,
    required this.onSeekEnd,
    required this.fmtTime,
  });

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          // top gradient
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
          // bottom gradient
          if (isVod)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

          // top bar
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

          // center: skip-back / play-pause / skip-fwd
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isVod) ...[
                  _SkipButton(icon: Icons.replay_10_rounded, onTap: onSkipBack),
                  const SizedBox(width: 24),
                ],
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
                if (isVod) ...[
                  const SizedBox(width: 24),
                  _SkipButton(icon: Icons.forward_10_rounded, onTap: onSkipFwd),
                ],
              ],
            ),
          ),

          // seek bar (VOD only)
          if (isVod)
            Positioned(
              bottom: 16, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text(fmtTime(position),
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight:          3,
                          thumbShape:           const RoundSliderThumbShape(enabledThumbRadius: 7),
                          overlayShape:         const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor:     AppColors.primary,
                          inactiveTrackColor:   Colors.white24,
                          thumbColor:           Colors.white,
                          overlayColor:         Colors.white24,
                        ),
                        child: Slider(
                          value:    position.inMilliseconds.toDouble()
                                        .clamp(0, duration.inMilliseconds.toDouble()),
                          max:      duration.inMilliseconds.toDouble(),
                          onChangeStart: (v) => onSeekStart(Duration(milliseconds: v.toInt())),
                          onChanged:     (v) => onSeekUpdate(Duration(milliseconds: v.toInt())),
                          onChangeEnd:   (v) => onSeekEnd(Duration(milliseconds: v.toInt())),
                        ),
                      ),
                    ),
                    Text(fmtTime(duration),
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      );
}

// ── Skip button ────────────────────────────────────────────────────────────────
class _SkipButton extends StatelessWidget {
  final IconData    icon;
  final VoidCallback onTap;
  const _SkipButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.4),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      );
}
