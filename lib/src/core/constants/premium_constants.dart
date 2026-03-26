abstract final class PremiumConstants {
  static const bool paymentsTemporarilyDisabled = bool.fromEnvironment(
    'TEMPCAM_DISABLE_PAYMENTS',
    defaultValue: false,
  );
  static const String yearlySubscriptionProductId = 'tempcam_premium_yearly';
  static const String fallbackYearlyPriceLabel = '\$3.00';
  static const String fallbackYearlyPlanLabel = '\$3.00 / year';
  static const Duration subscriptionAccessWindow = Duration(days: 366);
}
