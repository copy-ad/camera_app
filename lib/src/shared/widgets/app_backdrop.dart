import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.safeTop = false,
    this.safeBottom = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool safeTop;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (safeTop || safeBottom) {
      content = SafeArea(
        top: safeTop,
        bottom: safeBottom,
        child: content,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF07131E),
                Color(0xFF081927),
                Color(0xFF050D15),
              ],
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -40,
          child: _GlowOrb(
            size: 260,
            color: AppTheme.primary.withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          top: 140,
          right: -70,
          child: _GlowOrb(
            size: 220,
            color: AppTheme.tertiary.withValues(alpha: 0.12),
          ),
        ),
        Positioned(
          bottom: -100,
          left: 10,
          child: _GlowOrb(
            size: 240,
            color: AppTheme.secondary.withValues(alpha: 0.12),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GridAccentPainter(),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        content,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 56, sigmaY: 56),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _GridAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.025);

    const spacing = 42.0;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
