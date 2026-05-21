import 'dart:async';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/widgets.dart';
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
  late final Player          _player;
  late final VideoController _videoCtrl;
  Timer? _bufferTimeout;

  @override
  PlayerState build() {
    _player    = Player();
    _videoCtrl = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        // Try hardware decode, fall back to software automatically.
        // Without this, HEVC/H.265 streams throw "Could not open codec".
        hwdec: 'auto-safe',
      ),
    );

    _player.stream.playing.listen((playing) {
      _bufferTimeout?.cancel();
      state = state.copyWith(isPlaying: playing, isBuffering: false,
          hasError: false);
    });

    _player.stream.buffering.listen((buffering) {
      state = state.copyWith(isBuffering: buffering);
    });

    _player.stream.error.listen((err) {
      _bufferTimeout?.cancel();
      state = state.copyWith(
        hasError:     true,
        errorMessage: err,
        isBuffering:  false,
      );
    });

    _player.stream.position.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _player.stream.duration.listen((dur) {
      state = state.copyWith(duration: dur);
    });

    ref.onDispose(() {
      _bufferTimeout?.cancel();
      _player.dispose();
    });

    return PlayerState(controller: _videoCtrl);
  }

  /// DNS pre-warm on pointer-down.
  Future<void> preConnect(String url) async {
    try {
      final host = Uri.parse(url).host;
      if (host.isNotEmpty) await InternetAddress.lookup(host);
    } catch (_) {}
  }

  Future<void> openChannel(Channel channel) async {
    _bufferTimeout?.cancel();

    state = PlayerState(
      channel:     channel,
      controller:  _videoCtrl,
      isBuffering: true,
    );

    _bufferTimeout = Timer(const Duration(seconds: 15), () {
      if (state.isBuffering || (!state.isPlaying && !state.hasError)) {
        state = state.copyWith(
          hasError:     true,
          errorMessage: 'تعذر تشغيل البث. جرب المشغل الخارجي (VLC أو MX Player).',
          isBuffering:  false,
        );
      }
    });

    try {
      final url = channel.streamUrl;
      debugPrint('[Player] open: $url');
      await _player.open(
        Media(url, httpHeaders: const {
          'User-Agent': 'VLC/3.0.18 LibVLC/3.0.18',
          'Connection': 'keep-alive',
          'Accept':     '*/*',
        }),
        play: true,
      );
    } catch (e, st) {
      debugPrint('[Player] open failed: $e\n$st');
      _bufferTimeout?.cancel();
      state = state.copyWith(
        hasError:     true,
        errorMessage: e.toString(),
        isBuffering:  false,
      );
    }
  }

  void togglePlay() => _player.playOrPause();

  void seek(Duration position) => _player.seek(position);

  Future<void> openInExternalPlayer() async {
    final url = state.channel?.streamUrl;
    if (url == null) return;
    try {
      final intent = AndroidIntent(
        action: 'action_view',
        data:   url,
        type:   'video/*',
        flags:  [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (_) {}
  }

  void stop() {
    _player.stop();
    state = PlayerState(controller: _videoCtrl);
  }
}

final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);
