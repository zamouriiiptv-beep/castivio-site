import 'dart:io';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/channel.dart';

class PlayerState {
  final Channel?                channel;
  final BetterPlayerController? controller;
  final bool                    isPlaying;
  final bool                    isBuffering;
  final bool                    hasError;
  final String?                 errorMessage;
  final Duration                position;
  final Duration                duration;

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
  BetterPlayerController? _activeCtrl;
  BetterPlayerController? _preloadCtrl;
  Channel?                _preloadedChannel;

  @override
  PlayerState build() {
    _activeCtrl = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay:        true,
        fit:             BoxFit.contain,
        looping:         false,
        handleLifecycle: false,
        autoDispose:     false,
        expandToFill:    true,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
            showControls: false),
        errorBuilder: _hiddenErrorBuilder,
      ),
    );
    _activeCtrl!.addEventsListener(_onEvent);

    ref.onDispose(() {
      _activeCtrl?.removeEventsListener(_onEvent);
      _activeCtrl?.dispose();
      _preloadCtrl?.dispose();
      _activeCtrl       = null;
      _preloadCtrl      = null;
      _preloadedChannel = null;
    });

    return PlayerState(controller: _activeCtrl);
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

  /// DNS pre-warm on pointer-down so ExoPlayer's OkHttp finds a cached
  /// answer ~100–300 ms later when the actual tap fires.
  Future<void> preConnect(String url) async {
    try {
      final host = Uri.parse(url).host;
      if (host.isNotEmpty) await InternetAddress.lookup(host);
    } catch (_) {}
  }

  /// Load [channel] into a silent background ExoPlayer instance.
  /// If the user later taps this channel, controllers are swapped in <100 ms
  /// because the HLS manifest + first segments are already in memory.
  Future<void> preloadChannel(Channel channel) async {
    if (_preloadedChannel?.streamUrl == channel.streamUrl) return;

    // Drop any previous preload for a different channel.
    _preloadCtrl?.dispose();
    _preloadCtrl      = null;
    _preloadedChannel = null;

    final ctrl = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay:        false, // silent — no audio in background
        fit:             BoxFit.contain,
        handleLifecycle: false,
        autoDispose:     false,
        expandToFill:    true,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
            showControls: false),
        errorBuilder: _hiddenErrorBuilder,
      ),
    );

    try {
      await ctrl.setupDataSource(
        BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          channel.streamUrl,
          liveStream: _isLikelyLive(channel.streamUrl),
          headers:    const {'Connection': 'keep-alive'},
          bufferingConfiguration: const BetterPlayerBufferingConfiguration(
            minBufferMs:                      500,
            maxBufferMs:                     4000,
            bufferForPlaybackMs:              200,
            bufferForPlaybackAfterRebufferMs: 1000,
          ),
        ),
      );
      _preloadCtrl      = ctrl;
      _preloadedChannel = channel;
    } catch (_) {
      ctrl.dispose(); // silent failure — falls back to normal load
    }
  }

  Future<void> openChannel(Channel channel) async {
    // ── Fast path: preloaded controller is ready ──────────────────────────
    if (_preloadedChannel?.streamUrl == channel.streamUrl &&
        _preloadCtrl != null) {
      final incoming = _preloadCtrl!;
      final retiring  = _activeCtrl;

      _preloadCtrl      = null;
      _preloadedChannel = null;
      _activeCtrl       = incoming;

      retiring?.removeEventsListener(_onEvent);
      incoming.addEventsListener(_onEvent);

      state = PlayerState(
        channel:     channel,
        controller:  incoming,
        isBuffering: false,
        isPlaying:   true,
      );
      incoming.play();

      // Retire old controller off the critical path.
      Future.microtask(() => retiring?.dispose());
      return;
    }

    // ── Normal path ───────────────────────────────────────────────────────
    final ctrl = _activeCtrl;
    if (ctrl == null) return;

    // Cancel any in-flight preload for a different channel.
    _preloadCtrl?.dispose();
    _preloadCtrl      = null;
    _preloadedChannel = null;

    state = PlayerState(channel: channel, controller: ctrl, isBuffering: true);

    try {
      await ctrl.setupDataSource(
        BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          channel.streamUrl,
          liveStream: _isLikelyLive(channel.streamUrl),
          headers:    const {'Connection': 'keep-alive'},
          bufferingConfiguration: const BetterPlayerBufferingConfiguration(
            minBufferMs:                       800,
            maxBufferMs:                     10000,
            bufferForPlaybackMs:               200,
            bufferForPlaybackAfterRebufferMs:  1000,
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
    final ctrl = _activeCtrl;
    if (ctrl == null) return;
    if (state.isPlaying) ctrl.pause(); else ctrl.play();
  }

  void seek(Duration position) => _activeCtrl?.seekTo(position);

  void stop() {
    final ctrl = _activeCtrl;
    if (ctrl == null) return;
    try { ctrl.pause(); } catch (_) {}
    state = PlayerState(controller: ctrl);
  }
}

Widget _hiddenErrorBuilder(BuildContext context, String? errorMessage) =>
    const SizedBox.shrink();

final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);
