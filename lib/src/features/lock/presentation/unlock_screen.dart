import 'package:flutter/material.dart';
import 'package:tempcam/src/localization/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_backdrop.dart';
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
      body: AppBackdrop(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassPanel(
              padding: const EdgeInsets.all(28),
              radius: AppTheme.radiusL,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
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
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF05263D),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.tr('Vault Locked'),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 30,
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
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassDecoration(
                      radius: 24,
                      fill: Colors.white.withValues(alpha: 0.04),
                      shadows: const [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppTheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.tr('Protected Preview'),
                            style: const TextStyle(
                              color: AppTheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.isBusy ? null : () => widget.onUnlock(),
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
      ),
    );
  }
}
