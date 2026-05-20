import 'dart:async';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
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
  Timer?                  _bufferTimeout;

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
      _bufferTimeout?.cancel();
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
        _bufferTimeout?.cancel();
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
      final streamUrl = _preferHls(channel.streamUrl);
      final fmt = _detectFormat(streamUrl);
      await ctrl.setupDataSource(
        BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          streamUrl,
          liveStream:        _isLikelyLive(streamUrl),
          videoFormat:       fmt,
          useAsmsTracks:     fmt == BetterPlayerVideoFormat.hls,
          useAsmsAudioTracks: fmt == BetterPlayerVideoFormat.hls,
          useAsmsSubtitles:  false,
          headers: const {
            'Connection': 'keep-alive',
            'User-Agent': 'VLC/3.0.18 LibVLC/3.0.18',
            'Accept': '*/*',
          },
          bufferingConfiguration: const BetterPlayerBufferingConfiguration(
            minBufferMs:                      500,
            maxBufferMs:                     4000,
            bufferForPlaybackMs:              500,
            bufferForPlaybackAfterRebufferMs: 1000,
          ),
          cacheConfiguration: const BetterPlayerCacheConfiguration(useCache: false),
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

    // If stream doesn't start within 15s, show error with external player suggestion.
    _bufferTimeout?.cancel();
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
      final streamUrl = _preferHls(channel.streamUrl);
      final isLive    = _isLikelyLive(streamUrl);
      final fmt       = _detectFormat(streamUrl);
      debugPrint('[Player] open: $streamUrl live=$isLive fmt=$fmt');

      await ctrl.setupDataSource(
        BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          streamUrl,
          liveStream: isLive,
          videoFormat: fmt,
          useAsmsTracks: fmt == BetterPlayerVideoFormat.hls,
          useAsmsAudioTracks: fmt == BetterPlayerVideoFormat.hls,
          useAsmsSubtitles: false,
          headers: const {
            'Connection': 'keep-alive',
            'User-Agent': 'VLC/3.0.18 LibVLC/3.0.18',
            'Accept': '*/*',
            'Icy-MetaData': '1',
          },
          bufferingConfiguration: const BetterPlayerBufferingConfiguration(
            minBufferMs:                     1500,
            maxBufferMs:                    15000,
            bufferForPlaybackMs:              500,
            bufferForPlaybackAfterRebufferMs: 2000,
          ),
          cacheConfiguration: const BetterPlayerCacheConfiguration(useCache: false),
        ),
      );
      // setupDataSource enqueues play when autoPlay:true; one explicit call
      // covers the case where the controller was already initialized.
      ctrl.play();
    } catch (e, st) {
      debugPrint('[Player] setupDataSource failed: $e\n$st');
      _bufferTimeout?.cancel();
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

  /// Rewrite Xtream Codes live URLs to HLS format.
  /// Xtream servers expose every live stream as both MPEG-TS (.ts) and HLS
  /// (.m3u8). ExoPlayer handles adaptive HLS far more reliably than raw
  /// MPEG-TS over HTTP, so we always prefer the HLS variant for live paths.
  String _preferHls(String url) {
    if (url.toLowerCase().contains('/live/') &&
        url.toLowerCase().endsWith('.ts')) {
      return '${url.substring(0, url.length - 3)}.m3u8';
    }
    return url;
  }

  BetterPlayerVideoFormat _detectFormat(String url) {
    final lower = url.toLowerCase().split('?').first;
    if (lower.endsWith('.m3u8') || lower.contains('.m3u8?')) {
      return BetterPlayerVideoFormat.hls;
    }
    if (lower.endsWith('.mpd')) {
      return BetterPlayerVideoFormat.dash;
    }
    if (lower.endsWith('.ism') || lower.endsWith('/manifest')) {
      return BetterPlayerVideoFormat.ss;
    }
    return BetterPlayerVideoFormat.other;
  }

  void togglePlay() {
    final ctrl = _activeCtrl;
    if (ctrl == null) return;
    if (state.isPlaying) ctrl.pause(); else ctrl.play();
  }

  void seek(Duration position) => _activeCtrl?.seekTo(position);

  /// Opens the current channel in an external player (VLC, MX Player, etc.)
  Future<void> openInExternalPlayer() async {
    final url = state.channel?.streamUrl;
    if (url == null) return;
    try {
      final intent = AndroidIntent(
        action: 'action_view',
        data: url,
        type: 'video/*',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (_) {}
  }

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
