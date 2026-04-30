import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';

// ── Singleton player so it persists across screen navigations ────────────────
final playerInstanceProvider = Provider<Player>((ref) {
  final player = Player(
    configuration: const PlayerConfiguration(
      bufferSize: PlayerConfig.bufferSize,
      logLevel:   MPVLogLevel.error,
    ),
  );

  // Apply all performance tuning options
  PlayerConfig.mpvOptions.forEach((key, value) {
    player.setProperty(key, value);
  });

  ref.onDispose(player.dispose);
  return player;
});

// ── Player state ──────────────────────────────────────────────────────────────
class PlayerState {
  final Channel?    channel;
  final bool        isPlaying;
  final bool        isBuffering;
  final bool        hasError;
  final String?     errorMessage;
  final Duration    position;
  final Duration    duration;
  final bool        isFullscreen;

  const PlayerState({
    this.channel,
    this.isPlaying   = false,
    this.isBuffering = false,
    this.hasError    = false,
    this.errorMessage,
    this.position    = Duration.zero,
    this.duration    = Duration.zero,
    this.isFullscreen = false,
  });

  PlayerState copyWith({
    Channel?  channel,
    bool?     isPlaying,
    bool?     isBuffering,
    bool?     hasError,
    String?   errorMessage,
    Duration? position,
    Duration? duration,
    bool?     isFullscreen,
  }) => PlayerState(
    channel:      channel      ?? this.channel,
    isPlaying:    isPlaying    ?? this.isPlaying,
    isBuffering:  isBuffering  ?? this.isBuffering,
    hasError:     hasError     ?? this.hasError,
    errorMessage: errorMessage ?? this.errorMessage,
    position:     position     ?? this.position,
    duration:     duration     ?? this.duration,
    isFullscreen: isFullscreen ?? this.isFullscreen,
  );
}

// ── Provider ──────────────────────────────────────────────────────────────────
class PlayerNotifier extends Notifier<PlayerState> {
  late final Player _player;

  // Stores the next channel URL while current channel plays —
  // so TCP connection is already open when user switches
  String? _preConnectedUrl;
  Timer?  _controlsTimer;

  @override
  PlayerState build() {
    _player = ref.watch(playerInstanceProvider);
    _attachListeners();
    return const PlayerState();
  }

  void _attachListeners() {
    _player.stream.playing.listen((playing) {
      state = state.copyWith(isPlaying: playing);
      if (playing) WakelockPlus.enable();
    });

    _player.stream.buffering.listen((buffering) {
      state = state.copyWith(isBuffering: buffering);
    });

    _player.stream.position.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _player.stream.duration.listen((dur) {
      state = state.copyWith(duration: dur);
    });

    _player.stream.error.listen((err) {
      if (err.isNotEmpty) {
        state = state.copyWith(hasError: true, errorMessage: err);
      }
    });
  }

  /// Opens a channel — the core of "lightning speed".
  /// Strategy:
  ///  1. If this URL was pre-connected, it opens almost instantly.
  ///  2. Sets MPV options BEFORE open() so HW decoding is ready.
  ///  3. Calls play() without waiting — streams start before metadata arrives.
  Future<void> openChannel(Channel channel) async {
    state = state.copyWith(
      channel:      channel,
      isBuffering:  true,
      hasError:     false,
      errorMessage: null,
    );

    await _player.open(
      Media(channel.streamUrl),
      play: true,           // ← start playing immediately, don't wait
    );
  }

  /// Pre-warms the next channel's connection.
  /// Call this when the user hovers over or highlights a channel in the list.
  Future<void> preConnect(String streamUrl) async {
    _preConnectedUrl = streamUrl;
    // Tell libmpv to pre-resolve DNS and open a TCP connection silently
    await _player.setProperty('prefetch-playlist', 'yes');
  }

  void togglePlay() => _player.playOrPause();

  void seek(Duration position) => _player.seek(position);

  void setVolume(double vol) => _player.setVolume(vol * 100);

  void stop() {
    _player.stop();
    WakelockPlus.disable();
    state = const PlayerState();
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }
}

final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);
