import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tempcam/src/core/constants/app_strings.dart';
import 'package:tempcam/src/features/paywall/presentation/premium_paywall_screen.dart';
import 'package:tempcam/src/shared/models/app_settings.dart';
import 'package:tempcam/src/shared/state/app_controller.dart';
import 'package:tempcam/src/shared/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _authenticateThen(
    BuildContext context,
    AppController controller,
    Future<void> Function() action,
  ) async {
    final ok = await controller.unlockForSensitiveAccess();
    if (!context.mounted || !ok) {
      return;
    }
    await action();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
            children: [
              _SettingsHero(
                isActive: controller.hasPremiumAccess,
                hasStoreManagedTrialOffer: controller.hasStoreManagedTrialOffer,
                priceLabel: controller.yearlyPriceLabel,
                accessUntil: controller.premiumAccessExpiresAt,
                onManageAccess: () => PremiumPaywallScreen.show(context),
                onPanicExit: controller.panicExit,
              ),
              const SizedBox(height: 24),
              const _SettingsSectionLabel('Capture Defaults'),
              const SizedBox(height: 12),
              _PremiumCard(
                child: Column(
                  children: [
                    _ActionRow(
                      icon: Icons.schedule_rounded,
                      title: 'Default Self-Destruct Timer',
                      subtitle: 'Choose how long new captures stay available by default.',
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<AppTimerOption>(
                          value: controller.settings.defaultTimer,
                          dropdownColor: AppTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(18),
                          items: AppTimerOption.settingsDefaults
                              .map(
                                (option) => DropdownMenuItem<AppTimerOption>(
                                  value: option,
                                  child: Text(
                                    option.label,
                                    style: const TextStyle(color: AppTheme.secondary),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (option) async {
                            if (option == null) {
                              return;
                            }
                            await _authenticateThen(
                              context,
                              controller,
                              () => controller.updateDefaultTimer(option),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Color(0x33414755), height: 1),
                    const SizedBox(height: 14),
                    _ActionRow(
                      icon: Icons.notifications_active_rounded,
                      title: 'Expiry Notifications',
                      subtitle: 'Get warned before temporary media disappears.',
                      trailing: Switch.adaptive(
                        value: controller.settings.notificationsEnabled,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (value) async {
                          await _authenticateThen(
                            context,
                            controller,
                            () => controller.updateNotifications(value),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SettingsSectionLabel('Security'),
              const SizedBox(height: 12),
              _PremiumCard(
                child: Column(
                  children: [
                    _ActionRow(
                      icon: Icons.fingerprint_rounded,
                      title: 'Biometric Lock',
                      subtitle: controller.biometricAvailable
                          ? 'Protect app entry and sensitive actions with biometrics.'
                          : 'Biometric protection is unavailable on this device.',
                      trailing: Switch.adaptive(
                        value: controller.settings.biometricLockEnabled,
                        activeThumbColor: AppTheme.primary,
                        onChanged: controller.biometricAvailable
                            ? (value) async {
                                await _authenticateThen(
                                  context,
                                  controller,
                                  () => controller.updateBiometricLock(value),
                                );
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Color(0x33414755), height: 1),
                    const SizedBox(height: 14),
                    const _SecurityNote(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SettingsSectionLabel('Why People Use TempCam'),
              const SizedBox(height: 12),
              const _PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FeatureBullet(
                      title: 'Temporary by default',
                      description: 'Photos and videos auto-delete unless you decide to keep them forever.',
                    ),
                    SizedBox(height: 12),
                    _FeatureBullet(
                      title: 'Private by design',
                      description: 'Temporary captures stay inside TempCam instead of appearing in the main gallery.',
                    ),
                    SizedBox(height: 12),
                    _FeatureBullet(
                      title: 'Fast under pressure',
                      description: 'Open, capture, review, and protect sensitive moments with fewer steps.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Column(
                  children: [
                    Text(
                      '${AppStrings.appName} v1.0.0',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'LOCAL • TEMPORARY • PROTECTED',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({
    required this.isActive,
    required this.hasStoreManagedTrialOffer,
    required this.priceLabel,
    required this.accessUntil,
    required this.onManageAccess,
    required this.onPanicExit,
  });

  final bool isActive;
  final bool hasStoreManagedTrialOffer;
  final String priceLabel;
  final DateTime? accessUntil;
  final VoidCallback onManageAccess;
  final Future<void> Function() onPanicExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF21262F), Color(0xFF111316)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    color: AppTheme.primary,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.secondary.withValues(alpha: 0.94)
                          : AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      hasStoreManagedTrialOffer && !isActive
                          ? 'FREE TRIAL'
                          : isActive
                              ? 'ACTIVE'
                              : 'REQUIRED',
                      style: TextStyle(
                        color: hasStoreManagedTrialOffer || isActive
                            ? const Color(0xFF3C2F00)
                            : AppTheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      foregroundColor: AppTheme.onSurface,
                    ),
                    onPressed: () => onPanicExit(),
                    icon: const Icon(Icons.visibility_off_rounded),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            isActive
                ? 'Your access is live.'
                : hasStoreManagedTrialOffer
                    ? 'Start with 15 days free.'
                    : 'Yearly access powers TempCam.',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.06,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isActive
                ? accessUntil == null
                    ? 'Your current subscription is active through the store.'
                    : 'Access is recorded until ${_formatDate(accessUntil!)}.'
                : hasStoreManagedTrialOffer
                    ? 'Google Play or the App Store can start a secure 15-day free trial for eligible accounts before yearly billing begins.'
                    : 'A $priceLabel yearly subscription keeps TempCam private, temporary, and fully unlocked.',
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: const Color(0xFF003061),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            onPressed: onManageAccess,
            child: Text(
              hasStoreManagedTrialOffer && !isActive
                  ? 'View Yearly Plan'
                  : isActive
                      ? 'Manage Access'
                      : 'View Access Options',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 10,
        letterSpacing: 2,
        fontWeight: FontWeight.w800,
        color: AppTheme.onSurfaceVariant,
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailing,
      ],
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified_user_rounded, color: AppTheme.secondary),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Temp media stays local to your device until you explicitly keep it forever. Sensitive actions stay protected behind biometric confirmation when enabled.',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
