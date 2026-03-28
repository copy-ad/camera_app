import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tempcam/src/core/constants/app_strings.dart';
import 'package:tempcam/src/features/onboarding/presentation/app_tour_screen.dart';
import 'package:tempcam/src/features/paywall/presentation/premium_paywall_screen.dart';
import 'package:tempcam/src/localization/app_localizations.dart';
import 'package:tempcam/src/shared/models/app_settings.dart';
import 'package:tempcam/src/shared/models/vault_history_entry.dart';
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
        final l10n = context.l10n;
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 92),
              children: [
                _SettingsHero(
                  isActive: controller.hasPremiumAccess,
                  hasStoreManagedTrialOffer:
                      controller.hasStoreManagedTrialOffer,
                  priceLabel: controller.yearlyPriceLabel,
                  accessUntil: controller.premiumAccessExpiresAt,
                  onManageAccess: () => PremiumPaywallScreen.show(context),
                  onPanicExit: controller.panicExit,
                ),
                const SizedBox(height: 24),
                _SettingsSectionLabel(l10n.tr('Capture Defaults')),
                const SizedBox(height: 12),
                _PremiumCard(
                  child: Column(
                    children: [
                      _ActionRow(
                        icon: Icons.language_rounded,
                        title: l10n.tr('Language'),
                        subtitle: l10n.tr(
                          'Choose the app language. System Default follows your phone language.',
                        ),
                        stackTrailingOnNarrow: true,
                        trailingMinWidth: 132,
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: controller.settings.localeTag,
                            isDense: true,
                            dropdownColor: AppTheme.surfaceHigh,
                            borderRadius: BorderRadius.circular(18),
                            items: <DropdownMenuItem<String?>>[
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  l10n.tr('System Default'),
                                  style: const TextStyle(
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ),
                              ...AppLocalizations.supportedLanguages.map(
                                (option) => DropdownMenuItem<String?>(
                                  value: option.tag,
                                  child: Text(
                                    option.nativeName,
                                    style: const TextStyle(
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (tag) =>
                                controller.updateLanguageTag(tag),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Color(0x33414755), height: 1),
                      const SizedBox(height: 14),
                      _ActionRow(
                        icon: Icons.schedule_rounded,
                        title: l10n.tr('Default Self-Destruct Timer'),
                        subtitle: l10n.tr(
                          'Choose how long new captures stay available by default.',
                        ),
                        stackTrailingOnNarrow: true,
                        trailingMinWidth: 112,
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<AppTimerOption>(
                            value: controller.settings.defaultTimer,
                            isDense: true,
                            dropdownColor: AppTheme.surfaceHigh,
                            borderRadius: BorderRadius.circular(18),
                            items: AppTimerOption.settingsDefaults
                                .map(
                                  (option) => DropdownMenuItem<AppTimerOption>(
                                    value: option,
                                    child: Text(
                                      l10n.timerLabel(option),
                                      style: const TextStyle(
                                        color: AppTheme.secondary,
                                      ),
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
                        title: l10n.tr('Expiry Notifications'),
                        subtitle: l10n.tr(
                          'Get warned before temporary media disappears.',
                        ),
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
                      const SizedBox(height: 14),
                      const Divider(color: Color(0x33414755), height: 1),
                      const SizedBox(height: 14),
                      _ActionRow(
                        icon: Icons.notifications_none_rounded,
                        title: l10n.tr('Stealth Notifications'),
                        subtitle: l10n.tr(
                          'Hide photo and video wording in reminders for a quieter lock-screen presence.',
                        ),
                        trailing: Switch.adaptive(
                          value:
                              controller.settings.stealthNotificationsEnabled,
                          activeThumbColor: AppTheme.primary,
                          onChanged: controller.settings.notificationsEnabled
                              ? (value) async {
                                  await _authenticateThen(
                                    context,
                                    controller,
                                    () => controller.updateStealthNotifications(
                                      value,
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SettingsSectionLabel(l10n.tr('Security')),
                const SizedBox(height: 12),
                _PremiumCard(
                  child: Column(
                    children: [
                      _ActionRow(
                        icon: Icons.fingerprint_rounded,
                        title: l10n.tr('Biometric Lock'),
                        subtitle: controller.biometricAvailable
                            ? l10n.tr(
                                'Protect app entry and sensitive actions with biometrics.',
                              )
                            : l10n.tr(
                                'Biometric protection is unavailable on this device.',
                              ),
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
                      _ActionRow(
                        icon: Icons.lock_clock_rounded,
                        title: l10n.tr('Session Privacy Mode'),
                        subtitle: controller.settings.biometricLockEnabled
                            ? l10n.tr(
                                'Lock TempCam immediately whenever the app loses focus.',
                              )
                            : l10n.tr(
                                'Enable Biometric Lock first to use instant session relocking.',
                              ),
                        trailing: Switch.adaptive(
                          value: controller.settings.sessionPrivacyModeEnabled,
                          activeThumbColor: AppTheme.primary,
                          onChanged: controller.biometricAvailable &&
                                  controller.settings.biometricLockEnabled
                              ? (value) async {
                                  await _authenticateThen(
                                    context,
                                    controller,
                                    () => controller.updateSessionPrivacyMode(
                                      value,
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Color(0x33414755), height: 1),
                      const SizedBox(height: 14),
                      _ActionRow(
                        icon: Icons.timer_off_rounded,
                        title: l10n.tr('Quick Lock Timeout'),
                        subtitle: controller.settings.sessionPrivacyModeEnabled
                            ? l10n.tr(
                                'Session Privacy Mode locks instantly, so timeout is bypassed.',
                              )
                            : l10n.tr(
                                'Choose how long TempCam can stay in the background before it asks for biometrics again.',
                              ),
                        stackTrailingOnNarrow: true,
                        trailingMinWidth: 112,
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<QuickLockTimeoutOption>(
                            value: controller.settings.quickLockTimeout,
                            isDense: true,
                            dropdownColor: AppTheme.surfaceHigh,
                            borderRadius: BorderRadius.circular(18),
                            items: QuickLockTimeoutOption.valuesForSettings
                                .map(
                                  (option) =>
                                      DropdownMenuItem<QuickLockTimeoutOption>(
                                    value: option,
                                    child: Text(
                                      l10n.quickLockTimeoutLabel(option),
                                      style: const TextStyle(
                                        color: AppTheme.secondary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: controller.settings.biometricLockEnabled
                                ? (option) async {
                                    if (option == null) {
                                      return;
                                    }
                                    await _authenticateThen(
                                      context,
                                      controller,
                                      () => controller.updateQuickLockTimeout(
                                        option,
                                      ),
                                    );
                                  }
                                : null,
                          ),
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
                _SettingsSectionLabel(l10n.tr('Help')),
                const SizedBox(height: 12),
                _PremiumCard(
                  child: Column(
                    children: [
                      _ActionRow(
                        icon: Icons.explore_rounded,
                        title: l10n.tr('Replay App Tour'),
                        subtitle: l10n.tr(
                          'Walk through camera, timers, vault, security, and settings again any time.',
                        ),
                        trailing: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.surfaceContainer,
                            foregroundColor: AppTheme.onSurface,
                          ),
                          onPressed: () async {
                            await controller.reopenTour();
                            if (!context.mounted) {
                              return;
                            }
                            await AppTourScreen.show(context);
                            if (!context.mounted) {
                              return;
                            }
                            await controller.markTourCompleted();
                          },
                          child: Text(
                            l10n.tr('Start'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SettingsSectionLabel(l10n.tr('Trusted Vault History')),
                const SizedBox(height: 12),
                _PremiumCard(
                  child: controller.vaultHistory.isEmpty
                      ? const _HistoryEmptyState()
                      : Column(
                          children: controller.vaultHistory
                              .take(6)
                              .map((entry) => _HistoryRow(entry: entry))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 24),
                _SettingsSectionLabel(l10n.tr('Why People Use TempCam')),
                const SizedBox(height: 12),
                _PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FeatureBullet(
                        title: l10n.tr('Temporary by default'),
                        description: l10n.tr(
                          'Photos and videos auto-delete unless you decide to keep them forever.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FeatureBullet(
                        title: l10n.tr('Private by design'),
                        description: l10n.tr(
                          'Temporary captures stay inside TempCam instead of appearing in the main gallery.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FeatureBullet(
                        title: l10n.tr('Fast under pressure'),
                        description: l10n.tr(
                          'Open, capture, review, and protect sensitive moments with fewer steps.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _SettingsFooter(),
              ],
            ),
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
    final l10n = context.l10n;
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.secondary.withValues(alpha: 0.94)
                          : AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      hasStoreManagedTrialOffer && !isActive
                          ? l10n.tr('FREE TRIAL')
                          : isActive
                              ? l10n.tr('ACTIVE')
                              : l10n.tr('REQUIRED'),
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
                ? l10n.tr('Your access is live.')
                : hasStoreManagedTrialOffer
                    ? l10n.tr('Start with 15 days free.')
                    : l10n.tr('Yearly access powers TempCam.'),
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
                    ? l10n.tr(
                        'Your current subscription is active through the store.')
                    : l10n.tr(
                        'Access is recorded until {date}.',
                        {'date': l10n.formatDate(accessUntil!)},
                      )
                : hasStoreManagedTrialOffer
                    ? l10n.tr(
                        'Google Play or the App Store can start a secure 15-day free trial for eligible accounts before yearly billing begins.',
                      )
                    : l10n.tr(
                        'A {price} yearly subscription keeps TempCam private, temporary, and fully unlocked.',
                        {'price': priceLabel},
                      ),
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
                  ? l10n.tr('View Yearly Plan')
                  : isActive
                      ? l10n.tr('Manage Access')
                      : l10n.tr('View Access Options'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
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
    this.stackTrailingOnNarrow = false,
    this.trailingMinWidth,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool stackTrailingOnNarrow;
  final double? trailingMinWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStackTrailing =
            stackTrailingOnNarrow && constraints.maxWidth < 340;
        final trailingWidget = trailingMinWidth == null
            ? trailing
            : ConstrainedBox(
                constraints: BoxConstraints(minWidth: trailingMinWidth!),
                child: trailing,
              );

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
              child: shouldStackTrailing
                  ? Column(
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
                        const SizedBox(height: 12),
                        trailingWidget,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: trailingWidget,
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
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
          child: const Icon(
            Icons.verified_user_rounded,
            color: AppTheme.secondary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            context.l10n.tr(
              'Temp media stays local to your device until you explicitly keep it forever. Recent-app previews are shielded, and sensitive actions stay protected behind biometric confirmation when enabled.',
            ),
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsFooter extends StatelessWidget {
  const _SettingsFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          const Text(
            '${AppStrings.appName} v${AppStrings.versionName}',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.tr('LOCAL | TEMPORARY | PROTECTED'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.history_toggle_off_rounded,
          color: AppTheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.l10n.tr(
              'Keep Forever exports, manual deletions, and auto-deletions will appear here as a local trust log.',
            ),
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final VaultHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final icon = switch (entry.eventType) {
      VaultHistoryEventType.exported => Icons.upload_rounded,
      VaultHistoryEventType.deleted => Icons.delete_outline_rounded,
      VaultHistoryEventType.autoDeleted => Icons.auto_delete_rounded,
    };
    final accent = switch (entry.eventType) {
      VaultHistoryEventType.exported => AppTheme.primary,
      VaultHistoryEventType.deleted => AppTheme.error,
      VaultHistoryEventType.autoDeleted => AppTheme.secondary,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.details,
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.formatDateTime(entry.occurredAt),
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
