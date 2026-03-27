abstract final class LegalLinks {
  const LegalLinks._();

  static const String privacyPolicyUrl = String.fromEnvironment(
    'TEMPCAM_PRIVACY_POLICY_URL',
    defaultValue: '',
  );

  static const String subscriptionTermsUrl = String.fromEnvironment(
    'TEMPCAM_SUBSCRIPTION_TERMS_URL',
    defaultValue: '',
  );
}
