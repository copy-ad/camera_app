import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/camera/presentation/camera_screen.dart';
import '../../features/photos/presentation/photos_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  DateTime? _lastBackPressAt;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        final screens = [
          const PhotosScreen(),
          const CameraScreen(),
          const SettingsScreen(),
        ];
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            _handleBackPress(controller);
          },
          child: Scaffold(
            body: IndexedStack(
              index: controller.currentTabIndex,
              children: screens,
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.background.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 24,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavIcon(
                      selected: controller.currentTabIndex == 0,
                      icon: Icons.grid_view_rounded,
                      onTap: () => controller.setTab(0),
                    ),
                    _CenterLens(
                      selected: controller.currentTabIndex == 1,
                      onTap: () => controller.setTab(1),
                    ),
                    _NavIcon(
                      selected: controller.currentTabIndex == 2,
                      icon: Icons.settings_rounded,
                      onTap: () => controller.setTab(2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleBackPress(AppController controller) {
    if (controller.currentTabIndex != 1) {
      controller.setTab(1);
      return;
    }

    final now = DateTime.now();
    final shouldExit = _lastBackPressAt != null &&
        now.difference(_lastBackPressAt!) <= const Duration(seconds: 2);

    if (shouldExit) {
      Navigator.of(context).maybePop();
      return;
    }

    _lastBackPressAt = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Press back again to exit TempCam')),
      );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.selected, required this.icon, required this.onTap});

  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Icon(
          icon,
          color: selected ? AppTheme.primary : AppTheme.surfaceHighest,
        ),
      ),
    );
  }
}

class _CenterLens extends StatelessWidget {
  const _CenterLens({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppTheme.primary : AppTheme.surfaceLow,
          boxShadow: selected ? AppTheme.softGlow : const [],
        ),
        child: Icon(
          Icons.lens_rounded,
          color: selected ? AppTheme.background : AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
