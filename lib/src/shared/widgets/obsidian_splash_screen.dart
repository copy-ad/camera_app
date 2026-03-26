import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../theme/app_theme.dart';

class ObsidianSplashScreen extends StatefulWidget {
  const ObsidianSplashScreen({super.key});

  @override
  State<ObsidianSplashScreen> createState() => _ObsidianSplashScreenState();
}

class _ObsidianSplashScreenState extends State<ObsidianSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = 0.36 + (_controller.value * 0.44);
          final ringScale = 0.94 + (_controller.value * 0.08);
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.15,
                    colors: [Color(0x1F2A5DB5), AppTheme.background],
                  ),
                ),
              ),
              Positioned(
                top: -80,
                left: -30,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                right: -40,
                bottom: 120,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.secondary.withValues(alpha: 0.05),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    children: [
                      const Spacer(),
                      Transform.scale(
                        scale: ringScale,
                        child: Container(
                          width: 138,
                          height: 138,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceLowest,
                            border: Border.all(
                              color: AppTheme.outlineVariant.withValues(alpha: 0.28),
                            ),
                            boxShadow: AppTheme.softGlow,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                margin: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primary.withValues(alpha: 0.22),
                                  ),
                                ),
                              ),
                              Container(
                                width: 78,
                                height: 78,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primary.withValues(alpha: 0.08),
                                ),
                              ),
                              const Icon(Icons.lens_rounded, color: AppTheme.primary, size: 52),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 7,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'PRIVATE • TEMPORARY • LOCAL',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 4,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 44),
                      Container(
                        width: 188,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: AppTheme.softGlow,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Preparing secure vault experience',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLow,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Secure session initializing',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'END-TO-END LOCAL ENCRYPTED',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
