import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' show SubtitleTrack;
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';

// ignore_for_file: use_build_context_synchronously

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with WidgetsBindingObserver {
  bool      _showControls = true;
  Timer?    _hideTimer;
  bool      _isSeeking    = false;
  Duration  _dragPosition = Duration.zero;
  BoxFit    _videoFit     = BoxFit.contain;
  bool      _showFitToast = false;
  Timer?    _toastTimer;

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
    _toastTimer?.cancel();
    ref.read(playerProvider.notifier).stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    setState(() => _showControls = true);
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_isSeeking) setState(() => _showControls = false);
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

  void _onDoubleTap() {
    setState(() {
      _videoFit     = _videoFit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
      _showFitToast = true;
    });
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showFitToast = false);
    });
  }

  void _onSeekStart(Duration pos) {
    _hideTimer?.cancel();
    setState(() { _isSeeking = true; _dragPosition = pos; });
  }

  void _onSeekUpdate(Duration pos) => setState(() => _dragPosition = pos);

  void _onSeekEnd(Duration pos) {
    ref.read(playerProvider.notifier).seek(pos);
    setState(() => _isSeeking = false);
    _resetHideTimer();
  }

  void _showSubtitleSheet() {
    _hideTimer?.cancel();
    final ps     = ref.read(playerProvider);
    final tracks = ps.subtitleTracks
        .where((t) => t.id != 'no' && t.id != 'auto')
        .toList();
    SubtitleTrack? selected = ps.subtitleTrack?.id == 'no' || ps.subtitleTrack == null
        ? null
        : ps.subtitleTrack;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: const Text('الترجمة',
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w700)),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Off option
                    RadioListTile<String>(
                      value: 'no',
                      groupValue: selected?.id ?? 'no',
                      activeColor: AppColors.primary,
                      title: const Text('إيقاف الترجمة',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      onChanged: (_) => setDialogState(() => selected = null),
                    ),
                    if (tracks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('لا توجد ترجمة في هذا الملف',
                            style: TextStyle(color: AppColors.textMuted,
                                fontSize: 12)),
                      ),
                    ...tracks.map((t) => RadioListTile<String>(
                      value: t.id,
                      groupValue: selected?.id ?? 'no',
                      activeColor: AppColors.primary,
                      title: Text(_langName(t),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                      onChanged: (_) => setDialogState(() => selected = t),
                    )),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _resetHideTimer();
                },
                child: const Text('إلغاء',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selected == null) {
                    ref.read(playerProvider.notifier)
                        .setSubtitleTrack(SubtitleTrack.no());
                  } else {
                    ref.read(playerProvider.notifier)
                        .setSubtitleTrack(selected!);
                  }
                  Navigator.pop(ctx);
                  _resetHideTimer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('حسنًا'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(_resetHideTimer);
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _showResumeDialog(Duration savedPos) {
    _hideTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResumeDialog(
        savedPosition: savedPos,
        fmtTime: _fmt,
        onResume: () {
          Navigator.pop(context);
          ref.read(playerProvider.notifier).seek(savedPos);
          ref.read(playerProvider.notifier).dismissSavedPosition();
          _resetHideTimer();
        },
        onFresh: () {
          Navigator.pop(context);
          ref.read(playerProvider.notifier).deleteSavedPosition();
          _resetHideTimer();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ps   = ref.watch(playerProvider);
    final ctrl = ps.controller;
    final isVod = ps.duration > Duration.zero;
    final displayPos = _isSeeking ? _dragPosition : ps.position;

    ref.listen<PlayerState>(playerProvider, (prev, next) {
      if (next.savedPosition != null && prev?.savedPosition == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showResumeDialog(next.savedPosition!);
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap:       _toggleControls,
        onDoubleTap: _onDoubleTap,
        behavior:    HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned.fill(
              child: ctrl != null
                  ? Video(
                      controller: ctrl,
                      controls:   NoVideoControls,
                      fill:       Colors.black,
                      fit:        _videoFit,
                    )
                  : const SizedBox(),
            ),

            if (ps.isBuffering)
              const Center(child: _BufferingIndicator()),

            if (ps.hasError && !ps.isPlaying)
              _ErrorOverlay(
                message:    ps.errorMessage,
                onRetry:    () {
                  if (ps.channel != null) {
                    ref.read(playerProvider.notifier).openChannel(ps.channel!);
                  }
                },
                onBack:     () => Navigator.pop(context),
                onExternal: () =>
                    ref.read(playerProvider.notifier).openInExternalPlayer(),
              ),

            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity:  _showControls ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_showControls,
                child: _ControlsOverlay(
                  channel:        ps.channel,
                  isPlaying:      ps.isPlaying,
                  isVod:          isVod,
                  position:       displayPos,
                  duration:       ps.duration,
                  hasSubtitles:   ps.subtitleTracks
                      .any((t) => t.id != 'no' && t.id != 'auto'),
                  subtitleActive: ps.subtitleTrack != null &&
                      ps.subtitleTrack!.id != 'no',
                  onBack:         () => Navigator.pop(context),
                  onPlayPause:    () =>
                      ref.read(playerProvider.notifier).togglePlay(),
                  onFavorite: () {
                    final ch = ps.channel;
                    if (ch != null) {
                      ref.read(playlistRepositoryProvider).toggleFavorite(ch);
                    }
                  },
                  onExternal:    () =>
                      ref.read(playerProvider.notifier).openInExternalPlayer(),
                  onSubtitleTap: _showSubtitleSheet,
                  onSkipBack: () {
                    final ms = (ps.position.inMilliseconds - 10000)
                        .clamp(0, ps.duration.inMilliseconds);
                    ref.read(playerProvider.notifier)
                        .seek(Duration(milliseconds: ms));
                  },
                  onSkipFwd: () {
                    final ms = (ps.position.inMilliseconds + 10000)
                        .clamp(0, ps.duration.inMilliseconds);
                    ref.read(playerProvider.notifier)
                        .seek(Duration(milliseconds: ms));
                  },
                  onSeekStart:  _onSeekStart,
                  onSeekUpdate: _onSeekUpdate,
                  onSeekEnd:    _onSeekEnd,
                  fmtTime:      _fmt,
                ),
              ),
            ),

            if (_showFitToast)
              Positioned(
                top: 60,
                left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _videoFit == BoxFit.cover ? 'Fill' : 'Fit',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Buffering indicator ────────────────────────────────────────────────────────
class _BufferingIndicator extends StatelessWidget {
  const _BufferingIndicator();

  @override
  Widget build(BuildContext context) => Column(
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

// ── Error overlay ──────────────────────────────────────────────────────────────
class _ErrorOverlay extends StatelessWidget {
  final String?       message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  final VoidCallback? onExternal;
  const _ErrorOverlay({this.message, this.onRetry, this.onBack, this.onExternal});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 52),
              const SizedBox(height: 12),
              const Text('Stream Error',
                  style: TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w700)),
              if (message != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(message!,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                      textAlign: TextAlign.center),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 10, runSpacing: 8,
                alignment: WrapAlignment.center,
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
                  if (onExternal != null)
                    ElevatedButton.icon(
                      onPressed: onExternal,
                      icon:  const Icon(Icons.open_in_new_rounded),
                      label: const Text('مشغل خارجي'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
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

// ── Controls overlay ───────────────────────────────────────────────────────────
class _ControlsOverlay extends StatelessWidget {
  final Channel?   channel;
  final bool       isPlaying;
  final bool       isVod;
  final Duration   position;
  final Duration   duration;
  final bool       hasSubtitles;
  final bool       subtitleActive;
  final VoidCallback onBack, onPlayPause, onFavorite, onExternal, onSubtitleTap;
  final VoidCallback onSkipBack, onSkipFwd;
  final void Function(Duration) onSeekStart, onSeekUpdate, onSeekEnd;
  final String Function(Duration) fmtTime;

  const _ControlsOverlay({
    required this.channel,
    required this.isPlaying,
    required this.isVod,
    required this.position,
    required this.duration,
    required this.hasSubtitles,
    required this.subtitleActive,
    required this.onBack,
    required this.onPlayPause,
    required this.onFavorite,
    required this.onExternal,
    required this.onSubtitleTap,
    required this.onSkipBack,
    required this.onSkipFwd,
    required this.onSeekStart,
    required this.onSeekUpdate,
    required this.onSeekEnd,
    required this.fmtTime,
  });

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          // top gradient
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
          // bottom gradient
          if (isVod)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

          // top bar
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
                        color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
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

          // center: skip-back / play-pause / skip-fwd
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isVod) ...[
                  _SkipButton(icon: Icons.replay_10_rounded, onTap: onSkipBack),
                  const SizedBox(width: 24),
                ],
                GestureDetector(
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
                      color: Colors.white, size: 36,
                    ),
                  ),
                ),
                if (isVod) ...[
                  const SizedBox(width: 24),
                  _SkipButton(icon: Icons.forward_10_rounded, onTap: onSkipFwd),
                ],
              ],
            ),
          ),

          // seek bar + subtitle button (VOD only)
          if (isVod)
            Positioned(
              bottom: 8, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Seek bar row
                    Row(
                      children: [
                        Text(fmtTime(position),
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight:        3,
                              thumbShape:         const RoundSliderThumbShape(enabledThumbRadius: 7),
                              overlayShape:       const RoundSliderOverlayShape(overlayRadius: 14),
                              activeTrackColor:   AppColors.primary,
                              inactiveTrackColor: Colors.white24,
                              thumbColor:         Colors.white,
                              overlayColor:       Colors.white24,
                            ),
                            child: Slider(
                              value: position.inMilliseconds.toDouble()
                                  .clamp(0, duration.inMilliseconds.toDouble()),
                              max: duration.inMilliseconds.toDouble(),
                              onChangeStart: (v) => onSeekStart(Duration(milliseconds: v.toInt())),
                              onChanged:     (v) => onSeekUpdate(Duration(milliseconds: v.toInt())),
                              onChangeEnd:   (v) => onSeekEnd(Duration(milliseconds: v.toInt())),
                            ),
                          ),
                        ),
                        Text(fmtTime(duration),
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    // Subtitle button row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: onSubtitleTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: subtitleActive
                                  ? AppColors.primary.withOpacity(0.85)
                                  : Colors.white12,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: subtitleActive
                                    ? AppColors.primary
                                    : Colors.white24,
                              ),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                subtitleActive
                                    ? Icons.subtitles_rounded
                                    : Icons.subtitles_off_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              const Text('الترجمة',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
}

// ── Skip button ────────────────────────────────────────────────────────────────
class _SkipButton extends StatelessWidget {
  final IconData    icon;
  final VoidCallback onTap;
  const _SkipButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.4),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      );
}

// ── Subtitle tile ──────────────────────────────────────────────────────────────
class _SubtitleTile extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final bool         isSelected;
  final VoidCallback onTap;
  const _SubtitleTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Icon(icon,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            size: 20),
        title: Text(label,
            style: TextStyle(
                color: isSelected ? AppColors.primaryLight : Colors.white,
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400)),
        trailing: isSelected
            ? const Icon(Icons.check_rounded,
                color: AppColors.primary, size: 18)
            : null,
      );
}

// ── Resume dialog ─────────────────────────────────────────────────────────────
class _ResumeDialog extends StatelessWidget {
  final Duration             savedPosition;
  final String Function(Duration) fmtTime;
  final VoidCallback         onResume;
  final VoidCallback         onFresh;
  const _ResumeDialog({
    required this.savedPosition,
    required this.fmtTime,
    required this.onResume,
    required this.onFresh,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('استئناف',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('استئناف التشغيل من الموضع الأخير',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          Text(fmtTime(savedPosition),
              style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onResume,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('استئناف',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('البدء من جديد',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
}

// ── Language name helper ───────────────────────────────────────────────────────
String _langName(SubtitleTrack t) {
  // Prioritise language code → Arabic name; only use track title as last resort.
  const map = {
    'ar':  'العربية',    'ara': 'العربية',
    'en':  'الإنجليزية','eng': 'الإنجليزية',
    'fr':  'الفرنسية',  'fre': 'الفرنسية',  'fra': 'الفرنسية',
    'es':  'الإسبانية', 'spa': 'الإسبانية',
    'de':  'الألمانية', 'ger': 'الألمانية', 'deu': 'الألمانية',
    'pt':  'البرتغالية','por': 'البرتغالية',
    'it':  'الإيطالية', 'ita': 'الإيطالية',
    'ru':  'الروسية',   'rus': 'الروسية',
    'zh':  'الصينية',   'zho': 'الصينية',   'chi': 'الصينية',
    'ja':  'اليابانية', 'jpn': 'اليابانية',
    'ko':  'الكورية',   'kor': 'الكورية',
    'tr':  'التركية',   'tur': 'التركية',
    'nl':  'الهولندية', 'nld': 'الهولندية',
    'pl':  'البولندية', 'pol': 'البولندية',
    'sv':  'السويدية',  'swe': 'السويدية',
    'da':  'الدنماركية','dan': 'الدنماركية',
    'no':  'النرويجية', 'nor': 'النرويجية',
    'fi':  'الفنلندية', 'fin': 'الفنلندية',
    'he':  'العبرية',   'heb': 'العبرية',
    'fa':  'الفارسية',  'per': 'الفارسية',  'fas': 'الفارسية',
    'hi':  'الهندية',   'hin': 'الهندية',
    'ur':  'الأردية',   'urd': 'الأردية',
    'el':  'اليونانية', 'ell': 'اليونانية',
    'cs':  'التشيكية',  'ces': 'التشيكية',  'cze': 'التشيكية',
    'hu':  'الهنغارية', 'hun': 'الهنغارية',
    'ro':  'الرومانية', 'ron': 'الرومانية', 'rum': 'الرومانية',
    'sk':  'السلوفاكية','slk': 'السلوفاكية','slo': 'السلوفاكية',
    'bg':  'البلغارية', 'bul': 'البلغارية',
    'hr':  'الكرواتية', 'hrv': 'الكرواتية',
    'sr':  'الصربية',   'srp': 'الصربية',
    'uk':  'الأوكرانية','ukr': 'الأوكرانية',
    'th':  'التايلاندية','tha': 'التايلاندية',
    'vi':  'الفيتنامية','vie': 'الفيتنامية',
    'id':  'الإندونيسية','ind': 'الإندونيسية',
    'ms':  'الملايوية', 'msa': 'الملايوية', 'may': 'الملايوية',
    'ca':  'الكتالانية','cat': 'الكتالانية',
    'lt':  'الليتوانية','lit': 'الليتوانية',
    'lv':  'اللاتفية',  'lav': 'اللاتفية',
    'et':  'الإستونية', 'est': 'الإستونية',
    'sl':  'السلوفينية','slv': 'السلوفينية',
    'sq':  'الألبانية', 'alb': 'الألبانية', 'sqi': 'الألبانية',
    'mk':  'المقدونية', 'mac': 'المقدونية', 'mkd': 'المقدونية',
    'az':  'الأذربيجانية','aze': 'الأذربيجانية',
    'ka':  'الجورجية',  'geo': 'الجورجية',  'kat': 'الجورجية',
    'be':  'البيلاروسية','bel': 'البيلاروسية',
    'is':  'الآيسلندية','ice': 'الآيسلندية','isl': 'الآيسلندية',
    'mt':  'المالطية',  'mlt': 'المالطية',
    'af':  'الأفريكانية','afr': 'الأفريكانية',
    'sw':  'السواحيلية','swa': 'السواحيلية',
    'am':  'الأمهرية',  'amh': 'الأمهرية',
    'bn':  'البنغالية', 'ben': 'البنغالية',
    'ta':  'التاميلية', 'tam': 'التاميلية',
    'te':  'التيلوغو',  'tel': 'التيلوغو',
    'ml':  'المالايالامية','mal': 'المالايالامية',
    'kn':  'الكانادية', 'kan': 'الكانادية',
    'mr':  'الماراثية', 'mar': 'الماراثية',
    'gu':  'الغوجاراتية','guj': 'الغوجاراتية',
    'pa':  'البنجابية', 'pan': 'البنجابية',
    'my':  'البورمية',  'bur': 'البورمية',  'mya': 'البورمية',
    'km':  'الخميرية',  'khm': 'الخميرية',
    'lo':  'اللاوية',   'lao': 'اللاوية',
    'si':  'السنهالية', 'sin': 'السنهالية',
    'ne':  'النيبالية', 'nep': 'النيبالية',
    'mn':  'المنغولية', 'mon': 'المنغولية',
    'tl':  'الفلبينية', 'fil': 'الفلبينية',
    'und': 'غير محدد',
  };

  final lang = t.language?.toLowerCase().trim() ?? '';
  const plainLangTitles = {
    'english', 'arabic', 'french', 'spanish', 'german', 'italian', 'russian',
    'chinese', 'japanese', 'korean', 'turkish', 'portuguese', 'dutch', 'polish',
    'swedish', 'danish', 'norwegian', 'finnish', 'hebrew', 'persian', 'hindi',
    'urdu', 'greek', 'czech', 'hungarian', 'romanian', 'slovak', 'bulgarian',
    'croatian', 'serbian', 'ukrainian', 'thai', 'vietnamese', 'indonesian',
    'malay', 'catalan', 'lithuanian', 'latvian', 'estonian', 'slovenian',
    'albanian', 'macedonian', 'azerbaijani', 'georgian', 'belarusian',
    'icelandic', 'maltese', 'afrikaans', 'swahili', 'amharic', 'bengali',
    'tamil', 'telugu', 'malayalam', 'kannada', 'marathi', 'gujarati',
    'punjabi', 'burmese', 'khmer', 'lao', 'sinhala', 'nepali', 'mongolian',
    'filipino', 'tagalog',
  };

  final title = t.title?.trim();
  if (map.containsKey(lang)) {
    final arabicName = map[lang]!;
    // If title has extra info beyond plain language name, append it
    if (title != null && title.isNotEmpty &&
        !plainLangTitles.contains(title.toLowerCase()) &&
        title.toLowerCase() != lang) {
      return '$arabicName · $title';
    }
    return arabicName;
  }

  // Language code unknown — fall back to title
  if (title != null && title.isNotEmpty) return title;
  if (lang.isNotEmpty) return lang.toUpperCase();
  return 'ترجمة ${t.id}';
}
