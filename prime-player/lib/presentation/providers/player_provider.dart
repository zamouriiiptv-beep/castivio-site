import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../data/models/channel.dart';

class PlayerState {
  final Channel?         channel;
  final VideoController? controller;
  final bool             isPlaying;
  final bool             isBuffering;
  final bool             hasError;
  final String?          errorMessage;
  final Duration         position;
  final Duration         duration;

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
    Channel?         channel,
    VideoController? controller,
    bool?            isPlaying,
    bool?            isBuffering,
    bool?            hasError,
    String?          errorMessage,
    Duration?        position,
    Duration?        duration,
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
  late final Player          _player;
  late final VideoController _controller;
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  PlayerState build() {
    _player = Player(
      configuration: PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024, // 32 MB — smoother live TV
        logLevel:   MPVLogLevel.error,
      ),
    );
    _controller = VideoController(_player);

    _subs.addAll([
      _player.stream.playing.listen((v) {
        state = state.copyWith(isPlaying: v);
        if (v) WakelockPlus.enable();
      }),
      _player.stream.buffering.listen((v) {
        state = state.copyWith(isBuffering: v);
      }),
      _player.stream.position.listen((v) {
        state = state.copyWith(position: v);
      }),
      _player.stream.duration.listen((v) {
        state = state.copyWith(duration: v);
      }),
      _player.stream.error.listen((v) {
        if (v.isNotEmpty) {
          state = state.copyWith(
            hasError:     true,
            errorMessage: v,
            isBuffering:  false,
          );
        }
      }),
    ]);

    ref.onDispose(() {
      for (final s in _subs) { s.cancel(); }
      _player.dispose();
    });

    return PlayerState(controller: _controller);
  }

  /// Opens a channel. libmpv starts playing almost instantly — no initialize() wait.
  Future<void> openChannel(Channel channel) async {
    // Reset state immediately — UI shows spinner right away
    state = PlayerState(
      channel:     channel,
      controller:  _controller,
      isBuffering: true,
    );

    try {
      await _player.open(
        Media(
          channel.streamUrl,
          httpHeaders: const {'Connection': 'keep-alive'},
        ),
      );
      WakelockPlus.enable();
    } catch (e) {
      state = state.copyWith(
        hasError:     true,
        errorMessage: e.toString(),
        isBuffering:  false,
      );
    }
  }

  void togglePlay() => _player.playOrPause();

  void seek(Duration position) => _player.seek(position);

  void stop() {
    _player.stop();
    WakelockPlus.disable();
    state = PlayerState(controller: _controller);
  }
}

final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);
