import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tempcam/src/localization/app_localizations.dart';

import '../../../shared/state/app_controller.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_backdrop.dart';
import '../../../shared/widgets/glass_panel.dart';

class AppTourScreen extends StatefulWidget {
  const AppTourScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const AppTourScreen(),
      ),
    );
  }

  @override
  State<AppTourScreen> createState() => _AppTourScreenState();
}

class _AppTourScreenState extends State<AppTourScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = <_TourPageData>[
      _TourPageData(
        badge: l10n.tr('CAMERA'),
        title: l10n.tr('Capture private photos and videos fast.'),
        description: l10n.tr(
          'Use photo or video mode, tap to focus, pinch to zoom, control flash, and keep sensitive captures out of the main gallery from the start.',
        ),
        icon: Icons.camera_alt_rounded,
      ),
      _TourPageData(
        badge: l10n.tr('SCAN'),
        title: l10n.tr('Document scan actions happen before saving.'),
        description: l10n.tr(
          'If TempCam detects a phone number or address in a photo, you can call, add a contact, open maps, or tap Temp Save before choosing the timer.',
        ),
        icon: Icons.document_scanner_rounded,
      ),
      _TourPageData(
        badge: l10n.tr('VAULT'),
        title: l10n.tr('The vault keeps temporary media organized.'),
        description: l10n.tr(
          'Browse private photos and videos, see expiring items, open detected details again, and move photos or videos from the main gallery into TempCam when you need temporary private storage.',
        ),
        icon: Icons.lock_rounded,
      ),
      _TourPageData(
        badge: l10n.tr('SECURITY'),
        title: l10n.tr('Privacy protection stays ready under pressure.'),
        description: l10n.tr(
          'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and tap the eye icon for a fast app exit when you need privacy right away.',
        ),
        icon: Icons.fingerprint_rounded,
      ),
      _TourPageData(
        badge: l10n.tr('TIMERS'),
        title: l10n.tr('Temp Save leads into the self-destruct timer.'),
        description: l10n.tr(
          'After capture or import, choose how long each item should stay in TempCam. If you skip it, TempCam uses your default timer from Settings.',
        ),
        icon: Icons.schedule_rounded,
      ),
      _TourPageData(
        badge: l10n.tr('SETTINGS'),
        title: l10n.tr('Settings controls language, reminders, and access.'),
        description: l10n.tr(
          'Manage app language, expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.',
        ),
        icon: Icons.settings_rounded,
      ),
      _TourPageData(
        badge: l10n.tr('WELCOME'),
        title: l10n.tr('TempCam keeps sensitive captures temporary.'),
        description: l10n.tr(
          'Everything is designed to keep private photos, videos, and detected document details local first until they expire or you choose to keep them.',
        ),
        icon: Icons.shield_moon_rounded,
      ),
    ];
    final isLastPage = _pageIndex == pages.length - 1;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _closeTour();
      },
      child: Scaffold(
        body: AppBackdrop(
          safeTop: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Text(
                        l10n.tr('APP TOUR'),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _closeTour,
                      child: Text(l10n.tr('Skip')),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _pageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      return _TourCard(page: page);
                    },
                  ),
                ),
                const SizedBox(height: 18),
                GlassPanel(
                  radius: 26,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  color: AppTheme.surfaceContainer.withValues(alpha: 0.48),
                  child: Row(
                    children: List.generate(
                      pages.length,
                      (index) => Expanded(
                        child: AnimatedContainer(
                          duration: AppTheme.motionFast,
                          curve: AppTheme.emphasizedCurve,
                          height: 5,
                          margin: EdgeInsets.only(
                            right: index == pages.length - 1 ? 0 : 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: index == _pageIndex
                                ? const LinearGradient(
                                    colors: [
                                      AppTheme.primary,
                                      AppTheme.primaryContainer,
                                    ],
                                  )
                                : null,
                            color: index == _pageIndex
                                ? null
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (_pageIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _goBack,
                          child: Text(l10n.tr('Back')),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: isLastPage ? _closeTour : _goNext,
                        child: Text(
                          isLastPage ? l10n.tr('Get Started') : l10n.tr('Next'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _goBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _closeTour() async {
    final controller = context.read<AppController>();
    await controller.markTourCompleted();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({required this.page});

  final _TourPageData page;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) => GlassPanel(
          radius: 34,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          color: AppTheme.surfaceContainer.withValues(alpha: 0.44),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: AppTheme.motionMedium,
                      curve: AppTheme.emphasizedCurve,
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primary,
                            AppTheme.primaryContainer,
                          ],
                        ),
                        boxShadow: AppTheme.softGlow,
                      ),
                      child: Icon(
                        page.icon,
                        color: const Color(0xFF05263D),
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      radius: 999,
                      color: AppTheme.secondary.withValues(alpha: 0.24),
                      child: Text(
                        page.badge,
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      page.title,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.06,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      page.description,
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 16,
                        height: 1.55,
                      ),
                    ),
                    const Spacer(),
                    GlassPanel(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      radius: 24,
                      color: Colors.white.withValues(alpha: 0.035),
                      child: Row(
                        children: [
                          Icon(page.icon, color: AppTheme.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.l10n.tr(
                                'You can skip this now and reopen it any time from Settings.',
                              ),
                              style: const TextStyle(
                                color: AppTheme.onSurface,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TourPageData {
  const _TourPageData({
    required this.badge,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String badge;
  final String title;
  final String description;
  final IconData icon;
}
