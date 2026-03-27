abstract final class LegalLinks {
  const LegalLinks._();

  static const String privacyPolicyUrl = String.fromEnvironment(
    'https://copy-ad.github.io/camera_app/privacy-policy.html',
    defaultValue: '',
  );

  static const String subscriptionTermsUrl = String.fromEnvironment(
    'https://copy-ad.github.io/camera_app/subscription-terms.html',
    defaultValue: '',
  );
}
