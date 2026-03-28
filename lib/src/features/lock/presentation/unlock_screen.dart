import 'package:flutter/material.dart';
import 'package:tempcam/src/localization/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/glass_panel.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({
    super.key,
    required this.canUseBiometric,
    required this.isBusy,
    required this.onUnlock,
  });

  final bool canUseBiometric;
  final bool isBusy;
  final Future<bool> Function() onUnlock;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  bool _didAttemptAutoUnlock = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didAttemptAutoUnlock || !widget.canUseBiometric) {
      return;
    }
    _didAttemptAutoUnlock = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.isBusy) {
        return;
      }
      widget.onUnlock();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.background,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A1A), AppTheme.background],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassPanel(
                padding: const EdgeInsets.all(28),
                radius: AppTheme.radiusM,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceHighest,
                        boxShadow: AppTheme.softGlow,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: AppTheme.primary,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.tr('Vault Locked'),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.canUseBiometric
                          ? l10n.tr(
                              'Authenticating now. If the prompt does not appear, tap below to unlock TempCam.',
                            )
                          : l10n.tr(
                              'Biometrics are unavailable on this device. Continue without biometric lock from settings.',
                            ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.background,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed:
                            widget.isBusy ? null : () => widget.onUnlock(),
                        child: Text(
                          widget.isBusy
                              ? l10n.tr('Unlocking...')
                              : l10n.tr('Unlock TempCam'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
