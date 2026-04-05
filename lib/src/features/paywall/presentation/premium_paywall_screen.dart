import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tempcam/src/localization/app_localizations.dart';

import '../../../core/constants/legal_links.dart';
import '../../../core/constants/premium_constants.dart';
import '../../../shared/state/app_controller.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/tempcam_brand_mark.dart';

class PremiumPaywallScreen extends StatelessWidget {
  const PremiumPaywallScreen({
    super.key,
    this.requiredForAccess = false,
  });

  static const MethodChannel _systemChannel = MethodChannel('tempcam/system');

  final bool requiredForAccess;

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PremiumPaywallScreen()),
    );
  }

  static Future<void> _openLegalLink(
    BuildContext context, {
    required String rawUrl,
    required VoidCallback fallback,
  }) async {
    final url = rawUrl.trim();
    if (url.isEmpty) {
      fallback();
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      fallback();
      return;
    }
    try {
      final launched = await _systemChannel.invokeMethod<bool>(
        'openExternalUrl',
        <String, dynamic>{'url': uri.toString()},
      );
      if (launched == true) {
        return;
      }
    } catch (_) {}
    if (context.mounted) {
      fallback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        final l10n = context.l10n;
        const bool isTestAccess = PremiumConstants.paymentsTemporarilyDisabled;
        final bool isActive = controller.hasPremiumAccess;
        final bool hasStoreTrial = controller.hasStoreManagedTrialOffer;
        final bool isBusy =
            controller.isPurchasePending || controller.isStoreLoading;
        final String priceLine = controller.yearlySubscriptionProduct == null
            ? PremiumConstants.fallbackYearlyPlanLabel
            : '${controller.yearlyPriceLabel} / year';
        final String title = isTestAccess
            ? l10n.tr('Payments Disabled Temporarily')
            : isActive
                ? l10n.tr('Manage TempCam Access')
                : l10n.tr('Unlock Temporary Saving');
        final String description = isTestAccess
            ? l10n.tr(
                'This build bypasses subscriptions so you can test TempCam on your phone before store upload.',
              )
            : isActive
                ? l10n.tr(
                    'Your subscription is handled directly by the App Store or Google Play with one yearly plan.',
                  )
                : hasStoreTrial
                    ? l10n.tr(
                        'Explore the full app first. Start the secure store-managed 15-day trial when you are ready to save captures with timers, import media, and turn on private protection features.',
                      )
                    : l10n.tr(
                        'Explore the full app first. Start or restore yearly access when you are ready to save captures with timers, import media, and turn on private protection features.',
                      );
        final String badgeText = isTestAccess
            ? l10n.tr('PAYMENT OFF')
            : isActive
                ? l10n.tr('ACTIVE')
                : hasStoreTrial
                    ? l10n.tr('15 DAYS FREE')
                    : l10n.tr('UNLOCK SAVE');
        final String buttonText = isTestAccess
            ? l10n.tr('Payment Disabled For Testing')
            : hasStoreTrial
                ? l10n.tr('Start 15 Days Free')
                : isActive
                    ? l10n.tr('Access Active')
                    : isBusy
                        ? l10n.tr('Connecting To Store...')
                        : l10n.tr(
                            'Unlock 1 Year For {price}',
                            {'price': controller.yearlyPriceLabel},
                          );
        final String footerText = isTestAccess
            ? l10n.tr(
                'Disable TEMPCAM_DISABLE_PAYMENTS before uploading to the store.',
              )
            : l10n.tr(
                'Auto-renewing yearly subscription. Cancel anytime in Google Play or App Store subscriptions.',
              );
        final String pricingCaption = isTestAccess
            ? l10n.tr(
                'Store billing is currently bypassed by a temporary app-wide test switch.',
              )
            : hasStoreTrial
                ? l10n.tr(
                    'If eligible, checkout starts with the store-managed 15-day free trial and then renews yearly after temporary saving is unlocked.',
                  )
                : isActive
                    ? l10n.tr('Your yearly subscription is active.')
                    : controller.yearlySubscriptionProduct == null
                        ? l10n.tr(
                            'Fallback price shown until the store catalog loads.')
                        : l10n.tr(
                            'Directly billed and renewed by the platform store when you unlock saving.');

        return Scaffold(
          body: Stack(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF090B10),
                      AppTheme.surface,
                      AppTheme.surfaceLowest,
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -120,
                right: -40,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                left: -50,
                top: 180,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.secondary.withValues(alpha: 0.06),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight - 42),
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
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.16),
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
                          _PremiumHeroPanel(
                            title: title,
                            description: description,
                            badgeText: badgeText,
                            priceLine: priceLine,
                            pricingCaption: pricingCaption,
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
                                children: [
                                  _FeatureCard(
                                    Icons.lock_clock_rounded,
                                    AppTheme.primary,
                                    l10n.tr('Timed Saving'),
                                    l10n.tr(
                                      'Apply self-destruct timers and keep temporary captures inside TempCam after you enroll.',
                                    ),
                                  ),
                                  _FeatureCard(
                                    Icons.calendar_month_rounded,
                                    AppTheme.secondary,
                                    l10n.tr('Store Managed'),
                                    l10n.tr(
                                      'One yearly subscription, with the 15-day trial handled by Google Play or the App Store when eligible.',
                                    ),
                                  ),
                                  _FeatureCard(
                                    Icons.fingerprint_rounded,
                                    AppTheme.primary,
                                    l10n.tr('Private Protection'),
                                    l10n.tr(
                                      'Biometric lock, session privacy mode, and private retention controls stay aligned with your active access.',
                                    ),
                                  ),
                                  _FeatureCard(
                                    Icons.restore_rounded,
                                    AppTheme.secondary,
                                    l10n.tr('Restore Access'),
                                    l10n.tr(
                                      'Recover your yearly access from the App Store or Google Play on reinstall.',
                                    ),
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
                                border: Border.all(
                                    color: AppTheme.outlineVariant
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                controller.billingStatusMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    height: 1.4),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _PricingCard(
                            title: l10n.tr('Annual Access'),
                            subtitle: priceLine,
                            caption: pricingCaption,
                            selected: true,
                            badge: isTestAccess
                                ? l10n.tr('Testing')
                                : hasStoreTrial
                                    ? l10n.tr('Trial Then Yearly')
                                    : l10n.tr('Only Plan'),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: const Color(0xFF002A55),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
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
                          Text(
                            footerText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                                          final message = await context
                                              .read<AppController>()
                                              .restorePremiumPurchases();
                                          if (message != null &&
                                              context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(content: Text(message)),
                                            );
                                          }
                                        },
                                  child: Text(l10n.tr('Restore Purchase')),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _openLegalLink(
                                      context,
                                      rawUrl: LegalLinks.privacyPolicyUrl,
                                      fallback: () {
                                        showModalBottomSheet<void>(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          isScrollControlled: true,
                                          builder: (_) => _LegalInfoSheet(
                                            title: l10n.tr('Privacy Policy'),
                                            sections: [
                                              _LegalSection(
                                                heading: l10n.tr(
                                                  'What TempCam stores',
                                                ),
                                                body: l10n.tr(
                                                  'Temp photos and videos are stored locally on the device inside TempCam until they expire, are deleted, or are kept forever by the user.',
                                                ),
                                              ),
                                              _LegalSection(
                                                heading: l10n.tr(
                                                  'What TempCam does not do',
                                                ),
                                                body: l10n.tr(
                                                  'TempCam does not upload your temporary media to a cloud service inside the app flow. Subscription billing is handled by the platform store.',
                                                ),
                                              ),
                                              _LegalSection(
                                                heading: l10n.tr(
                                                  'Before release',
                                                ),
                                                body: l10n.tr(
                                                  'Set TEMPCAM_PRIVACY_POLICY_URL during your release build to open your hosted policy page from the app.',
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Text(l10n.tr('Privacy Policy')),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _openLegalLink(
                                      context,
                                      rawUrl: LegalLinks.subscriptionTermsUrl,
                                      fallback: () {
                                        showModalBottomSheet<void>(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          isScrollControlled: true,
                                          builder: (_) => _LegalInfoSheet(
                                            title: l10n.tr(
                                              'Subscription Terms',
                                            ),
                                            sections: [
                                              _LegalSection(
                                                heading: l10n.tr('Plan'),
                                                body: l10n.tr(
                                                  'TempCam offers one auto-renewing yearly subscription for access to the app.',
                                                ),
                                              ),
                                              _LegalSection(
                                                heading: l10n.tr('Billing'),
                                                body: l10n.tr(
                                                  'Payment is charged by Google Play or the App Store at confirmation of purchase. Subscriptions renew automatically unless canceled before the renewal date.',
                                                ),
                                              ),
                                              _LegalSection(
                                                heading: l10n.tr(
                                                  'Managing access',
                                                ),
                                                body: l10n.tr(
                                                  'Users can restore purchases after reinstall and can manage or cancel subscriptions from their platform subscription settings.',
                                                ),
                                              ),
                                              _LegalSection(
                                                heading: l10n.tr(
                                                  'Release setup',
                                                ),
                                                body: l10n.tr(
                                                  'Set TEMPCAM_SUBSCRIPTION_TERMS_URL during your release build to open your hosted terms page from the app.',
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Text(l10n.tr('Terms')),
                                ),
                              ],
                            ),
                          ],
                          if (controller.premiumAccessExpiresAt != null &&
                              isActive &&
                              !isTestAccess) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.tr(
                                'Access recorded until {date}',
                                {
                                  'date': l10n.formatDate(
                                    controller.premiumAccessExpiresAt!,
                                  ),
                                },
                              ),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.onSurfaceVariant),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.12),
                AppTheme.surfaceContainer.withValues(alpha: 0.94),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
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
        gradient: selected
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1B2636),
                  Color(0xFF121922),
                ],
              )
            : null,
        color: selected ? null : AppTheme.surfaceLow,
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

class _PremiumHeroPanel extends StatelessWidget {
  const _PremiumHeroPanel({
    required this.title,
    required this.description,
    required this.badgeText,
    required this.priceLine,
    required this.pricingCaption,
  });

  final String title;
  final String description;
  final String badgeText;
  final String priceLine;
  final String pricingCaption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF151F2D),
            Color(0xFF0E131B),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          const TempCamBrandMark(size: 112, showGlow: false),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
                color: AppTheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              color: AppTheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  icon: Icons.workspace_premium_rounded,
                  title: priceLine,
                  subtitle: pricingCaption,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  icon: Icons.lock_clock_rounded,
                  title: AppLocalizations.of(context).tr('Timed Saving'),
                  subtitle: AppLocalizations.of(context).tr(
                    'Apply self-destruct timers and keep temporary captures inside TempCam after you enroll.',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.4,
            ),
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
                padding:
                    EdgeInsets.only(bottom: section == sections.last ? 0 : 16),
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
