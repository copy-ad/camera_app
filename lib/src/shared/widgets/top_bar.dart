import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.centerSubtitle,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final String? centerSubtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              SizedBox(width: 28, child: leading),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: AppTheme.primary,
                      ),
                    ),
                    if (centerSubtitle != null)
                      Text(centerSubtitle!,
                          style: const TextStyle(
                              fontSize: 10,
                              letterSpacing: 2,
                              color: AppTheme.onSurfaceVariant)),
                  ],
                ),
              ),
              SizedBox(width: 28, child: trailing),
            ],
          ),
        ),
      ),
    );
  }
}
