import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppTheme.radiusS,
    this.color = AppTheme.glassFill,
    this.blur = 20,
    this.margin,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final double blur;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final panel = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: AppTheme.glassDecoration(
            radius: radius,
            fill: color,
            stroke: Colors.white.withValues(alpha: 0.08),
          ),
          child: child,
        ),
      ),
    );

    if (margin == null) {
      return panel;
    }

    return Padding(
      padding: margin!,
      child: panel,
    );
  }
}
