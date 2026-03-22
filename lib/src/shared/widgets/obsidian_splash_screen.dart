import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../theme/app_theme.dart';

class ObsidianSplashScreen extends StatelessWidget {
  const ObsidianSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.background,
              gradient: RadialGradient(center: Alignment.topCenter, radius: 1.1, colors: [Color(0x182A5DB5), AppTheme.background]),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceLowest,
                      border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.28)),
                      boxShadow: AppTheme.softGlow,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2))),
                        ),
                        const Icon(Icons.lens, color: AppTheme.primary, size: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Text(AppStrings.appName, style: TextStyle(fontFamily: 'Manrope', fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 7, color: AppTheme.primary)),
                  const SizedBox(height: 14),
                  const Text('PRIVATE • TEMPORARY • LOCAL', style: TextStyle(fontSize: 12, letterSpacing: 4, color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 48),
                  Container(
                    width: 180,
                    height: 3,
                    decoration: BoxDecoration(color: AppTheme.surfaceHighest, borderRadius: BorderRadius.circular(999)),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 72,
                      height: 3,
                      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(999), boxShadow: AppTheme.softGlow),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: AppTheme.surfaceLow, borderRadius: BorderRadius.circular(999)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 10, height: 10, child: DecoratedBox(decoration: BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle))),
                        SizedBox(width: 8),
                        Text('Secure Session Initialized', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600, color: AppTheme.secondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('END-TO-END LOCAL ENCRYPTED', style: TextStyle(fontSize: 10, letterSpacing: 3, color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


