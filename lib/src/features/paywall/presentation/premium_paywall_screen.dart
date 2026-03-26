import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/premium_constants.dart';
import '../../../shared/state/app_controller.dart';
import '../../../shared/theme/app_theme.dart';

class PremiumPaywallScreen extends StatelessWidget {
  const PremiumPaywallScreen({
    super.key,
    this.requiredForAccess = false,
  });

  final bool requiredForAccess;

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PremiumPaywallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        const bool isTestAccess = PremiumConstants.paymentsTemporarilyDisabled;
        final bool isActive = controller.hasPremiumAccess;
        final bool isBusy =
            controller.isPurchasePending || controller.isStoreLoading;
        final String priceLine = controller.yearlySubscriptionProduct == null
            ? PremiumConstants.fallbackYearlyPlanLabel
            : '${controller.yearlyPriceLabel} / year';
        final String title = isTestAccess
            ? 'Payments Disabled Temporarily'
            : requiredForAccess
                ? 'Yearly Access Required'
                : 'Manage TempCam Access';
        final String description = isTestAccess
            ? 'This build bypasses subscriptions so you can test TempCam on your phone before store upload.'
            : requiredForAccess
                ? 'TempCam is now usage-gated by a single yearly store subscription. Purchase or restore access to open the app.'
                : 'Your subscription is handled directly by the App Store or Google Play with one yearly plan.';
        final String badgeText = isTestAccess
            ? 'PAYMENT OFF'
            : isActive
                ? 'ACTIVE'
                : 'YEARLY ACCESS';
        final String buttonText = isTestAccess
            ? 'Payment Disabled For Testing'
            : isActive
                ? 'Access Active'
                : isBusy
                    ? 'Connecting To Store...'
                    : 'Buy 1 Year For ${controller.yearlyPriceLabel}';
        const String footerText = isTestAccess
            ? 'Disable TEMPCAM_DISABLE_PAYMENTS before uploading to the store.'
            : 'Auto-renewing yearly subscription. Cancel anytime in Google Play or App Store subscriptions.';
        final String pricingCaption = isTestAccess
            ? 'Store billing is currently bypassed by a temporary app-wide test switch.'
            : isActive
                ? 'Your yearly subscription is active.'
                : controller.yearlySubscriptionProduct == null
                    ? 'Fallback price shown until the store catalog loads.'
                    : 'Directly billed and renewed by the platform store.';

        return Scaffold(
          body: Stack(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.surface, AppTheme.surfaceLowest],
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              if (!requiredForAccess)
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close_rounded, color: AppTheme.primary),
                                )
                              else
                                const SizedBox(width: 48),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  badgeText,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: AppTheme.surfaceHighest,
                            child: Icon(Icons.verified_user_rounded, color: AppTheme.secondary),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppTheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 22),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 380;
                              return GridView.count(
                                shrinkWrap: true,
                                crossAxisCount: compact ? 1 : 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: compact ? 2.2 : 0.88,
                                physics: const NeverScrollableScrollPhysics(),
                                children: const [
                                  _FeatureCard(
                                    Icons.lock_clock_rounded,
                                    AppTheme.primary,
                                    'Whole App Access',
                                    'Without an active yearly subscription, the camera vault stays locked at launch.',
                                  ),
                                  _FeatureCard(
                                    Icons.calendar_month_rounded,
                                    AppTheme.secondary,
                                    'Yearly Billing',
                                    'One auto-renewing yearly subscription managed directly by Google Play or the App Store.',
                                  ),
                                  _FeatureCard(
                                    Icons.fingerprint_rounded,
                                    AppTheme.primary,
                                    'Biometric Re-Entry',
                                    'After access is active, Face ID or fingerprint can protect future app launches.',
                                  ),
                                  _FeatureCard(
                                    Icons.restore_rounded,
                                    AppTheme.secondary,
                                    'Restore Support',
                                    'Recover your yearly access from the App Store or Google Play on reinstall.',
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          if (controller.billingStatusMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                controller.billingStatusMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppTheme.onSurfaceVariant, height: 1.4),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _PricingCard(
                            title: 'Annual Access',
                            subtitle: priceLine,
                            caption: pricingCaption,
                            selected: true,
                            badge: isTestAccess ? 'Testing' : 'Only Plan',
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: const Color(0xFF002A55),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              ),
                              onPressed: isTestAccess || isActive || isBusy
                                  ? null
                                  : () async {
                                      final message = await context.read<AppController>().purchasePremiumSubscription();
                                      if (message != null && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(message)),
                                        );
                                      }
                                    },
                              child: Text(
                                buttonText,
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            footerText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.5,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          if (!isTestAccess) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 4,
                              alignment: WrapAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: isBusy
                                      ? null
                                      : () async {
                                          final message = await context.read<AppController>().restorePremiumPurchases();
                                          if (message != null && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(message)),
                                            );
                                          }
                                        },
                                  child: const Text('Restore Purchase'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    showModalBottomSheet<void>(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                      builder: (_) => const _LegalInfoSheet(
                                        title: 'Privacy Policy',
                                        sections: [
                                          _LegalSection(
                                            heading: 'What TempCam stores',
                                            body: 'Temp photos and videos are stored locally on the device inside TempCam until they expire, are deleted, or are kept forever by the user.',
                                          ),
                                          _LegalSection(
                                            heading: 'What TempCam does not do',
                                            body: 'TempCam does not upload your temporary media to a cloud service inside the app flow. Subscription billing is handled by the platform store.',
                                          ),
                                          _LegalSection(
                                            heading: 'Before release',
                                            body: 'Host this privacy policy on a public URL and add that URL in the Play Console privacy policy field before publishing.',
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: const Text('Privacy Policy'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    showModalBottomSheet<void>(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                      builder: (_) => const _LegalInfoSheet(
                                        title: 'Subscription Terms',
                                        sections: [
                                          _LegalSection(
                                            heading: 'Plan',
                                            body: 'TempCam offers one auto-renewing yearly subscription for access to the app.',
                                          ),
                                          _LegalSection(
                                            heading: 'Billing',
                                            body: 'Payment is charged by Google Play or the App Store at confirmation of purchase. Subscriptions renew automatically unless canceled before the renewal date.',
                                          ),
                                          _LegalSection(
                                            heading: 'Managing access',
                                            body: 'Users can restore purchases after reinstall and can manage or cancel subscriptions from their platform subscription settings.',
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: const Text('Terms'),
                                ),
                              ],
                            ),
                          ],
                          if (controller.premiumAccessExpiresAt != null && isActive && !isTestAccess) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Access recorded until ${_formatExpiry(controller.premiumAccessExpiresAt!)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatExpiry(DateTime value) {
    final month = _monthNames[value.month - 1];
    return '$month ${value.day}, ${value.year}';
  }

  static const List<String> _monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(this.icon, this.accent, this.title, this.body);

  final IconData icon;
  final Color accent;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > 220;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          child: horizontal
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: accent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            body,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: accent),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.title,
    required this.subtitle,
    required this.caption,
    required this.selected,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String caption;
  final bool selected;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: selected ? AppTheme.surfaceHighest : AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.4)
              : AppTheme.outlineVariant.withValues(alpha: 0.16),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      badge!.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary),
                    ),
                  ),
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(caption,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, height: 1.35)),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.outline)),
            child: selected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: AppTheme.primary),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _LegalInfoSheet extends StatelessWidget {
  const _LegalInfoSheet({
    required this.title,
    required this.sections,
  });

  final String title;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xF1141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            ...sections.map(
              (section) => Padding(
                padding: EdgeInsets.only(bottom: section == sections.last ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.heading,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      section.body,
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection({
    required this.heading,
    required this.body,
  });

  final String heading;
  final String body;
}
