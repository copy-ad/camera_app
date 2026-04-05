import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:tempcam/src/features/lock/presentation/unlock_screen.dart';
import 'package:tempcam/src/features/onboarding/presentation/app_tour_screen.dart';
import 'package:tempcam/src/localization/app_localizations.dart';
import 'package:tempcam/src/shared/state/app_controller.dart';
import 'package:tempcam/src/shared/theme/app_theme.dart';
import 'package:tempcam/src/shared/widgets/main_shell.dart';
import 'package:tempcam/src/shared/widgets/obsidian_splash_screen.dart';

class TempCamRoot extends StatefulWidget {
  const TempCamRoot({super.key});

  @override
  State<TempCamRoot> createState() => _TempCamRootState();
}

class _TempCamRootState extends State<TempCamRoot> {
  final QuickActions _quickActions = const QuickActions();
  bool _isShowingTour = false;
  bool _quickActionsReady = false;
  String? _quickActionsLocaleTag;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureQuickActions(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        final localeTag =
            AppLocalizations.localeTag(Localizations.localeOf(context));
        if (_quickActionsReady && _quickActionsLocaleTag != localeTag) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _configureQuickActions(context);
          });
        }

        if (controller.didFinishBootstrap &&
            controller.shouldShowAppTour &&
            !_isShowingTour &&
            !controller.isLocked) {
          _isShowingTour = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) {
              return;
            }
            await AppTourScreen.show(context);
            _isShowingTour = false;
          });
        }

        late final Widget child;
        if (!controller.didFinishBootstrap) {
          child = const ObsidianSplashScreen();
        } else if (controller.isLocked) {
          child = UnlockScreen(
            canUseBiometric: controller.biometricAvailable,
            isBusy: controller.isUnlocking,
            onUnlock: controller.unlockApp,
          );
        } else {
          child = const MainShell();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (controller.isPreviewShieldActive) const _RecentsPrivacyShield(),
          ],
        );
      },
    );
  }

  Future<void> _configureQuickActions(BuildContext context) async {
    if (!mounted) {
      return;
    }
    final l10n = context.l10n;
    final localeTag =
        AppLocalizations.localeTag(Localizations.localeOf(context));
    try {
      if (!_quickActionsReady) {
        await _quickActions.initialize((shortcutType) {
          if (!mounted) {
            return;
          }
          final controller = context.read<AppController>();
          switch (shortcutType) {
            case 'open_camera':
              controller.openCameraQuickAction();
              return;
            case 'open_vault':
              controller.openVaultQuickAction();
              return;
            default:
              return;
          }
        });
      }
      await _quickActions.setShortcutItems(<ShortcutItem>[
        ShortcutItem(
          type: 'open_camera',
          localizedTitle: l10n.tr('Open Camera'),
          icon: 'icon_camera_shortcut',
        ),
        ShortcutItem(
          type: 'open_vault',
          localizedTitle: l10n.tr('Open Vault'),
          icon: 'icon_vault_shortcut',
        ),
      ]);
      _quickActionsReady = true;
      _quickActionsLocaleTag = localeTag;
    } catch (_) {}
  }
}

class _RecentsPrivacyShield extends StatelessWidget {
  const _RecentsPrivacyShield();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0A0A0A),
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.black.withValues(alpha: 0.82)),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shield_moon_rounded,
                    color: AppTheme.primary,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TEMPCAM',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.tr('Protected Preview'),
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
