import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

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

  static const List<_TourPageData> _pages = [
    _TourPageData(
      badge: 'WELCOME',
      title: 'TempCam keeps sensitive captures temporary.',
      description:
          'Take private photos and videos inside TempCam, keep them out of the main gallery, and let them disappear unless you keep them forever.',
      icon: Icons.shield_moon_rounded,
    ),
    _TourPageData(
      badge: 'CAMERA',
      title: 'Capture quickly with the private camera.',
      description:
          'Use photo or video mode, tap to focus, pinch to zoom, control flash, and review the private preview before you apply the timer.',
      icon: Icons.camera_alt_rounded,
    ),
    _TourPageData(
      badge: 'TIMERS',
      title: 'Every item gets a self-destruct timer.',
      description:
          'Choose a timer after capture or import. If you skip it, TempCam uses your default timer from Settings.',
      icon: Icons.schedule_rounded,
    ),
    _TourPageData(
      badge: 'VAULT',
      title: 'The vault keeps temp media private first.',
      description:
          'Browse photos and videos in the private vault, filter by type, import existing media into TempCam, extend timers, or delete items when you need to.',
      icon: Icons.lock_rounded,
    ),
    _TourPageData(
      badge: 'SECURITY',
      title: 'Biometrics, quick relock, and Panic Exit stay ready.',
      description:
          'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and Panic Exit for faster privacy under pressure.',
      icon: Icons.fingerprint_rounded,
    ),
    _TourPageData(
      badge: 'SETTINGS',
      title: 'Settings controls reminders, stealth mode, and access.',
      description:
          'Manage expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.',
      icon: Icons.settings_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _pageIndex == _pages.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFF090B0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'APP TOUR',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _pageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _TourCard(page: page);
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: List.generate(
                  _pages.length,
                  (index) => Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index == _pages.length - 1 ? 0 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: index == _pageIndex
                            ? AppTheme.primary
                            : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
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
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _goBack,
                        child: const Text('Back'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: const Color(0xFF003061),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: isLastPage ? _finish : _goNext,
                      child: Text(
                        isLastPage ? 'Get Started' : 'Next',
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

  void _finish() {
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF202631), Color(0xFF0E1117)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, color: AppTheme.primary, size: 34),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              page.badge,
              style: const TextStyle(
                color: Color(0xFF3C2F00),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Icon(page.icon, color: AppTheme.secondary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'You can skip this now and reopen it any time from Settings.',
                    style: TextStyle(
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
