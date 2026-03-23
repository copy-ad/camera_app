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
            ? 'Set paymentsTemporarilyDisabled to false before uploading.'
            : 'One subscription. No monthly tier. Managed directly by Apple or Google.';
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (!requiredForAccess)
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded,
                                  color: AppTheme.primary),
                            )
                          else
                            const SizedBox(width: 48),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
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
                      const SizedBox(height: 18),
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.surfaceHighest,
                        child: Icon(Icons.verified_user_rounded,
                            color: AppTheme.secondary),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18,
                            color: AppTheme.onSurfaceVariant,
                            height: 1.45),
                      ),
                      const SizedBox(height: 28),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.05,
                          physics: const NeverScrollableScrollPhysics(),
                          children: const [
                            _FeatureCard(
                                Icons.lock_clock_rounded,
                                AppTheme.primary,
                                'Whole App Access',
                                'Without an active yearly subscription, the camera vault stays locked at launch.'),
                            _FeatureCard(
                                Icons.calendar_month_rounded,
                                AppTheme.secondary,
                                'One Year Window',
                                'The client records one year of access from the verified store purchase date.'),
                            _FeatureCard(
                                Icons.fingerprint_rounded,
                                AppTheme.primary,
                                'Biometric Re-Entry',
                                'After access is active, Face ID or fingerprint can protect future app launches.'),
                            _FeatureCard(
                                Icons.restore_rounded,
                                AppTheme.secondary,
                                'Restore Support',
                                'Recover your yearly access from the App Store or Google Play on reinstall.'),
                          ],
                        ),
                      ),
                      if (controller.billingStatusMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: AppTheme.outlineVariant
                                    .withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            controller.billingStatusMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppTheme.onSurfaceVariant, height: 1.4),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999)),
                          ),
                          onPressed: isTestAccess || isActive || isBusy
                              ? null
                              : () async {
                                  final message = await context
                                      .read<AppController>()
                                      .purchasePremiumSubscription();
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
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        footerText,
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            color: AppTheme.onSurfaceVariant),
                      ),
                      if (!isTestAccess) ...[
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 18,
                          alignment: WrapAlignment.center,
                          children: [
                            TextButton(
                              onPressed: isBusy
                                  ? null
                                  : () async {
                                      final message = await context
                                          .read<AppController>()
                                          .restorePremiumPurchases();
                                      if (message != null && context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text(message)),
                                        );
                                      }
                                    },
                              child: const Text('Restore Purchase'),
                            ),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Add your privacy policy URL before release.')),
                                );
                              },
                              child: const Text('Privacy Policy'),
                            ),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Add your terms of service URL before release.')),
                                );
                              },
                              child: const Text('Terms'),
                            ),
                          ],
                        ),
                      ],
                      if (controller.premiumAccessExpiresAt != null &&
                          isActive &&
                          !isTestAccess) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Access recorded until ${_formatExpiry(controller.premiumAccessExpiresAt!)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ],
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 19,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  color: AppTheme.onSurfaceVariant, height: 1.45)),
        ],
      ),
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
