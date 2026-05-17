import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/channel.dart';

class PlayerState {
  final Channel?               channel;
  final BetterPlayerController? controller;
  final bool                   isPlaying;
  final bool                   isBuffering;
  final bool                   hasError;
  final String?                errorMessage;
  final Duration               position;
  final Duration               duration;

  const PlayerState({
    this.channel,
    this.controller,
    this.isPlaying   = false,
    this.isBuffering = false,
    this.hasError    = false,
    this.errorMessage,
    this.position    = Duration.zero,
    this.duration    = Duration.zero,
  });

  PlayerState copyWith({
    Channel?                channel,
    BetterPlayerController? controller,
    bool?                   isPlaying,
    bool?                   isBuffering,
    bool?                   hasError,
    String?                 errorMessage,
    Duration?               position,
    Duration?               duration,
  }) => PlayerState(
    channel:      channel      ?? this.channel,
    controller:   controller   ?? this.controller,
    isPlaying:    isPlaying    ?? this.isPlaying,
    isBuffering:  isBuffering  ?? this.isBuffering,
    hasError:     hasError     ?? this.hasError,
    errorMessage: errorMessage ?? this.errorMessage,
    position:     position     ?? this.position,
    duration:     duration     ?? this.duration,
  );
}

class PlayerNotifier extends Notifier<PlayerState> {
  BetterPlayerController? _controller;

  @override
  PlayerState build() {
    final controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay:        true,
        fit:             BoxFit.contain,
        looping:         false,
        handleLifecycle: false,
        autoDispose:     false,
        expandToFill:    true,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false,
        ),
        errorBuilder: _hiddenErrorBuilder,
      ),
    );
    controller.addEventsListener(_onEvent);
    _controller = controller;

    ref.onDispose(() {
      controller.removeEventsListener(_onEvent);
      controller.dispose();
      _controller = null;
    });

    return PlayerState(controller: controller);
  }

  void _onEvent(BetterPlayerEvent event) {
    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.play:
        state = state.copyWith(isPlaying: true, isBuffering: false);
        break;
      case BetterPlayerEventType.pause:
        state = state.copyWith(isPlaying: false);
        break;
      case BetterPlayerEventType.bufferingStart:
        state = state.copyWith(isBuffering: true);
        break;
      case BetterPlayerEventType.bufferingEnd:
        state = state.copyWith(isBuffering: false);
        break;
      case BetterPlayerEventType.progress:
        final pos = event.parameters?['progress'] as Duration?;
        final dur = event.parameters?['duration'] as Duration?;
        state = state.copyWith(
          position: pos ?? state.position,
          duration: dur ?? state.duration,
        );
        break;
      case BetterPlayerEventType.initialized:
        state = state.copyWith(isBuffering: false);
        break;
      case BetterPlayerEventType.exception:
        final msg = event.parameters?['exception']?.toString();
        state = state.copyWith(
          hasError:     true,
          errorMessage: msg,
          isBuffering:  false,
        );
        break;
      default:
        break;
    }
  }

  /// Pre-warm a connection to the given URL (HEAD request) so the actual
  /// open() call has a hot DNS cache + TCP handshake ready. Best-effort, never throws.
  Future<void> preConnect(String url) async {
    // ExoPlayer manages its own connections; the DoH interceptor + DNS cache
    // already give us a warm path. This is a no-op kept for API compatibility.
  }

  Future<void> openChannel(Channel channel) async {
    final ctrl = _controller;
    if (ctrl == null) return;

    state = PlayerState(
      channel:     channel,
      controller:  ctrl,
      isBuffering: true,
    );

    try {
      await ctrl.setupDataSource(
        BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          channel.streamUrl,
          liveStream: _isLikelyLive(channel.streamUrl),
          headers:    const {'Connection': 'keep-alive'},
          bufferingConfiguration: const BetterPlayerBufferingConfiguration(
            minBufferMs:                       1500,
            maxBufferMs:                      15000,
            bufferForPlaybackMs:                500,
            bufferForPlaybackAfterRebufferMs:  2000,
          ),
        ),
      );
    } catch (e) {
      state = state.copyWith(
        hasError:     true,
        errorMessage: e.toString(),
        isBuffering:  false,
      );
    }
  }

  bool _isLikelyLive(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('/movie/')  || lower.contains('/series/')) return false;
    if (lower.endsWith('.mp4')     || lower.endsWith('.mkv') ||
        lower.endsWith('.avi')     || lower.endsWith('.mov')) return false;
    return true;
  }

  void togglePlay() {
    final ctrl = _controller;
    if (ctrl == null) return;
    if (state.isPlaying) {
      ctrl.pause();
    } else {
      ctrl.play();
    }
  }

  void seek(Duration position) {
    _controller?.seekTo(position);
  }

  void stop() {
    final ctrl = _controller;
    if (ctrl == null) return;
    try {
      ctrl.pause();
    } catch (_) {}
    state = PlayerState(controller: ctrl);
  }
}

Widget _hiddenErrorBuilder(BuildContext context, String? errorMessage) {
  return const SizedBox.shrink();
}

final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);
