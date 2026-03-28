import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:tempcam/src/features/lock/presentation/unlock_screen.dart';
import 'package:tempcam/src/features/onboarding/presentation/app_tour_screen.dart';
import 'package:tempcam/src/features/paywall/presentation/premium_paywall_screen.dart';
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
  bool _isShowingTrialDialog = false;
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
        final l10n = context.l10n;
        final localeTag =
            AppLocalizations.localeTag(Localizations.localeOf(context));
        if (_quickActionsReady && _quickActionsLocaleTag != localeTag) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _configureQuickActions(context);
          });
        }
        if (controller.didFinishBootstrap &&
            controller.shouldShowTrialStartedNotice &&
            !_isShowingTrialDialog) {
          _isShowingTrialDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) {
              return;
            }
            final navigator = Navigator.of(context);
            final appController = context.read<AppController>();
            await showDialog<void>(
              context: navigator.context,
              barrierDismissible: false,
              builder: (_) => _TrialStartedDialog(
                hasStoreManagedTrialOffer: controller.hasStoreManagedTrialOffer,
                priceLabel: controller.yearlyPriceLabel,
                l10n: l10n,
              ),
            );
            if (!mounted) {
              return;
            }
            await appController.markTrialStartedNoticeSeen();
            _isShowingTrialDialog = false;
          });
        }

        if (controller.didFinishBootstrap &&
            controller.shouldShowAppTour &&
            !_isShowingTrialDialog &&
            !_isShowingTour &&
            !controller.isLocked) {
          _isShowingTour = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) {
              return;
            }
            final appController = context.read<AppController>();
            await AppTourScreen.show(context);
            if (!mounted) {
              return;
            }
            await appController.markTourCompleted();
            _isShowingTour = false;
          });
        }

        late final Widget child;
        if (!controller.didFinishBootstrap) {
          child = const ObsidianSplashScreen();
        } else if (!controller.hasPremiumAccess) {
          child = const PremiumPaywallScreen(requiredForAccess: true);
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

class _TrialStartedDialog extends StatelessWidget {
  const _TrialStartedDialog({
    required this.hasStoreManagedTrialOffer,
    required this.priceLabel,
    required this.l10n,
  });

  final bool hasStoreManagedTrialOffer;
  final String priceLabel;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.tr('15 DAYS FREE'),
                    style: const TextStyle(
                      color: Color(0xFF342700),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              l10n.tr('Start with a secure free trial.'),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hasStoreManagedTrialOffer
                  ? l10n.tr(
                      'Google Play will start your 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.',
                    )
                  : l10n.tr(
                      'If your Google Play account is eligible, the store will offer a 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.',
                    ),
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.tr(
                  'After the trial ends, Google Play continues the subscription at {price} per year unless the user cancels in time.',
                  {'price': priceLabel},
                ),
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: const Color(0xFF003061),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.tr('Continue To Access'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
