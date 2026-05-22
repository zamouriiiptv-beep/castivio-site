import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/constants.dart';

class TopSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String                hint;
  final ValueChanged<String>  onChanged;

  const TopSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<TopSearchBar> createState() => _TopSearchBarState();
}

class _TopSearchBarState extends State<TopSearchBar>
    with SingleTickerProviderStateMixin {
  final SpeechToText _stt        = SpeechToText();
  bool               _sttReady   = false;
  bool               _listening  = false;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  Timer?             _listenTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _pulseCtrl.reverse();
        else if (s == AnimationStatus.dismissed && _listening) _pulseCtrl.forward();
      });
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final ok = await _stt.initialize(
      onError: (_) {
        if (mounted) setState(() => _listening = false);
        _pulseCtrl.stop();
        _pulseCtrl.reset();
      },
    );
    if (mounted) setState(() => _sttReady = ok);
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _stt.stop();
      _listenTimer?.cancel();
      _pulseCtrl.stop();
      _pulseCtrl.reset();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (!_sttReady) return;

    setState(() => _listening = true);
    _pulseCtrl.forward();

    // Auto-stop after 20 s
    _listenTimer = Timer(const Duration(seconds: 20), () async {
      await _stt.stop();
      _pulseCtrl.stop();
      _pulseCtrl.reset();
      if (mounted) setState(() => _listening = false);
    });

    await _stt.listen(
      onResult: (result) {
        final q = result.recognizedWords;
        widget.controller.text = q;
        widget.onChanged(q);
        if (result.finalResult) {
          _listenTimer?.cancel();
          _pulseCtrl.stop();
          _pulseCtrl.reset();
          if (mounted) setState(() => _listening = false);
        }
      },
      listenFor:   const Duration(seconds: 20),
      pauseFor:    const Duration(seconds: 3),
      cancelOnError: true,
      partialResults: true,
    );
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
  }

  @override
  void dispose() {
    _listenTimer?.cancel();
    _pulseCtrl.dispose();
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _listening ? AppColors.primary : AppColors.border,
          width: _listening ? 1.5 : 1,
        ),
        boxShadow: _listening
            ? [BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 8,
              )]
            : [],
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search_rounded,
              color: AppColors.textMuted, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged:  widget.onChanged,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                border:         InputBorder.none,
                isDense:        true,
                contentPadding: EdgeInsets.zero,
                hintText:       _listening ? 'أستمع…' : widget.hint,
                hintStyle: TextStyle(
                  color: _listening
                      ? AppColors.primary.withOpacity(0.8)
                      : AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          // Clear button
          if (hasText)
            GestureDetector(
              onTap: _clear,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 15),
              ),
            ),
          // Voice button
          if (_sttReady)
            GestureDetector(
              onTap: _toggleListen,
              child: Container(
                width: 36, height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: const Border(
                    left: BorderSide(color: AppColors.border),
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight:    Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  color: _listening
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.transparent,
                ),
                child: ScaleTransition(
                  scale: _pulseAnim,
                  child: Icon(
                    _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: _listening ? AppColors.primary : AppColors.textMuted,
                    size: 17,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
