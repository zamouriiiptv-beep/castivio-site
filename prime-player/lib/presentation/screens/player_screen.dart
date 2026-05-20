import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_player_plus/better_player_plus.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with WidgetsBindingObserver {
  bool _showControls = true;
  Timer? _hideTimer;

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
      if (mounted) setState(() => _showControls = false);
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

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final ctrl = playerState.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap:           _toggleControls,
        onDoubleTapDown: (d) => _handleDoubleTap(d, context),
        behavior:        HitTestBehavior.opaque,
        child: Stack(
          children: [
            // ── Video surface — ExoPlayer renders via BetterPlayer ──
            Positioned.fill(
              child: ctrl != null
                  ? BetterPlayer(controller: ctrl)
                  : const SizedBox(),
            ),

            // ── Buffering spinner ────────────────────────────────────────
            if (playerState.isBuffering)
              const Center(child: _BufferingIndicator()),

            // ── Error overlay ────────────────────────────────────────────
            if (playerState.hasError)
              _ErrorOverlay(
                message: playerState.errorMessage,
                onRetry: () {
                  if (playerState.channel != null) {
                    ref.read(playerProvider.notifier)
                        .openChannel(playerState.channel!);
                  }
                },
                onBack: () => Navigator.pop(context),
              ),

            // ── Controls overlay (auto-hides) ────────────────────────────
            AnimatedOpacity(
              duration:  const Duration(milliseconds: 250),
              opacity:   _showControls ? 1 : 0,
              child:     IgnorePointer(
                ignoring: !_showControls,
                child:    _ControlsOverlay(
                  channel:     playerState.channel,
                  isPlaying:   playerState.isPlaying,
                  position:    playerState.position,
                  duration:    playerState.duration,
                  onBack:      () => Navigator.pop(context),
                  onPlayPause: () =>
                      ref.read(playerProvider.notifier).togglePlay(),
                  onSeek: (v) => ref.read(playerProvider.notifier).seek(
                    Duration(
                      seconds:
                          (v * playerState.duration.inSeconds).round(),
                    ),
                  ),
                  onFavorite: () {
                    final ch = playerState.channel;
                    if (ch != null) {
                      ref
                          .read(playlistRepositoryProvider)
                          .toggleFavorite(ch);
                    }
                  },
                  onExternal: () =>
                      ref.read(playerProvider.notifier).openInExternalPlayer(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDoubleTap(TapDownDetails d, BuildContext context) {
    final half = MediaQuery.of(context).size.width / 2;
    final pos  = ref.read(playerProvider).position;
    ref.read(playerProvider.notifier).seek(
      d.globalPosition.dx < half
          ? pos - const Duration(seconds: 10)
          : pos + const Duration(seconds: 10),
    );
    _resetHideTimer();
  }
}

// ── Buffering indicator ───────────────────────────────────────────────────────
class _BufferingIndicator extends StatelessWidget {
  const _BufferingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
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
}

// ── Error overlay ─────────────────────────────────────────────────────────────
class _ErrorOverlay extends StatelessWidget {
  final String?       message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  const _ErrorOverlay({this.message, this.onRetry, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 52),
            const SizedBox(height: 12),
            const Text('Stream Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            if (message != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(message!,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
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
                if (onBack != null && onRetry != null)
                  const SizedBox(width: 12),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Controls overlay ──────────────────────────────────────────────────────────
class _ControlsOverlay extends StatelessWidget {
  final Channel?   channel;
  final bool       isPlaying;
  final Duration   position, duration;
  final VoidCallback onBack, onPlayPause, onFavorite, onExternal;
  final ValueChanged<double> onSeek;

  const _ControlsOverlay({
    required this.channel,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onBack,
    required this.onPlayPause,
    required this.onSeek,
    required this.onFavorite,
    required this.onExternal,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),

        // Top bar
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
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

        // Center play/pause
        Center(
          child: GestureDetector(
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
                color: Colors.white,
                size:  36,
              ),
            ),
          ),
        ),

        // Bottom seek bar (only for VOD streams with known duration)
        if (duration > Duration.zero)
          Positioned(
            bottom: 12, left: 16, right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(position),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    Text(_fmt(duration),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14),
                    activeTrackColor:   AppColors.accent,
                    inactiveTrackColor: Colors.white24,
                    thumbColor:         AppColors.accent,
                  ),
                  child: Slider(
                    value: duration.inSeconds > 0
                        ? (position.inSeconds / duration.inSeconds)
                            .clamp(0.0, 1.0)
                        : 0,
                    onChanged: onSeek,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
