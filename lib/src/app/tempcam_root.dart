import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tempcam/src/features/lock/presentation/unlock_screen.dart';
import 'package:tempcam/src/features/paywall/presentation/premium_paywall_screen.dart';
import 'package:tempcam/src/shared/state/app_controller.dart';
import 'package:tempcam/src/shared/widgets/main_shell.dart';
import 'package:tempcam/src/shared/widgets/obsidian_splash_screen.dart';

class TempCamRoot extends StatelessWidget {
  const TempCamRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        if (!controller.didFinishBootstrap) {
          return const ObsidianSplashScreen();
        }
        if (!controller.hasPremiumAccess) {
          return const PremiumPaywallScreen(requiredForAccess: true);
        }
        if (controller.isLocked) {
          return UnlockScreen(
            canUseBiometric: controller.biometricAvailable,
            isBusy: controller.isUnlocking,
            onUnlock: controller.unlockApp,
          );
        }
        return const MainShell();
      },
    );
  }
}
