import 'dart:async';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../data/models/channel.dart';
import 'playlist_provider.dart';

class PlayerState {
  final Channel?            channel;
  final VideoController?    controller;
  final bool                isPlaying;
  final bool                isBuffering;
  final bool                hasError;
  final String?             errorMessage;
  final Duration            position;
  final Duration            duration;
  final List<SubtitleTrack> subtitleTracks;
  final SubtitleTrack?      subtitleTrack;
  final Duration?           savedPosition;

  const PlayerState({
    this.channel,
    this.controller,
    this.isPlaying      = false,
    this.isBuffering    = false,
    this.hasError       = false,
    this.errorMessage,
    this.position       = Duration.zero,
    this.duration       = Duration.zero,
    this.subtitleTracks = const [],
    this.subtitleTrack,
    this.savedPosition,
  });

  PlayerState copyWith({
    Channel?             channel,
    VideoController?     controller,
    bool?                isPlaying,
    bool?                isBuffering,
    bool?                hasError,
    String?              errorMessage,
    Duration?            position,
    Duration?            duration,
    List<SubtitleTrack>? subtitleTracks,
    SubtitleTrack?       subtitleTrack,
    bool                 clearSubtitleTrack  = false,
    Duration?            savedPosition,
    bool                 clearSavedPosition  = false,
  }) => PlayerState(
    channel:        channel        ?? this.channel,
    controller:     controller     ?? this.controller,
    isPlaying:      isPlaying      ?? this.isPlaying,
    isBuffering:    isBuffering    ?? this.isBuffering,
    hasError:       hasError       ?? this.hasError,
    errorMessage:   errorMessage   ?? this.errorMessage,
    position:       position       ?? this.position,
    duration:       duration       ?? this.duration,
    subtitleTracks: subtitleTracks ?? this.subtitleTracks,
    subtitleTrack:  clearSubtitleTrack  ? null : (subtitleTrack  ?? this.subtitleTrack),
    savedPosition:  clearSavedPosition ? null : (savedPosition  ?? this.savedPosition),
  );
}

class PlayerNotifier extends Notifier<PlayerState> {
  late final Player          _player;
  late final VideoController _videoCtrl;
  Timer? _bufferTimeout;
  bool   _markedWatched = false;

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
      // Save every 30 seconds for VOD only
      if (pos.inSeconds > 0 && pos.inSeconds % 30 == 0 &&
          state.duration > Duration.zero) {
        _savePosition();
      }
    });

    _player.stream.duration.listen((dur) {
      state = state.copyWith(duration: dur);
    });

    _player.stream.tracks.listen((tracks) {
      state = state.copyWith(subtitleTracks: tracks.subtitle);
    });

    _player.stream.track.listen((track) {
      state = state.copyWith(subtitleTrack: track.subtitle);
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
    _markedWatched = false;

    // Load saved position for VOD (id starts with 'vod_') — non-fatal
    Duration? saved;
    if (channel.id.startsWith('vod_')) {
      try {
        final storage = ref.read(storageServiceProvider);
        final ms      = storage.getSavedPositionMs(channel.id);
        if (ms != null && ms > 30000) saved = Duration(milliseconds: ms);
      } catch (e) {
        debugPrint('[Player] saved position load failed: $e');
      }
    }

    state = PlayerState(
      channel:       channel,
      controller:    _videoCtrl,
      isBuffering:   true,
      savedPosition: saved,
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
    await openUrlInExternalPlayer(url);
  }

  Future<void> openUrlInExternalPlayer(String url) async {
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

  void setSubtitleTrack(SubtitleTrack track) {
    _player.setSubtitleTrack(track);
    state = state.copyWith(subtitleTrack: track);
  }

  void dismissSavedPosition() {
    state = state.copyWith(clearSavedPosition: true);
  }

  Future<void> deleteSavedPosition() async {
    final ch = state.channel;
    if (ch == null) return;
    await ref.read(storageServiceProvider).clearWatchData(ch.id);
    state = state.copyWith(clearSavedPosition: true);
  }

  Future<void> _savePosition() async {
    try {
      final ch  = state.channel;
      final pos = state.position;
      final dur = state.duration;
      if (ch == null || pos <= Duration.zero) return;
      if (!ch.id.startsWith('vod_')) return;
      if (_markedWatched) return;

      final storage = ref.read(storageServiceProvider);

      // Mark watched when ≥80% viewed
      if (dur > Duration.zero &&
          pos.inMilliseconds / dur.inMilliseconds >= 0.8) {
        await storage.markWatched(ch.id);
        _markedWatched = true;
        ref.read(watchRefreshProvider.notifier).state++;
        return;
      }

      await storage.savePositionMs(ch.id, pos.inMilliseconds);
      if (dur > Duration.zero) {
        await storage.saveDurationMs(ch.id, dur.inMilliseconds);
      }
      ref.read(watchRefreshProvider.notifier).state++;
    } catch (e) {
      debugPrint('[Player] save position failed: $e');
    }
  }

  void stop() {
    _savePosition();
    _player.stop();
    state = PlayerState(controller: _videoCtrl);
  }
}

final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);
