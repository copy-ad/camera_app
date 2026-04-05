import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TempCamBrandMark extends StatelessWidget {
  const TempCamBrandMark({
    super.key,
    this.size = 148,
    this.showGlow = true,
  });

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    final outerShadow = showGlow
        ? <BoxShadow>[
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.18),
              blurRadius: size * 0.18,
              spreadRadius: size * 0.015,
              offset: Offset(0, size * 0.04),
            ),
            BoxShadow(
              color: AppTheme.secondary.withValues(alpha: 0.08),
              blurRadius: size * 0.22,
              spreadRadius: size * 0.01,
              offset: Offset(0, size * 0.06),
            ),
          ]
        : const <BoxShadow>[];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1D2C42),
                  Color(0xFF101724),
                  Color(0xFF070A11),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: outerShadow,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.35),
                  radius: 1.08,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.16),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.16),
                  ],
                  stops: const [0, 0.42, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: size * 0.18,
            left: size * 0.18,
            child: Transform.rotate(
              angle: -0.12,
              child: _DocumentBadge(size: size * 0.28),
            ),
          ),
          Center(
            child: SizedBox(
              width: size * 0.56,
              height: size * 0.56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.square(
                    dimension: size * 0.56,
                    child: CircularProgressIndicator(
                      value: 0.82,
                      strokeWidth: size * 0.028,
                      backgroundColor: AppTheme.surfaceHighest,
                      color: AppTheme.secondary,
                    ),
                  ),
                  Container(
                    width: size * 0.44,
                    height: size * 0.44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.28),
                        width: size * 0.02,
                      ),
                      color: const Color(0xFF121B28),
                    ),
                  ),
                  Container(
                    width: size * 0.31,
                    height: size * 0.31,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFDCEBFF),
                          AppTheme.primary.withValues(alpha: 0.88),
                          const Color(0xFF203145),
                        ],
                        stops: const [0, 0.48, 1],
                      ),
                    ),
                  ),
                  Container(
                    width: size * 0.16,
                    height: size * 0.16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0A1420),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: size * 0.22,
            right: size * 0.16,
            child: _OrbitalDot(
              diameter: size * 0.11,
              color: AppTheme.secondary,
            ),
          ),
          Positioned(
            right: size * 0.14,
            bottom: size * 0.14,
            child: _ShieldBadge(size: size * 0.24),
          ),
        ],
      ),
    );
  }
}

class _DocumentBadge extends StatelessWidget {
  const _DocumentBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 1.08,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F3),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(size * 0.22),
                  bottomLeft: Radius.circular(size * 0.18),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size * 0.18,
              vertical: size * 0.2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: size * 0.46,
                  height: size * 0.08,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: size * 0.1),
                Container(
                  width: size * 0.58,
                  height: size * 0.08,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB7C2D4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: size * 0.08),
                Container(
                  width: size * 0.4,
                  height: size * 0.08,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB7C2D4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShieldBadge extends StatelessWidget {
  const _ShieldBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF101B2A),
        borderRadius: BorderRadius.circular(size * 0.36),
        border: Border.all(
          color: AppTheme.secondary.withValues(alpha: 0.36),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.14),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Icon(
        Icons.shield_rounded,
        size: size * 0.56,
        color: AppTheme.secondary,
      ),
    );
  }
}

class _OrbitalDot extends StatelessWidget {
  const _OrbitalDot({
    required this.diameter,
    required this.color,
  });

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: diameter * 0.9,
            spreadRadius: diameter * 0.04,
          ),
        ],
      ),
    );
  }
}
