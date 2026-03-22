import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tempcam/src/core/constants/app_strings.dart';
import 'package:tempcam/src/features/paywall/presentation/premium_paywall_screen.dart';
import 'package:tempcam/src/shared/models/app_settings.dart';
import 'package:tempcam/src/shared/state/app_controller.dart';
import 'package:tempcam/src/shared/theme/app_theme.dart';
import 'package:tempcam/src/shared/widgets/top_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
            children: [
              const TopBar(
                title: AppStrings.appName,
                leading: Icon(Icons.grid_view_rounded, color: AppTheme.surfaceHighest, size: 22),
                trailing: Icon(Icons.flash_on_rounded, color: AppTheme.surfaceHighest, size: 22),
              ),
              const SizedBox(height: 12),
              const _SectionLabel('Subscription'),
              const SizedBox(height: 12),
              _SubscriptionCard(
                isActive: controller.hasPremiumAccess,
                priceLabel: controller.yearlyPriceLabel,
                accessUntil: controller.premiumAccessExpiresAt,
                onTap: () => PremiumPaywallScreen.show(context),
              ),
              const SizedBox(height: 26),
              const _SectionLabel('General'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: AppTheme.surfaceLow, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Default Expiry Timer'),
                      subtitle: const Text('Choose how long new photos persist after capture', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<AppTimerOption>(
                          value: controller.settings.defaultTimer,
                          dropdownColor: AppTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(18),
                          items: AppTimerOption.settingsDefaults.map((option) => DropdownMenuItem(value: option, child: Text(option.label, style: const TextStyle(color: AppTheme.secondary)))).toList(),
                          onChanged: (option) {
                            if (option != null) {
                              controller.updateDefaultTimer(option);
                            }
                          },
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 18, endIndent: 18, color: Color(0x33414755)),
                    SwitchListTile.adaptive(
                      value: controller.settings.notificationsEnabled,
                      onChanged: controller.updateNotifications,
                      activeThumbColor: AppTheme.primary,
                      title: const Text('Notifications'),
                      subtitle: const Text('Prepared for future reminders before expiry', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                    ),
                    const Divider(height: 1, indent: 18, endIndent: 18, color: Color(0x33414755)),
                    SwitchListTile.adaptive(
                      value: controller.settings.biometricLockEnabled,
                      onChanged: controller.biometricAvailable ? controller.updateBiometricLock : null,
                      activeThumbColor: AppTheme.primary,
                      title: const Text('Biometric App Lock'),
                      subtitle: Text(
                        controller.biometricAvailable ? 'Protect launch, resume, and sensitive detail access' : 'Unavailable on this device',
                        style: const TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const _SectionLabel('Privacy'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.surfaceLow, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.14))),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 22, backgroundColor: Color(0x22E9C349), child: Icon(Icons.verified_user_rounded, color: AppTheme.secondary)),
                    SizedBox(width: 14),
                    Expanded(child: Text('Photos are stored locally on your device only. No cloud, no sharing, total privacy.', style: TextStyle(color: AppTheme.onSurfaceVariant, height: 1.45))),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              const Column(
                children: [
                  Text('TEMPCAM v1.0.0', style: TextStyle(fontSize: 10, letterSpacing: 2, color: AppTheme.onSurfaceVariant)),
                  SizedBox(height: 4),
                  Text('END-TO-END LOCAL ENCRYPTED', style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: const TextStyle(fontFamily: 'Manrope', fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppTheme.onSurfaceVariant));
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.onTap, required this.isActive, required this.priceLabel, required this.accessUntil});

  final VoidCallback onTap;
  final bool isActive;
  final String priceLabel;
  final DateTime? accessUntil;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppTheme.surfaceLow, borderRadius: BorderRadius.circular(28)),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              top: -12,
              child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withValues(alpha: 0.08))),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isActive ? 'Yearly Access Active' : 'Yearly Access Required', style: const TextStyle(fontFamily: 'Manrope', fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                const SizedBox(height: 8),
                SizedBox(
                  width: 250,
                  child: Text(
                    isActive
                        ? accessUntil == null
                            ? 'Your current access is active through the store.'
                            : 'Access recorded until ${_formatDate(accessUntil!)}. Open to restore or review billing actions.'
                        : 'This app now requires an active $priceLabel yearly store subscription to open and use TempCam.',
                    style: const TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: const Color(0xFF003061)),
                  onPressed: onTap,
                  child: Text(isActive ? 'Manage Access' : 'View Access Options'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}
