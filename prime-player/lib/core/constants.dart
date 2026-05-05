import 'package:flutter/material.dart';

class AppColors {
  // Deep dark — better than Hot Player
  static const Color background    = Color(0xFF0A0E1A);
  static const Color surface       = Color(0xFF111827);
  static const Color surfaceLight  = Color(0xFF1C2333);
  static const Color sidebar       = Color(0xFF080C16);

  // Prime brand — purple→blue gradient (matches logo)
  static const Color primary       = Color(0xFF7C3AED);
  static const Color primaryLight  = Color(0xFFA78BFA);
  static const Color secondary     = Color(0xFF2563EB);

  // Channel number badge
  static const Color channelBadge  = Color(0xFF1D4ED8);

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted     = Color(0xFF4B5563);

  // States
  static const Color success       = Color(0xFF10B981);
  static const Color error         = Color(0xFFEF4444);
  static const Color warning       = Color(0xFFF59E0B);
  static const Color border        = Color(0xFF1F2937);

  // Legacy aliases
  static const Color accent        = Color(0xFF7C3AED);
  static const Color accentLight   = Color(0xFFA78BFA);
}

// Gradient shorthand
const kPrimeGradient = LinearGradient(
  colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kPrimeGradientH = LinearGradient(
  colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
);

class AppStrings {
  static const String appName    = 'Prime Player';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'IPTV · MOVIES · SERIES';
  static const String website    = 'primeiptvplus.com';
  static const String whatsApp   = '+212666686732';
}
