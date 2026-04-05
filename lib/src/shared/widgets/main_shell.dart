import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tempcam/src/localization/app_localizations.dart';

import '../../features/camera/presentation/camera_screen.dart';
import '../../features/photos/presentation/photos_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'glass_panel.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  DateTime? _lastBackPressAt;
  late final List<Widget> _screens = const [
    PhotosScreen(),
    CameraScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
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
              children: _screens,
            ),
            bottomNavigationBar: controller.currentTabIndex == 1
                ? null
                : SafeArea(
                    top: false,
                    child: GlassPanel(
                      margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      radius: AppTheme.radiusL,
                      color: AppTheme.surfaceContainer.withValues(alpha: 0.56),
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
      SystemNavigator.pop();
      return;
    }

    _lastBackPressAt = now;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.tr('Press back again to exit TempCam'))),
      );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon(
      {required this.selected, required this.icon, required this.onTap});

  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.motionFast,
        curve: AppTheme.emphasizedCurve,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.16)
              : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: selected ? AppTheme.primary : AppTheme.onSurfaceVariant,
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
        duration: AppTheme.motionMedium,
        curve: AppTheme.emphasizedCurve,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary,
                    AppTheme.primaryContainer,
                  ],
                )
              : null,
          color: selected ? null : AppTheme.surfaceLow,
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.06),
          ),
          boxShadow: selected
              ? [
                  ...AppTheme.softGlow,
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : AppTheme.deepShadow,
        ),
        child: Icon(
          Icons.lens_rounded,
          color: selected ? AppTheme.background : AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
