import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../data/models/channel.dart';

class PlayerState {
  final Channel?               channel;
  final VideoPlayerController? controller;
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
    Channel?               channel,
    VideoPlayerController? controller,
    bool?                  isPlaying,
    bool?                  isBuffering,
    bool?                  hasError,
    String?                errorMessage,
    Duration?              position,
    Duration?              duration,
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
  VideoPlayerController? _current;
  VideoPlayerController? _prewarmed; // pre-warmed for next channel
  Timer? _posTimer;

  @override
  PlayerState build() => const PlayerState();

  Future<void> openChannel(Channel channel) async {
    // Dispose previous
    _posTimer?.cancel();
    final old = _current;
    _current = null;

    state = state.copyWith(
      channel:      channel,
      controller:   null,
      isBuffering:  true,
      hasError:     false,
      errorMessage: null,
      isPlaying:    false,
      position:     Duration.zero,
      duration:     Duration.zero,
    );

    old?.removeListener(_onUpdate);
    old?.dispose();

    try {
      VideoPlayerController ctrl;

      // Use pre-warmed controller if URL matches
      if (_prewarmed != null &&
          _prewarmed!.dataSource == channel.streamUrl &&
          _prewarmed!.value.isInitialized) {
        ctrl = _prewarmed!;
        _prewarmed = null;
      } else {
        _prewarmed?.dispose();
        _prewarmed = null;
        ctrl = _makeController(channel.streamUrl);
        await ctrl.initialize();
      }

      ctrl.addListener(_onUpdate);
      _current = ctrl;

      await ctrl.play();
      WakelockPlus.enable();

      state = state.copyWith(
        controller:  ctrl,
        isBuffering: false,
        isPlaying:   true,
        duration:    ctrl.value.duration,
      );

      _posTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (_current != null && _current!.value.isInitialized) {
          state = state.copyWith(position: _current!.value.position);
        }
      });
    } catch (e) {
      state = state.copyWith(
        hasError:     true,
        errorMessage: e.toString(),
        isBuffering:  false,
      );
    }
  }

  void _onUpdate() {
    final ctrl = _current;
    if (ctrl == null) return;
    final v = ctrl.value;
    state = state.copyWith(
      isPlaying:    v.isPlaying,
      isBuffering:  v.isBuffering,
      hasError:     v.hasError,
      errorMessage: v.hasError ? v.errorDescription : null,
      duration:     v.duration,
    );
    if (v.isPlaying) WakelockPlus.enable();
  }

  /// Pre-warm TCP connection for next channel on pointer-down.
  Future<void> preConnect(String streamUrl) async {
    if (_prewarmed?.dataSource == streamUrl) return;
    _prewarmed?.dispose();
    _prewarmed = _makeController(streamUrl);
    try {
      await _prewarmed!.initialize();
    } catch (_) {
      _prewarmed = null;
    }
  }

  VideoPlayerController _makeController(String url) =>
      VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {'Connection': 'keep-alive'},
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: false),
      );

  void togglePlay() {
    final ctrl = _current;
    if (ctrl == null) return;
    if (ctrl.value.isPlaying) {
      ctrl.pause();
      WakelockPlus.disable();
    } else {
      ctrl.play();
      WakelockPlus.enable();
    }
  }

  void seek(Duration position) => _current?.seekTo(position);

  void stop() {
    _posTimer?.cancel();
    _current?.removeListener(_onUpdate);
    _current?.dispose();
    _current = null;
    _prewarmed?.dispose();
    _prewarmed = null;
    WakelockPlus.disable();
    state = const PlayerState();
  }
}

final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);
