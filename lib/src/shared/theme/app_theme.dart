import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF131313);
  static const Color surface = Color(0xFF131313);
  static const Color surfaceLowest = Color(0xFF0E0E0E);
  static const Color surfaceLow = Color(0xFF1C1B1B);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color surfaceHighest = Color(0xFF353534);
  static const Color primary = Color(0xFFA7C8FF);
  static const Color primaryContainer = Color(0xFF3291FF);
  static const Color secondary = Color(0xFFE9C349);
  static const Color tertiary = Color(0xFFFFB595);
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFC1C6D7);
  static const Color outline = Color(0xFF8B90A0);
  static const Color outlineVariant = Color(0xFF414755);
  static const Color error = Color(0xFFFFB4AB);
  static const double radiusS = 16;
  static const double radiusM = 24;
  static const double radiusL = 32;

  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        error: error,
        onPrimary: Color(0xFF003061),
        onSecondary: Color(0xFF3C2F00),
        onSurface: onSurface,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      fontFamily: 'Inter',
    );
  }

  static List<BoxShadow> get softGlow => const [
        BoxShadow(
          color: Color(0x403291FF),
          blurRadius: 28,
          offset: Offset(0, 10),
        ),
      ];
}
