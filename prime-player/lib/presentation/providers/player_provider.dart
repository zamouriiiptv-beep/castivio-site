import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
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
  PlayerNotifier(this._player, this._controller);

  final Player          _player;
  final VideoController _controller;
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  PlayerState build() {
    _subs.addAll([
      _player.stream.playing.listen((v) {
        state = state.copyWith(isPlaying: v);
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
    });

    return PlayerState(controller: _controller);
  }

  Future<void> openChannel(Channel channel) async {
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
    state = PlayerState(controller: _controller);
  }
}

final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(
  () => throw UnimplementedError('playerProvider must be overridden in main()'),
);
