import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF061019);
  static const Color surface = Color(0xFF07131E);
  static const Color surfaceLowest = Color(0xFF050C14);
  static const Color surfaceLow = Color(0xFF0D1723);
  static const Color surfaceContainer = Color(0xFF122131);
  static const Color surfaceHigh = Color(0xFF1A2D42);
  static const Color surfaceHighest = Color(0xFF27405B);
  static const Color primary = Color(0xFF8AD8FF);
  static const Color primaryContainer = Color(0xFF4DA6FF);
  static const Color secondary = Color(0xFFFFD56A);
  static const Color tertiary = Color(0xFFFFB7D9);
  static const Color onSurface = Color(0xFFF3F7FC);
  static const Color onSurfaceVariant = Color(0xFFAAC1D5);
  static const Color outline = Color(0xFF7E97AC);
  static const Color outlineVariant = Color(0xFF2D465C);
  static const Color error = Color(0xFFFFB0B2);
  static const Color success = Color(0xFF7CE6B9);
  static const Color glassStroke = Color(0x2FFFFFFF);
  static const Color glassFill = Color(0x66233A52);
  static const double radiusS = 16;
  static const double radiusM = 24;
  static const double radiusL = 32;
  static const Duration motionFast = Duration(milliseconds: 180);
  static const Duration motionMedium = Duration(milliseconds: 280);
  static const Curve emphasizedCurve = Curves.easeOutCubic;

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
        onPrimary: Color(0xFF04253A),
        onSecondary: Color(0xFF3C2F00),
        onSurface: onSurface,
      ),
      splashFactory: InkRipple.splashFactory,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceContainer.withValues(alpha: 0.92),
        contentTextStyle: const TextStyle(
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF04253A),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          foregroundColor: onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        thickness: 1,
      ),
      fontFamily: 'Inter',
    );
  }

  static List<BoxShadow> get softGlow => const [
        BoxShadow(
          color: Color(0x404DA6FF),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get deepShadow => const [
        BoxShadow(
          color: Color(0x4D02070D),
          blurRadius: 34,
          offset: Offset(0, 22),
        ),
      ];

  static BoxDecoration glassDecoration({
    double radius = radiusM,
    Color? fill,
    Color? stroke,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: fill ?? glassFill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: stroke ?? glassStroke,
      ),
      boxShadow: shadows ?? deepShadow,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.02),
        ],
      ),
    );
  }
}
