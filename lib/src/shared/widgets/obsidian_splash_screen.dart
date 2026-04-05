import 'package:flutter/material.dart';
import 'package:tempcam/src/localization/app_localizations.dart';

import '../../core/constants/app_strings.dart';
import '../theme/app_theme.dart';
import 'app_backdrop.dart';
import 'glass_panel.dart';
import 'tempcam_brand_mark.dart';

class ObsidianSplashScreen extends StatefulWidget {
  const ObsidianSplashScreen({super.key});

  @override
  State<ObsidianSplashScreen> createState() => _ObsidianSplashScreenState();
}

class _ObsidianSplashScreenState extends State<ObsidianSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = 0.34 + (_controller.value * 0.5);
          final markScale = 0.97 + (_controller.value * 0.05);
          final cardShift = (_controller.value - 0.5) * 12;

          return AppBackdrop(
            safeTop: true,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                child: Column(
                  children: [
                    const Spacer(),
                    Transform.translate(
                      offset: Offset(0, cardShift * -0.25),
                      child: Transform.scale(
                        scale: markScale,
                        child: const TempCamBrandMark(size: 156),
                      ),
                    ),
                    const SizedBox(height: 28),
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
                    const SizedBox(height: 10),
                    const Text(
                      AppStrings.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 3.2,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Transform.translate(
                      offset: Offset(0, cardShift),
                      child: GlassPanel(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        radius: 30,
                        color: AppTheme.surfaceContainer.withValues(alpha: 0.5),
                        child: Column(
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                _SplashChip(
                                  icon: Icons.lock_clock_rounded,
                                  label: l10n.tr('Private Vault'),
                                ),
                                _SplashChip(
                                  icon: Icons.document_scanner_rounded,
                                  label: l10n.tr('Live Scan'),
                                ),
                                _SplashChip(
                                  icon: Icons.shield_rounded,
                                  label: l10n.tr('Security'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.tr('Preparing secure vault experience'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.tr('Secure session initializing'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: 210,
                      height: 6,
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
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.secondary,
                                  AppTheme.primaryContainer,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLow,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppTheme.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.tr('LOCAL PRIVATE STORAGE'),
                            style: const TextStyle(
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SplashChip extends StatelessWidget {
  const _SplashChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
