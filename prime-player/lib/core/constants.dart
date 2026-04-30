import 'package:flutter/material.dart';

class AppColors {
  static const Color background   = Color(0xFF0A0A23);
  static const Color surface      = Color(0xFF14143A);
  static const Color surfaceLight = Color(0xFF1E1E50);
  static const Color primary      = Color(0xFF4F46E5);  // Prime purple
  static const Color primaryLight = Color(0xFF6D63FF);
  static const Color accent       = Color(0xFFF59E0B);  // Prime gold
  static const Color accentLight  = Color(0xFFFDE68A);
  static const Color textPrimary  = Color(0xFFE2E8F0);
  static const Color textSecondary= Color(0xFF94A3B8);
  static const Color textMuted    = Color(0xFF475569);
  static const Color success      = Color(0xFF10B981);
  static const Color error        = Color(0xFFEF4444);
  static const Color border       = Color(0xFF2D2D6B);
}

class AppStrings {
  static const String appName     = 'Prime Player';
  static const String appTagline  = 'Lightning-fast IPTV';
  static const String whatsApp    = '+212666686732';
  static const String website     = 'primeiptvplus.com';
}

/// MPV / libmpv tuning for minimum channel-open latency
class PlayerConfig {
  /// Initial buffer in bytes — small = faster first frame
  static const int bufferSize = 16 * 1024 * 1024; // 16 MB

  /// libmpv property map applied at player init
  static const Map<String, String> mpvOptions = {
    // Hardware decoding — GPU path, fastest decode
    'hwdec': 'auto-safe',
    // Network
    'network-timeout': '3',          // fail fast, 3 s
    'stream-buffer-size': '4096',    // 4 KB read-ahead (low latency start)
    // Cache — just enough for smooth play without delaying start
    'cache': 'yes',
    'cache-secs': '8',
    'demuxer-max-bytes': '8MiB',
    'demuxer-readahead-secs': '2',
    // Decoder threads
    'vd-lavc-threads': '0',          // 0 = auto (use all CPU cores)
    // Sync
    'video-sync': 'audio',
    // Disable unused features that add latency
    'interpolation': 'no',
    'deband': 'no',
    'dither-depth': 'no',
  };

  /// How many ms to wait before showing loading spinner (avoid flicker)
  static const int spinnerDelayMs = 400;

  /// DNS pre-resolve + TCP pre-connect timeout
  static const int preConnectTimeoutMs = 2000;
}
