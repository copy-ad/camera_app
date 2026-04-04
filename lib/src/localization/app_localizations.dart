import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../shared/models/app_settings.dart';

@immutable
class AppLanguageOption {
  const AppLanguageOption({
    required this.tag,
    required this.locale,
    required this.nativeName,
  });

  final String tag;
  final Locale locale;
  final String nativeName;
}

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const Locale fallbackLocale = Locale('en');

  static const List<AppLanguageOption> supportedLanguages = [
    AppLanguageOption(
      tag: 'en',
      locale: Locale('en'),
      nativeName: 'English',
    ),
    AppLanguageOption(
      tag: 'zh',
      locale: Locale('zh'),
      nativeName: 'Chinese (Simplified)',
    ),
    AppLanguageOption(
      tag: 'es',
      locale: Locale('es'),
      nativeName: 'Spanish',
    ),
    AppLanguageOption(
      tag: 'tr',
      locale: Locale('tr'),
      nativeName: 'Turkish',
    ),
    AppLanguageOption(
      tag: 'de',
      locale: Locale('de'),
      nativeName: 'Deutsch',
    ),
    AppLanguageOption(
      tag: 'fr',
      locale: Locale('fr'),
      nativeName: 'French',
    ),
    AppLanguageOption(
      tag: 'pt_BR',
      locale: Locale('pt', 'BR'),
      nativeName: 'Portuguese (Brazil)',
    ),
    AppLanguageOption(
      tag: 'ru',
      locale: Locale('ru'),
      nativeName: 'Russian',
    ),
    AppLanguageOption(
      tag: 'ar',
      locale: Locale('ar'),
      nativeName: 'Arabic',
    ),
    AppLanguageOption(
      tag: 'ko',
      locale: Locale('ko'),
      nativeName: 'Korean',
    ),
  ];

  static List<Locale> get supportedLocales => supportedLanguages
      .map((language) => language.locale)
      .toList(growable: false);

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null,
        'AppLocalizations is not available in this context.');
    return localizations!;
  }

  static AppLocalizations fromLocale(Locale? locale) {
    return AppLocalizations(resolveSupportedLocale(locale));
  }

  static Locale resolveSupportedLocale(Locale? locale) {
    if (locale == null) {
      return fallbackLocale;
    }

    final normalizedLanguage = locale.languageCode.toLowerCase();
    final normalizedCountry = locale.countryCode?.toUpperCase();

    for (final supported in supportedLanguages) {
      if (supported.locale.languageCode.toLowerCase() != normalizedLanguage) {
        continue;
      }
      final supportedCountry = supported.locale.countryCode?.toUpperCase();
      if (supportedCountry == null ||
          normalizedCountry == null ||
          supportedCountry == normalizedCountry) {
        return supported.locale;
      }
    }

    return fallbackLocale;
  }

  static Locale? parseLocaleTag(String? tag) {
    if (tag == null || tag.isEmpty) {
      return null;
    }
    for (final option in supportedLanguages) {
      if (option.tag == tag) {
        return option.locale;
      }
    }
    return null;
  }

  static String localeTag(Locale locale) {
    for (final option in supportedLanguages) {
      if (option.locale.languageCode == locale.languageCode &&
          option.locale.countryCode == locale.countryCode) {
        return option.tag;
      }
    }
    return locale.countryCode == null
        ? locale.languageCode
        : '${locale.languageCode}_${locale.countryCode}';
  }

  String get intlLocaleName {
    final countryCode = locale.countryCode;
    if (countryCode == null || countryCode.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}_$countryCode';
  }

  String tr(String source, [Map<String, String> args = const {}]) {
    final tag = localeTag(locale);
    final languageMap =
        _localizedValues[tag] ?? _localizedValues[fallbackLocale.languageCode]!;
    var value = languageMap[source] ?? source;
    for (final entry in args.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  String languageName(String? tag) {
    if (tag == null || tag.isEmpty) {
      return tr('System Default');
    }
    for (final option in supportedLanguages) {
      if (option.tag == tag) {
        return option.nativeName;
      }
    }
    return tag;
  }

  String timerLabel(AppTimerOption option) => tr(option.label);

  String timerLabelFromString(String rawLabel) => tr(rawLabel);

  String quickLockTimeoutLabel(QuickLockTimeoutOption option) =>
      tr(option.label);

  String formatDate(DateTime value) {
    return DateFormat.yMMMd(intlLocaleName).format(value);
  }

  String formatDateTime(DateTime value) {
    final date = DateFormat.yMMMd(intlLocaleName).format(value);
    final time = DateFormat.jm(intlLocaleName).format(value);
    return '$date • $time';
  }

  String formatRemaining(DateTime? expiresAt, {required bool isKeptForever}) {
    if (isKeptForever) {
      return tr('Forever');
    }
    if (expiresAt == null) {
      return tr('Expired');
    }
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    if (difference.isNegative) {
      return tr('Expired');
    }
    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);
    final minutes = difference.inMinutes.remainder(60);
    if (days > 0) {
      return tr('{days}d {hours}h', {
        'days': '$days',
        'hours': '$hours',
      });
    }
    if (difference.inHours > 0) {
      return tr('{hours}h {minutes}m', {
        'hours': '${difference.inHours}',
        'minutes': '$minutes',
      });
    }
    return tr('{minutes}m', {'minutes': '${difference.inMinutes}'});
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLanguages.any(
      (language) => language.locale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
      AppLocalizations.fromLocale(locale),
    );
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

const Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'System Default': 'System Default',
    'Language': 'Language',
    'Choose the app language. System Default follows your phone language.':
        'Choose the app language. System Default follows your phone language.',
    'Press back again to exit TempCam': 'Press back again to exit TempCam',
    'Protected Preview': 'Protected Preview',
    '15 DAYS FREE': '15 DAYS FREE',
    'Start with a secure free trial.': 'Start with a secure free trial.',
    'Google Play will start your 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'Google Play will start your 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.',
    'If your Google Play account is eligible, the store will offer a 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'If your Google Play account is eligible, the store will offer a 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.',
    'After the trial ends, Google Play continues the subscription at {price} per year unless the user cancels in time.':
        'After the trial ends, Google Play continues the subscription at {price} per year unless the user cancels in time.',
    'Continue To Access': 'Continue To Access',
    'PRIVATE • TEMPORARY • LOCAL': 'PRIVATE • TEMPORARY • LOCAL',
    'Preparing secure vault experience': 'Preparing secure vault experience',
    'Secure session initializing': 'Secure session initializing',
    'LOCAL PRIVATE STORAGE': 'LOCAL PRIVATE STORAGE',
    'Vault Locked': 'Vault Locked',
    'Authenticating now. If the prompt does not appear, tap below to unlock TempCam.':
        'Authenticating now. If the prompt does not appear, tap below to unlock TempCam.',
    'Biometrics are unavailable on this device. Continue without biometric lock from settings.':
        'Biometrics are unavailable on this device. Continue without biometric lock from settings.',
    'Unlocking...': 'Unlocking...',
    'Unlock TempCam': 'Unlock TempCam',
    'Switching camera...': 'Switching camera...',
    'Default {timer}': 'Default {timer}',
    'PHOTO': 'PHOTO',
    'VIDEO': 'VIDEO',
    'Private Preview': 'Private Preview',
    'Tap to view': 'Tap to view',
    'Set Self-Destruct Timer': 'Set Self-Destruct Timer',
    '7 day timers are available with Premium.':
        '7 day timers are available with Premium.',
    'Choose when this capture evaporates from the vault.':
        'Choose when this capture evaporates from the vault.',
    'Unlock Premium to use the 7 day timer.':
        'Unlock Premium to use the 7 day timer.',
    'Apply Timer': 'Apply Timer',
    'Defaults to 24 hours if skipped.': 'Defaults to 24 hours if skipped.',
    'Review this private video before setting its timer.':
        'Review this private video before setting its timer.',
    'Review this private photo before setting its timer.':
        'Review this private photo before setting its timer.',
    'Unlock Premium': 'Unlock Premium',
    'Private Vault': 'Private Vault',
    'Encrypted Vault': 'Private Vault',
    'Expiring in': 'Expiring in',
    'Created': 'Created',
    'Private Video': 'Private Video',
    'Private Photo': 'Private Photo',
    'Detected details': 'Detected details',
    'Saved in TempCam until this photo expires or you keep it forever.':
        'Saved in TempCam until this photo expires or you keep it forever.',
    'Phone numbers': 'Phone numbers',
    'Addresses': 'Addresses',
    'Detected phone number': 'Detected phone number',
    'Detected address': 'Detected address',
    'Detected details before saving': 'Detected details before saving',
    'Use the detected phone number or address first, then tap Temp Save to choose the timer.':
        'Use the detected phone number or address first, then tap Temp Save to choose the timer.',
    'Extend Timer': 'Extend Timer',
    'Keep Forever': 'Keep Forever',
    'Premium Only': 'Premium Only',
    'Delete Now': 'Delete Now',
    'Call': 'Call',
    'Add to Contacts': 'Add to Contacts',
    'Open in Maps': 'Open in Maps',
    'Temp Save': 'Temp Save',
    'Discard': 'Discard',
    'TempCam Contact': 'TempCam Contact',
    'Unable to open the phone dialer right now.':
        'Unable to open the phone dialer right now.',
    'Unable to open the contacts app right now.':
        'Unable to open the contacts app right now.',
    'Unable to open the map right now.': 'Unable to open the map right now.',
    'Tap to view detected details': 'Tap to view detected details',
    'Media no longer exists.': 'Media no longer exists.',
    'WELCOME': 'WELCOME',
    'CAMERA': 'CAMERA',
    'SCAN': 'SCAN',
    'TIMERS': 'TIMERS',
    'VAULT': 'VAULT',
    'SECURITY': 'SECURITY',
    'SETTINGS': 'SETTINGS',
    'Capture private photos and videos fast.':
        'Capture private photos and videos fast.',
    'Use photo or video mode, tap to focus, pinch to zoom, control flash, and keep sensitive captures out of the main gallery from the start.':
        'Use photo or video mode, tap to focus, pinch to zoom, control flash, and keep sensitive captures out of the main gallery from the start.',
    'Document scan actions happen before saving.':
        'Document scan actions happen before saving.',
    'If TempCam detects a phone number or address in a photo, you can call, add a contact, open maps, or tap Temp Save before choosing the timer.':
        'If TempCam detects a phone number or address in a photo, you can call, add a contact, open maps, or tap Temp Save before choosing the timer.',
    'The vault keeps temporary media organized.':
        'The vault keeps temporary media organized.',
    'Browse private photos and videos, see expiring items, open detected details again, import media into TempCam, extend timers, or delete items when you need to.':
        'Browse private photos and videos, see expiring items, open detected details again, import media into TempCam, extend timers, or delete items when you need to.',
    'Privacy protection stays ready under pressure.':
        'Privacy protection stays ready under pressure.',
    'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and Panic Exit for faster privacy when you need it.':
        'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and Panic Exit for faster privacy when you need it.',
    'Temp Save leads into the self-destruct timer.':
        'Temp Save leads into the self-destruct timer.',
    'After capture or import, choose how long each item should stay in TempCam. If you skip it, TempCam uses your default timer from Settings.':
        'After capture or import, choose how long each item should stay in TempCam. If you skip it, TempCam uses your default timer from Settings.',
    'Settings controls language, reminders, and access.':
        'Settings controls language, reminders, and access.',
    'Manage app language, expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.':
        'Manage app language, expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.',
    'Everything is designed to keep private photos, videos, and detected document details local first until they expire or you choose to keep them.':
        'Everything is designed to keep private photos, videos, and detected document details local first until they expire or you choose to keep them.',
    'TempCam keeps sensitive captures temporary.':
        'TempCam keeps sensitive captures temporary.',
    'Take private photos and videos inside TempCam, keep them out of the main gallery, and let them disappear unless you keep them forever.':
        'Take private photos and videos inside TempCam, keep them out of the main gallery, and let them disappear unless you keep them forever.',
    'Capture quickly with the private camera.':
        'Capture quickly with the private camera.',
    'Use photo or video mode, tap to focus, pinch to zoom, control flash, and review the private preview before you apply the timer.':
        'Use photo or video mode, tap to focus, pinch to zoom, control flash, and review the private preview before you apply the timer.',
    'Every item gets a self-destruct timer.':
        'Every item gets a self-destruct timer.',
    'Choose a timer after capture or import. If you skip it, TempCam uses your default timer from Settings.':
        'Choose a timer after capture or import. If you skip it, TempCam uses your default timer from Settings.',
    'The vault keeps temp media private first.':
        'The vault keeps temp media private first.',
    'Browse photos and videos in the private vault, filter by type, import existing media into TempCam, extend timers, or delete items when you need to.':
        'Browse photos and videos in the private vault, filter by type, import existing media into TempCam, extend timers, or delete items when you need to.',
    'Biometrics, quick relock, and Panic Exit stay ready.':
        'Biometrics, quick relock, and Panic Exit stay ready.',
    'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and Panic Exit for faster privacy under pressure.':
        'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and Panic Exit for faster privacy under pressure.',
    'Settings controls reminders, stealth mode, and access.':
        'Settings controls reminders, stealth mode, and access.',
    'Manage expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.':
        'Manage expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.',
    'APP TOUR': 'APP TOUR',
    'Skip': 'Skip',
    'Back': 'Back',
    'Get Started': 'Get Started',
    'Next': 'Next',
    'You can skip this now and reopen it any time from Settings.':
        'You can skip this now and reopen it any time from Settings.',
    'Capture Defaults': 'Capture Defaults',
    'Default Self-Destruct Timer': 'Default Self-Destruct Timer',
    'Choose how long new captures stay available by default.':
        'Choose how long new captures stay available by default.',
    'Expiry Notifications': 'Expiry Notifications',
    'Get warned before temporary media disappears.':
        'Get warned before temporary media disappears.',
    'Stealth Notifications': 'Stealth Notifications',
    'Hide photo and video wording in reminders for a quieter lock-screen presence.':
        'Hide photo and video wording in reminders for a quieter lock-screen presence.',
    'Security': 'Security',
    'Biometric Lock': 'Biometric Lock',
    'Protect app entry and sensitive actions with biometrics.':
        'Protect app entry and sensitive actions with biometrics.',
    'Biometric protection is unavailable on this device.':
        'Biometric protection is unavailable on this device.',
    'Session Privacy Mode': 'Session Privacy Mode',
    'Lock TempCam immediately whenever the app loses focus.':
        'Lock TempCam immediately whenever the app loses focus.',
    'Enable Biometric Lock first to use instant session relocking.':
        'Enable Biometric Lock first to use instant session relocking.',
    'Quick Lock Timeout': 'Quick Lock Timeout',
    'Session Privacy Mode locks instantly, so timeout is bypassed.':
        'Session Privacy Mode locks instantly, so timeout is bypassed.',
    'Choose how long TempCam can stay in the background before it asks for biometrics again.':
        'Choose how long TempCam can stay in the background before it asks for biometrics again.',
    'Help': 'Help',
    'Replay App Tour': 'Replay App Tour',
    'Walk through camera, timers, vault, security, and settings again any time.':
        'Walk through camera, smart scan, vault, security, timers, and settings again any time.',
    'Replay Tour': 'Replay Tour',
    'Why People Use TempCam': 'Why People Use TempCam',
    'Temporary by default': 'Temporary by default',
    'Photos and videos auto-delete unless you decide to keep them forever.':
        'Photos and videos auto-delete unless you decide to keep them forever.',
    'Private by design': 'Private by design',
    'Temporary captures stay inside TempCam instead of appearing in the main gallery.':
        'Temporary captures stay inside TempCam instead of appearing in the main gallery.',
    'Fast under pressure': 'Fast under pressure',
    'Panic Exit and quick relocking help when you need privacy right away.':
        'Panic Exit and quick relocking help when you need privacy right away.',
    'Manage Access': 'Manage Access',
    'Trusted Vault History': 'Trusted Vault History',
    'Local record of exports, deletions, and auto-deletions.':
        'Local record of exports, deletions, and auto-deletions.',
    'Privacy Notes': 'Privacy Notes',
    'Temp media stays local to your device until you explicitly keep it forever. Recent-app previews are shielded, and sensitive actions stay protected behind biometric confirmation when enabled.':
        'Temp media stays local to your device until you explicitly keep it forever. Recent-app previews are shielded, and sensitive actions stay protected behind biometric confirmation when enabled.',
    'Panic Exit': 'Panic Exit',
    'Close TempCam immediately and relock on return.':
        'Close TempCam immediately and relock on return.',
    'Open Camera': 'Open Camera',
    'Open Vault': 'Open Vault',
    'All': 'All',
    'Photos': 'Photos',
    'Videos': 'Videos',
    'All Media': 'All Media',
    'Cancel': 'Cancel',
    'Delete': 'Delete',
    'Kept Forever': 'Kept Forever',
    'Your vault is empty': 'Your vault is empty',
    'No temp photos yet': 'No temp photos yet',
    'No temp videos yet': 'No temp videos yet',
    'Capture a photo or video and it will appear here with its self-destruct timer.':
        'Capture a photo or video and it will appear here with its self-destruct timer.',
    'This filter only shows temp photos stored inside TempCam.':
        'This filter only shows temp photos stored inside TempCam.',
    'This filter only shows temp videos stored inside TempCam.':
        'This filter only shows temp videos stored inside TempCam.',
    'Restore Purchase': 'Restore Purchase',
    'Privacy Policy': 'Privacy Policy',
    'Terms': 'Terms',
    '1 Hour': '1 Hour',
    '3 Hours': '3 Hours',
    '12 Hours': '12 Hours',
    '24 Hours': '24 Hours',
    '3 Days': '3 Days',
    '7 Days': '7 Days',
    '5 Seconds': '5 Seconds',
    '15 Seconds': '15 Seconds',
    '30 Seconds': '30 Seconds',
    'Forever': 'Forever',
    'Expired': 'Expired',
    '{days}d {hours}h': '{days}d {hours}h',
    '{hours}h {minutes}m': '{hours}h {minutes}m',
    '{minutes}m': '{minutes}m',
    'Start': 'Start',
    'Every temporary moment, in one calm vault.':
        'Every temporary moment, in one calm vault.',
    'Browse all temp photos and videos, focus on what is expiring, and clean up quickly when you need to.':
        'Browse all temp photos and videos, focus on what is expiring, and clean up quickly when you need to.',
    '{count} temp items ready': '{count} temp items ready',
    'Capture': 'Capture',
    'Done': 'Done',
    'Done ({count})': 'Done ({count})',
    'Select': 'Select',
    'Choose items to delete.': 'Choose items to delete.',
    '{count} items selected for deletion.':
        '{count} items selected for deletion.',
    'Expiring Soon': 'Expiring Soon',
    '{count} items deleted from TempCam.':
        '{count} items deleted from TempCam.',
    'FREE TRIAL': 'FREE TRIAL',
    'ACTIVE': 'ACTIVE',
    'REQUIRED': 'REQUIRED',
    'Your access is live.': 'Your access is live.',
    'Start with 15 days free.': 'Start with 15 days free.',
    'Yearly access powers TempCam.': 'Yearly access powers TempCam.',
    'Your current subscription is active through the store.':
        'Your current subscription is active through the store.',
    'Access is recorded until {date}.': 'Access is recorded until {date}.',
    'Google Play or the App Store can start a secure 15-day free trial for eligible accounts before yearly billing begins.':
        'Google Play or the App Store can start a secure 15-day free trial for eligible accounts before yearly billing begins.',
    'A {price} yearly subscription keeps TempCam private, temporary, and fully unlocked.':
        'A {price} yearly subscription keeps TempCam private, temporary, and fully unlocked.',
    'View Yearly Plan': 'View Yearly Plan',
    'View Access Options': 'View Access Options',
    'LOCAL | TEMPORARY | PROTECTED': 'LOCAL | TEMPORARY | PROTECTED',
    'Keep Forever exports, manual deletions, and auto-deletions will appear here as a local trust log.':
        'Keep Forever exports, manual deletions, and auto-deletions will appear here as a local trust log.',
    'Payments Disabled Temporarily': 'Payments Disabled Temporarily',
    'Access Required': 'Access Required',
    'Manage TempCam Access': 'Manage TempCam Access',
    'This build bypasses subscriptions so you can test TempCam on your phone before store upload.':
        'This build bypasses subscriptions so you can test TempCam on your phone before store upload.',
    'Start the Google Play or App Store managed 15-day free trial, or restore your yearly access to open TempCam.':
        'Start the Google Play or App Store managed 15-day free trial, or restore your yearly access to open TempCam.',
    'Buy or restore yearly access to open TempCam. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'Buy or restore yearly access to open TempCam. If your store account is eligible, the platform may apply the 15-day free trial during checkout.',
    'Your subscription is handled directly by the App Store or Google Play with one yearly plan.':
        'Your subscription is handled directly by the App Store or Google Play with one yearly plan.',
    'Start your secure store-managed 15-day free trial, then continue with one yearly plan.':
        'Start your secure store-managed 15-day free trial, then continue with one yearly plan.',
    'Start or restore yearly access. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'Start or restore yearly access. If your store account is eligible, the platform may apply the 15-day free trial during checkout.',
    'PAYMENT OFF': 'PAYMENT OFF',
    'YEARLY ACCESS': 'YEARLY ACCESS',
    'Payment Disabled For Testing': 'Payment Disabled For Testing',
    'Start 15 Days Free': 'Start 15 Days Free',
    'Access Active': 'Access Active',
    'Connecting To Store...': 'Connecting To Store...',
    'Buy 1 Year For {price}': 'Buy 1 Year For {price}',
    'Disable TEMPCAM_DISABLE_PAYMENTS before uploading to the store.':
        'Disable TEMPCAM_DISABLE_PAYMENTS before uploading to the store.',
    'Auto-renewing yearly subscription. Cancel anytime in Google Play or App Store subscriptions.':
        'Auto-renewing yearly subscription. Cancel anytime in Google Play or App Store subscriptions.',
    'Store billing is currently bypassed by a temporary app-wide test switch.':
        'Store billing is currently bypassed by a temporary app-wide test switch.',
    'If eligible, checkout starts with the store-managed 15-day free trial and then renews yearly.':
        'If eligible, checkout starts with the store-managed 15-day free trial and then renews yearly.',
    'Your yearly subscription is active.':
        'Your yearly subscription is active.',
    'Fallback price shown until the store catalog loads.':
        'Fallback price shown until the store catalog loads.',
    'Directly billed and renewed by the platform store.':
        'Directly billed and renewed by the platform store.',
    'Annual Access': 'Annual Access',
    'Testing': 'Testing',
    'Trial Then Yearly': 'Trial Then Yearly',
    'Only Plan': 'Only Plan',
    'Store Trial': 'Store Trial',
    'The 15-day free trial is managed by Google Play or the App Store, so clearing app data will not restart it.':
        'The 15-day free trial is managed by Google Play or the App Store, so clearing app data will not restart it.',
    'Yearly Billing': 'Yearly Billing',
    'One auto-renewing yearly subscription managed directly by Google Play or the App Store.':
        'One auto-renewing yearly subscription managed directly by Google Play or the App Store.',
    'Secure Access': 'Secure Access',
    'Once the subscription or trial is active, TempCam unlocks fully and can re-lock with biometrics.':
        'Once the subscription or trial is active, TempCam unlocks fully and can re-lock with biometrics.',
    'Restore Support': 'Restore Support',
    'Recover your yearly access from the App Store or Google Play on reinstall.':
        'Recover your yearly access from the App Store or Google Play on reinstall.',
    'Access recorded until {date}': 'Access recorded until {date}',
    'Camera is unavailable.': 'Camera is unavailable.',
    'Flash auto': 'Flash auto',
    'Flash on': 'Flash on',
    'Flash torch': 'Flash torch',
    'Flash off': 'Flash off',
    'Flash is unavailable on this camera.':
        'Flash is unavailable on this camera.',
    'Video saved to TempCam': 'Video saved to TempCam',
    'Recording started': 'Recording started',
    'Unable to use video recording right now.':
        'Unable to use video recording right now.',
    'Video auto-deleted': 'Video auto-deleted',
    'Photo auto-deleted': 'Photo auto-deleted',
    '{media} expired after {timer} and was removed from TempCam.':
        '{media} expired after {timer} and was removed from TempCam.',
    'Finish the current capture before importing media.':
        'Finish the current capture before importing media.',
    '{count} items imported into TempCam, but {failed} original items could not be removed from the main gallery.':
        '{count} items imported into TempCam, but {failed} original items could not be removed from the main gallery.',
    '{count} items moved into TempCam and removed from the main gallery.':
        '{count} items moved into TempCam and removed from the main gallery.',
    'Unable to import media right now.': 'Unable to import media right now.',
    'Video deleted now': 'Video deleted now',
    'Photo deleted now': 'Photo deleted now',
    '{media} removed manually before its timer ended.':
        '{media} removed manually before its timer ended.',
    'Unable to export this item to the main gallery.':
        'Unable to export this item to the main gallery.',
    'Video kept forever': 'Video kept forever',
    'Photo kept forever': 'Photo kept forever',
    '{media} exported to the main gallery and removed from TempCam expiry.':
        '{media} exported to the main gallery and removed from TempCam expiry.',
    'Video kept forever and exported.': 'Video kept forever and exported.',
    'Photo kept forever and exported.': 'Photo kept forever and exported.',
    'Video': 'Video',
    'Photo': 'Photo',
    'Before release': 'Before release',
    'Billing': 'Billing',
    'Managing access': 'Managing access',
    'Open, capture, review, and protect sensitive moments with fewer steps.':
        'Open, capture, review, and protect sensitive moments with fewer steps.',
    'Payment is charged by Google Play or the App Store at confirmation of purchase. Subscriptions renew automatically unless canceled before the renewal date.':
        'Payment is charged by Google Play or the App Store at confirmation of purchase. Subscriptions renew automatically unless canceled before the renewal date.',
    'Plan': 'Plan',
    'Release setup': 'Release setup',
    'Restore request sent to the store.': 'Restore request sent to the store.',
    'Set TEMPCAM_PRIVACY_POLICY_URL during your release build to open your hosted policy page from the app.':
        'Set TEMPCAM_PRIVACY_POLICY_URL during your release build to open your hosted policy page from the app.',
    'Set TEMPCAM_SUBSCRIPTION_TERMS_URL during your release build to open your hosted terms page from the app.':
        'Set TEMPCAM_SUBSCRIPTION_TERMS_URL during your release build to open your hosted terms page from the app.',
    'Subscription Terms': 'Subscription Terms',
    'Temp photos and videos are stored locally on the device inside TempCam until they expire, are deleted, or are kept forever by the user.':
        'Temp photos and videos are stored locally on the device inside TempCam until they expire, are deleted, or are kept forever by the user.',
    'TempCam does not upload your temporary media to a cloud service inside the app flow. Subscription billing is handled by the platform store.':
        'TempCam does not upload your temporary media to a cloud service inside the app flow. Subscription billing is handled by the platform store.',
    'TempCam offers one auto-renewing yearly subscription for access to the app.':
        'TempCam offers one auto-renewing yearly subscription for access to the app.',
    'Users can restore purchases after reinstall and can manage or cancel subscriptions from their platform subscription settings.':
        'Users can restore purchases after reinstall and can manage or cancel subscriptions from their platform subscription settings.',
    'Waiting for store confirmation...': 'Waiting for store confirmation...',
    'What TempCam does not do': 'What TempCam does not do',
    'What TempCam stores': 'What TempCam stores',
    'Yearly access unlocked. TempCam is ready to use.':
        'Yearly access unlocked. TempCam is ready to use.',
    'Your yearly subscription has been restored.':
        'Your yearly subscription has been restored.',
  },
  'tr': {
    'System Default': 'Sistem Varsayılanı',
    'Language': 'Dil',
    'Choose the app language. System Default follows your phone language.':
        'Uygulama dilini seçin. Sistem Varsayılanı telefonunuzun dilini kullanır.',
    'Press back again to exit TempCam':
        'TempCam çıkmak için geri tuşuna tekrar basın',
    'Protected Preview': 'Korumalı Önizleme',
    '15 DAYS FREE': '15 GÜN ÜCRETSİZ',
    'Start with a secure free trial.':
        'Güvenli bir ücretsiz deneme ile başlayın.',
    'Google Play will start your 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'Yıllık aboneliği başlattığınızda Google Play 15 günlük ücretsiz denemenizi başlatır. Bu deneme mağaza hesabına bağlıdır, bu nedenle uygulama verilerini silmek denemeyi yeniden başlatmaz.',
    'If your Google Play account is eligible, the store will offer a 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'Google Play hesabınız uygunsa, yıllık aboneliği başlattığınızda mağaza 15 günlük ücretsiz deneme sunar. Bu deneme mağaza hesabına bağlıdır, bu nedenle uygulama verilerini silmek denemeyi yeniden başlatmaz.',
    'After the trial ends, Google Play continues the subscription at {price} per year unless the user cancels in time.':
        'Deneme sona erdikten sonra kullanıcı zamanında iptal etmezse Google Play aboneliği yılda {price} ile sürdürür.',
    'Continue To Access': 'Erişime Devam Et',
    'PRIVATE • TEMPORARY • LOCAL': 'ÖZEL • GEÇİCİ • YEREL',
    'Preparing secure vault experience': 'Güvenli kasa deneyimi hazırlanıyor',
    'Secure session initializing': 'Güvenli oturum başlatılıyor',
    'LOCAL PRIVATE STORAGE': 'YEREL ÖZEL DEPOLAMA',
    'Vault Locked': 'Kasa Kilitli',
    'Authenticating now. If the prompt does not appear, tap below to unlock TempCam.':
        'Doğrulama yapılıyor. İstem görünmezse, TempCam kilidini açmak için aşağıya dokunun.',
    'Biometrics are unavailable on this device. Continue without biometric lock from settings.':
        'Bu cihazda biyometri kullanılamıyor. Ayarlardan biyometrik kilit olmadan devam edin.',
    'Unlocking...': 'Kilidi açılıyor...',
    'Unlock TempCam': 'TempCam Kilidini Aç',
    'Switching camera...': 'Kamera değiştiriliyor...',
    'Default {timer}': 'Varsayılan {timer}',
    'PHOTO': 'FOTOĞRAF',
    'VIDEO': 'VİDEO',
    'Private Preview': 'Özel Önizleme',
    'Tap to view': 'Görüntülemek için dokun',
    'Set Self-Destruct Timer': 'Kendini İmha Zamanlayıcısını Ayarla',
    '7 day timers are available with Premium.':
        '7 günlük zamanlayıcılar Premium ile kullanılabilir.',
    'Choose when this capture evaporates from the vault.':
        'Bu kaydın kasadan ne zaman silineceğini seçin.',
    'Unlock Premium to use the 7 day timer.':
        '7 günlük zamanlayıcıyı kullanmak için Premium kilidini açın.',
    'Apply Timer': 'Zamanlayıcıyı Uygula',
    'Defaults to 24 hours if skipped.':
        'Atlanırsa varsayılan olarak 24 saat kullanılır.',
    'Review this private video before setting its timer.':
        'Zamanlayıcıyı ayarlamadan önce bu özel videoyu gözden geçirin.',
    'Review this private photo before setting its timer.':
        'Zamanlayıcıyı ayarlamadan önce bu özel fotoğrafı gözden geçirin.',
    'Unlock Premium': 'Premium Kilidini Aç',
    'Private Vault': 'Özel Kasa',
    'Expiring in': 'Sürenin Dolmasına',
    'Created': 'Oluşturuldu',
    'Private Video': 'Özel Video',
    'Private Photo': 'Özel Fotoğraf',
    'Extend Timer': 'Zamanlayıcıyı Uzat',
    'Keep Forever': 'Sonsuza Kadar Sakla',
    'Premium Only': 'Yalnızca Premium',
    'Delete Now': 'Şimdi Sil',
    'Media no longer exists.': 'Medya artık mevcut değil.',
    'WELCOME': 'HOŞ GELDİNİZ',
    'CAMERA': 'KAMERA',
    'TIMERS': 'ZAMANLAYICILAR',
    'VAULT': 'KASA',
    'SECURITY': 'GÜVENLİK',
    'SETTINGS': 'AYARLAR',
    'TempCam keeps sensitive captures temporary.':
        'TempCam hassas çekimleri geçici tutar.',
    'Take private photos and videos inside TempCam, keep them out of the main gallery, and let them disappear unless you keep them forever.':
        'Özel fotoğraf ve videoları TempCam içinde çekin, ana galeriden uzak tutun ve sonsuza kadar saklamadığınız sürece kaybolmalarına izin verin.',
    'Capture quickly with the private camera.':
        'Özel kamera ile hızlıca çekim yapın.',
    'Use photo or video mode, tap to focus, pinch to zoom, control flash, and review the private preview before you apply the timer.':
        'Fotoğraf veya video modunu kullanın, odaklamak için dokunun, yakınlaştırmak için kıstırın, flaşı kontrol edin ve zamanlayıcıyı uygulamadan önce özel önizlemeyi gözden geçirin.',
    'Every item gets a self-destruct timer.':
        'Her öğe bir kendini imha zamanlayıcısı alır.',
    'Choose a timer after capture or import. If you skip it, TempCam uses your default timer from Settings.':
        'Çekim veya içe aktarma sonrasında bir zamanlayıcı seçin. Atlarsanız TempCam Ayarlar bölümündeki varsayılan zamanlayıcıyı kullanır.',
    'The vault keeps temp media private first.':
        'Kasa geçici medyayı önce özel tutar.',
    'Browse photos and videos in the private vault, filter by type, import existing media into TempCam, extend timers, or delete items when you need to.':
        'Özel kasadaki fotoğraf ve videolara göz atın, türe göre filtreleyin, mevcut medyayı TempCam içine aktarın, zamanlayıcıları uzatın veya gerektiğinde öğeleri silin.',
    'Biometrics, quick relock, and Panic Exit stay ready.':
        'Biyometri, hızlı yeniden kilitleme ve Panik Çıkış hazır bekler.',
    'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and Panic Exit for faster privacy under pressure.':
        'Baskı altında daha hızlı gizlilik için biyometrik koruma, Oturum Gizlilik Modu, hızlı kilit zaman aşımı, korumalı son uygulamalar önizlemesi ve Panik Çıkış kullanın.',
    'Settings controls reminders, stealth mode, and access.':
        'Ayarlar hatırlatıcıları, gizli modu ve erişimi kontrol eder.',
    'Manage expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.':
        'Sona erme bildirimlerini, gizli bildirim metnini, varsayılan zamanlayıcıları, abonelik erişimini yönetin ve bu turu istediğiniz zaman Ayarlar bölümünden yeniden açın.',
    'APP TOUR': 'UYGULAMA TURU',
    'Skip': 'Geç',
    'Back': 'Geri',
    'Get Started': 'Başlayın',
    'Next': 'İleri',
    'You can skip this now and reopen it any time from Settings.':
        'Bunu şimdi atlayabilir ve istediğiniz zaman Ayarlar bölümünden yeniden açabilirsiniz.',
    'Capture Defaults': 'Çekim Varsayılanları',
    'Default Self-Destruct Timer': 'Varsayılan Kendini İmha Zamanlayıcısı',
    'Choose how long new captures stay available by default.':
        'Yeni çekimlerin varsayılan olarak ne kadar süre kullanılabilir kalacağını seçin.',
    'Expiry Notifications': 'Sona Erme Bildirimleri',
    'Get warned before temporary media disappears.':
        'Geçici medya kaybolmadan önce uyarı alın.',
    'Stealth Notifications': 'Gizli Bildirimler',
    'Hide photo and video wording in reminders for a quieter lock-screen presence.':
        'Daha sade bir kilit ekranı görünümü için hatırlatıcılardaki fotoğraf ve video ifadelerini gizleyin.',
    'Security': 'Güvenlik',
    'Biometric Lock': 'Biyometrik Kilit',
    'Protect app entry and sensitive actions with biometrics.':
        'Uygulamaya girişi ve hassas işlemleri biyometri ile koruyun.',
    'Biometric protection is unavailable on this device.':
        'Bu cihazda biyometrik koruma kullanılamıyor.',
    'Session Privacy Mode': 'Oturum Gizlilik Modu',
    'Lock TempCam immediately whenever the app loses focus.':
        'Uygulama odağını kaybettiğinde TempCam' 'i hemen kilitleyin.',
    'Enable Biometric Lock first to use instant session relocking.':
        'Anında oturum yeniden kilitlemeyi kullanmak için önce Biyometrik Kilit özelliğini etkinleştirin.',
    'Quick Lock Timeout': 'Hızlı Kilit Zaman Aşımı',
    'Session Privacy Mode locks instantly, so timeout is bypassed.':
        'Oturum Gizlilik Modu anında kilitler, bu nedenle zaman aşımı devre dışı kalır.',
    'Choose how long TempCam can stay in the background before it asks for biometrics again.':
        'TempCam’in tekrar biyometri istemeden önce arka planda ne kadar süre kalabileceğini seçin.',
    'Help': 'Yardım',
    'Replay App Tour': 'Uygulama Turunu Tekrar Oynat',
    'Walk through camera, timers, vault, security, and settings again any time.':
        'Kamera, zamanlayıcılar, kasa, güvenlik ve ayarlar bölümlerini istediğiniz zaman yeniden gözden geçirin.',
    'Replay Tour': 'Turu Tekrar Oynat',
    'Why People Use TempCam': 'İnsanlar Neden TempCam Kullanıyor',
    'Temporary by default': 'Varsayılan olarak geçici',
    'Photos and videos auto-delete unless you decide to keep them forever.':
        'Sonsuza kadar saklamaya karar vermediğiniz sürece fotoğraflar ve videolar otomatik olarak silinir.',
    'Private by design': 'Tasarım gereği özel',
    'Temporary captures stay inside TempCam instead of appearing in the main gallery.':
        'Geçici çekimler ana galeride görünmek yerine TempCam içinde kalır.',
    'Fast under pressure': 'Baskı altında hızlı',
    'Panic Exit and quick relocking help when you need privacy right away.':
        'Hemen gizliliğe ihtiyaç duyduğunuzda Panik Çıkış ve hızlı yeniden kilitleme yardımcı olur.',
    'Manage Access': 'Erişimi Yönet',
    'Trusted Vault History': 'Güvenilir Kasa Geçmişi',
    'Local record of exports, deletions, and auto-deletions.':
        'Dışa aktarma, silme ve otomatik silme işlemlerinin yerel kaydı.',
    'Privacy Notes': 'Gizlilik Notları',
    'Temp media stays local to your device until you explicitly keep it forever. Recent-app previews are shielded, and sensitive actions stay protected behind biometric confirmation when enabled.':
        'Geçici medya, siz açıkça sonsuza kadar saklamayı seçene kadar cihazınızda yerel kalır. Son uygulama önizlemeleri korunur ve etkin olduğunda hassas işlemler biyometrik onayın arkasında kalır.',
    'Panic Exit': 'Panik Çıkış',
    'Close TempCam immediately and relock on return.':
        'TempCam’i hemen kapatın ve geri döndüğünüzde yeniden kilitleyin.',
    'Open Camera': 'Kamerayı Aç',
    'Open Vault': 'Kasayı Aç',
    'All': 'Tümü',
    'Photos': 'Fotoğraflar',
    'Videos': 'Videolar',
    'All Media': 'Tüm Medya',
    'Cancel': 'İptal',
    'Delete': 'Sil',
    'Kept Forever': 'Sonsuza Kadar Saklandı',
    'Your vault is empty': 'Kasanız boş',
    'No temp photos yet': 'Henüz geçici fotoğraf yok',
    'No temp videos yet': 'Henüz geçici video yok',
    'Capture a photo or video and it will appear here with its self-destruct timer.':
        'Bir fotoğraf veya video çekin; kendini imha zamanlayıcısıyla burada görünecektir.',
    'This filter only shows temp photos stored inside TempCam.':
        'Bu filtre yalnızca TempCam içinde depolanan geçici fotoğrafları gösterir.',
    'This filter only shows temp videos stored inside TempCam.':
        'Bu filtre yalnızca TempCam içinde depolanan geçici videoları gösterir.',
    'Restore Purchase': 'Satın Alımı Geri Yükle',
    'Privacy Policy': 'Gizlilik Politikası',
    'Terms': 'Koşullar',
    '1 Hour': '1 Saat',
    '3 Hours': '3 Saat',
    '12 Hours': '12 Saat',
    '24 Hours': '24 Saat',
    '3 Days': '3 Gün',
    '7 Days': '7 Gün',
    '5 Seconds': '5 Saniye',
    '15 Seconds': '15 Saniye',
    '30 Seconds': '30 Saniye',
    'Forever': 'Sonsuza Kadar',
    'Expired': 'Süresi Doldu',
    'Start': 'Başlat',
    'Every temporary moment, in one calm vault.':
        'Her geçici anı tek ve sakin bir kasada toplayın.',
    'Browse all temp photos and videos, focus on what is expiring, and clean up quickly when you need to.':
        'Tüm geçici fotoğrafları ve videoları gezin, süresi dolmak üzere olanlara odaklanın ve gerektiğinde hızlıca temizlik yapın.',
    '{count} temp items ready': '{count} geçici öğe hazır',
    'Capture': 'Çekim',
    'Done': 'Bitti',
    'Done ({count})': 'Bitti ({count})',
    'Select': 'Seç',
    'Choose items to delete.': 'Silmek için öğeleri seçin.',
    '{count} items selected for deletion.':
        '{count} öğe silinmek için seçildi.',
    'Expiring Soon': 'Yakında Sona Eriyor',
    '{count} items deleted from TempCam.': '{count} öğe TempCam' 'den silindi.',
    'FREE TRIAL': 'ÜCRETSİZ DENEME',
    'ACTIVE': 'AKTİF',
    'REQUIRED': 'GEREKLİ',
    'Your access is live.': 'Erişiminiz aktif.',
    'Start with 15 days free.': '15 gün ücretsiz başlayın.',
    'Yearly access powers TempCam.': 'Yıllık erişim TempCam' 'i etkinleştirir.',
    'Your current subscription is active through the store.':
        'Mevcut aboneliğiniz mağaza üzerinden aktif.',
    'Access is recorded until {date}.': 'Erişim {date} tarihine kadar kayıtlı.',
    'Google Play or the App Store can start a secure 15-day free trial for eligible accounts before yearly billing begins.':
        'Google Play veya App Store, uygun hesaplar için yıllık ücretlendirme başlamadan önce güvenli 15 günlük ücretsiz deneme başlatabilir.',
    'A {price} yearly subscription keeps TempCam private, temporary, and fully unlocked.':
        '{price} tutarındaki yıllık abonelik TempCam'
            'i özel, geçici ve tamamen açık tutar.',
    'View Yearly Plan': 'Yıllık Planı Gör',
    'View Access Options': 'Erişim Seçeneklerini Gör',
    'LOCAL | TEMPORARY | PROTECTED': 'YEREL | GEÇİCİ | KORUMALI',
    'Keep Forever exports, manual deletions, and auto-deletions will appear here as a local trust log.':
        'Sonsuza Kadar Sakla dışa aktarmaları, manuel silmeler ve otomatik silmeler burada yerel güven günlüğü olarak görünecek.',
    'Payments Disabled Temporarily': 'Ödemeler Geçici Olarak Kapalı',
    'Access Required': 'Erişim Gerekli',
    'Manage TempCam Access': 'TempCam Erişimini Yönet',
    'This build bypasses subscriptions so you can test TempCam on your phone before store upload.':
        'Bu sürüm abonelikleri atlar; böylece TempCam'
            'i mağazaya yüklemeden önce telefonunuzda test edebilirsiniz.',
    'Start the Google Play or App Store managed 15-day free trial, or restore your yearly access to open TempCam.':
        'TempCam'
            'i açmak için Google Play veya App Store yönetimli 15 günlük ücretsiz denemeyi başlatın ya da yıllık erişiminizi geri yükleyin.',
    'Buy or restore yearly access to open TempCam. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'TempCam'
            'i açmak için yıllık erişim satın alın veya geri yükleyin. Mağaza hesabınız uygunsa platform ödeme sırasında 15 günlük ücretsiz denemeyi uygulayabilir.',
    'Your subscription is handled directly by the App Store or Google Play with one yearly plan.':
        'Aboneliğiniz App Store veya Google Play tarafından tek yıllık planla yönetilir.',
    'Start your secure store-managed 15-day free trial, then continue with one yearly plan.':
        'Güvenli mağaza yönetimli 15 günlük ücretsiz denemenizi başlatın, sonra tek yıllık planla devam edin.',
    'Start or restore yearly access. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'Yıllık erişimi başlatın veya geri yükleyin. Mağaza hesabınız uygunsa platform ödeme sırasında 15 günlük ücretsiz deneme uygulayabilir.',
    'PAYMENT OFF': 'ÖDEME KAPALI',
    'YEARLY ACCESS': 'YILLIK ERİŞİM',
    'Payment Disabled For Testing': 'Test İçin Ödemeler Kapalı',
    'Start 15 Days Free': '15 Gün Ücretsiz Başla',
    'Access Active': 'Erişim Aktif',
    'Connecting To Store...': 'Mağazaya Bağlanılıyor...',
    'Buy 1 Year For {price}': '1 Yılı {price} ile Satın Al',
    'Auto-renewing yearly subscription. Cancel anytime in Google Play or App Store subscriptions.':
        'Otomatik yenilenen yıllık abonelik. Google Play veya App Store aboneliklerinden istediğiniz zaman iptal edebilirsiniz.',
    'Store billing is currently bypassed by a temporary app-wide test switch.':
        'Mağaza ödemesi şu anda uygulama genelindeki geçici bir test anahtarıyla atlandı.',
    'If eligible, checkout starts with the store-managed 15-day free trial and then renews yearly.':
        'Uygunsa ödeme, mağazanın yönettiği 15 günlük ücretsiz denemeyle başlar ve sonra yıllık yenilenir.',
    'Your yearly subscription is active.': 'Yıllık aboneliğiniz aktif.',
    'Fallback price shown until the store catalog loads.':
        'Mağaza kataloğu yüklenene kadar yedek fiyat gösterilir.',
    'Directly billed and renewed by the platform store.':
        'Doğrudan platform mağazası tarafından faturalandırılır ve yenilenir.',
    'Annual Access': 'Yıllık Erişim',
    'Testing': 'Test',
    'Trial Then Yearly': 'Deneme Sonra Yıllık',
    'Only Plan': 'Tek Plan',
    'Store Trial': 'Mağaza Denemesi',
    'Yearly Billing': 'Yıllık Faturalama',
    'Secure Access': 'Güvenli Erişim',
    'Restore Support': 'Geri Yükleme Desteği',
    'Access recorded until {date}': 'Erişim {date} tarihine kadar kayıtlı',
    'Camera is unavailable.': 'Kamera kullanılamıyor.',
    'Flash auto': 'Flaş otomatik',
    'Flash on': 'Flaş açık',
    'Flash torch': 'Flaş torch',
    'Flash off': 'Flaş kapalı',
    'Flash is unavailable on this camera.': 'Bu kamerada flaş kullanılamıyor.',
    'Video saved to TempCam': 'Video TempCam' 'e kaydedildi',
    'Recording started': 'Kayıt başladı',
    'Unable to use video recording right now.':
        'Video kaydı şu anda kullanılamıyor.',
    'Video auto-deleted': 'Video otomatik silindi',
    'Photo auto-deleted': 'Fotoğraf otomatik silindi',
    '{media} expired after {timer} and was removed from TempCam.':
        '{media}, {timer} sonunda süresi dolarak TempCam' 'den kaldırıldı.',
    'Finish the current capture before importing media.':
        'Medyayı içe aktarmadan önce mevcut çekimi tamamlayın.',
    '{count} items imported into TempCam, but {failed} original items could not be removed from the main gallery.':
        '{count} öğe TempCam'
            'e aktarıldı ancak {failed} orijinal öğe ana galeriden kaldırılamadı.',
    '{count} items moved into TempCam and removed from the main gallery.':
        '{count} öğe TempCam' 'e taşındı ve ana galeriden kaldırıldı.',
    'Unable to import media right now.': 'Medya şu anda içe aktarılamıyor.',
    'Video deleted now': 'Video şimdi silindi',
    'Photo deleted now': 'Fotoğraf şimdi silindi',
    '{media} removed manually before its timer ended.':
        '{media}, zamanlayıcı bitmeden önce manuel olarak kaldırıldı.',
    'Unable to export this item to the main gallery.':
        'Bu öğe ana galeriye dışa aktarılamadı.',
    'Video kept forever': 'Video sonsuza kadar saklandı',
    'Photo kept forever': 'Fotoğraf sonsuza kadar saklandı',
    '{media} exported to the main gallery and removed from TempCam expiry.':
        '{media} ana galeriye dışa aktarıldı ve TempCam zaman aşımından çıkarıldı.',
    'Video kept forever and exported.':
        'Video sonsuza kadar saklandı ve dışa aktarıldı.',
    'Photo kept forever and exported.':
        'Fotoğraf sonsuza kadar saklandı ve dışa aktarıldı.',
    'Video': 'Video',
    'Photo': 'Fotoğraf',
    'Before release': 'Serbest bırakılmadan önce',
    'Billing': 'Faturalandırma',
    'Disable TEMPCAM_DISABLE_PAYMENTS before uploading to the store.':
        'Mağazaya yüklemeden önce TEMPCAM_DISABLE_PAYMENTS öğesini devre dışı bırakın.',
    'Encrypted Vault': 'Şifreli Kasa',
    'Managing access': 'Erişimi yönetme',
    'Once the subscription or trial is active, TempCam unlocks fully and can re-lock with biometrics.':
        'Abonelik veya deneme etkinleştirildiğinde TempCam kilidi tamamen açılır ve biyometri ile yeniden kilitlenebilir.',
    'One auto-renewing yearly subscription managed directly by Google Play or the App Store.':
        'Doğrudan Google Play veya App Store tarafından yönetilen, otomatik olarak yenilenen bir yıllık abonelik.',
    'Open, capture, review, and protect sensitive moments with fewer steps.':
        'Daha az adımla hassas anları açın, yakalayın, inceleyin ve koruyun.',
    'Payment is charged by Google Play or the App Store at confirmation of purchase. Subscriptions renew automatically unless canceled before the renewal date.':
        'Ödeme, satın alma onayının ardından Google Play veya App Store tarafından tahsil edilir. Abonelikler, yenileme tarihinden önce iptal edilmediği sürece otomatik olarak yenilenir.',
    'Plan': 'Planı',
    'Recover your yearly access from the App Store or Google Play on reinstall.':
        'App Store veya Google Play üzerinden yeniden yükleme yaparak yıllık erişiminizi kurtarın.',
    'Release setup': 'Sürüm kurulumu',
    'Restore request sent to the store.':
        'Mağazaya gönderilen geri yükleme isteği.',
    'Set TEMPCAM_PRIVACY_POLICY_URL during your release build to open your hosted policy page from the app.':
        'Barındırılan politika sayfanızı uygulamadan açmak için sürüm derlemeniz sırasında TEMPCAM_PRIVACY_POLICY_URL değerini ayarlayın.',
    'Set TEMPCAM_SUBSCRIPTION_TERMS_URL during your release build to open your hosted terms page from the app.':
        'Barındırılan şartlar sayfanızı uygulamadan açmak için sürüm derlemeniz sırasında TEMPCAM_SUBSCRIPTION_TERMS_URL değerini ayarlayın.',
    'Subscription Terms': 'Abonelik Koşulları',
    'Temp photos and videos are stored locally on the device inside TempCam until they expire, are deleted, or are kept forever by the user.':
        'Geçici fotoğraflar ve videolar, süreleri dolana, silinene veya kullanıcı tarafından sonsuza kadar saklanana kadar TempCam içindeki cihazda yerel olarak depolanır.',
    'TempCam does not upload your temporary media to a cloud service inside the app flow. Subscription billing is handled by the platform store.':
        'TempCam, geçici medyanızı uygulama akışı içindeki bir bulut hizmetine yüklemez. Abonelik faturalandırması platform mağazası tarafından gerçekleştirilir.',
    'TempCam offers one auto-renewing yearly subscription for access to the app.':
        'TempCam, uygulamaya erişim için otomatik olarak yenilenen bir yıllık abonelik sunar.',
    'The 15-day free trial is managed by Google Play or the App Store, so clearing app data will not restart it.':
        '15 günlük ücretsiz deneme, Google Play veya App Store tarafından yönetildiğinden, uygulama verilerinin temizlenmesi onu yeniden başlatmaz.',
    'Users can restore purchases after reinstall and can manage or cancel subscriptions from their platform subscription settings.':
        'Kullanıcılar satın aldıkları ürünleri yeniden yükledikten sonra geri yükleyebilir ve abonelikleri platform abonelik ayarlarından yönetebilir veya iptal edebilir.',
    'Waiting for store confirmation...': 'Mağaza onayı bekleniyor...',
    'What TempCam does not do': 'TempCam ne yapmaz',
    'What TempCam stores': 'TempCam neleri saklıyor?',
    'Yearly access unlocked. TempCam is ready to use.':
        'Yıllık erişimin kilidi açıldı. TempCam kullanıma hazır.',
    'Your yearly subscription has been restored.':
        'Yıllık aboneliğiniz geri yüklendi.',
    '{days}d {hours}h': '{days}d {hours}h',
    '{hours}h {minutes}m': '{hours}h {minutes}m',
    '{minutes}m': '{minutes}m',
  },
  'zh': {
    'System Default': '跟随系统',
    'Language': '语言',
    'Choose the app language. System Default follows your phone language.':
        '选择应用语言。“跟随系统”会使用手机语言。',
    'Press back again to exit TempCam': '再按一次返回即可退出 TempCam',
    'Protected Preview': '受保护预览',
    '15 DAYS FREE': '免费 15 天',
    'Start with a secure free trial.': '先开始安全免费试用。',
    'Continue To Access': '继续进入',
    'PRIVATE • TEMPORARY • LOCAL': '私密 • 临时 • 本地',
    'Preparing secure vault experience': '正在准备安全保险库体验',
    'Secure session initializing': '正在初始化安全会话',
    'Vault Locked': '保险库已锁定',
    'Unlocking...': '正在解锁...',
    'Unlock TempCam': '解锁 TempCam',
    'Switching camera...': '正在切换摄像头...',
    'Default {timer}': '默认 {timer}',
    'PHOTO': '照片',
    'VIDEO': '视频',
    'Tap to view': '点击查看',
    'Set Self-Destruct Timer': '设置自毁计时器',
    'Apply Timer': '应用计时器',
    'Private Vault': '私密保险库',
    'Expiring in': '剩余时间',
    'Created': '创建时间',
    'Private Video': '私密视频',
    'Private Photo': '私密照片',
    'Extend Timer': '延长计时器',
    'Keep Forever': '永久保留',
    'Delete Now': '立即删除',
    'Skip': '跳过',
    'Back': '返回',
    'Get Started': '开始使用',
    'Next': '下一步',
    'Capture Defaults': '拍摄默认值',
    'Security': '安全',
    'Help': '帮助',
    'Manage Access': '管理访问权限',
    'Open Camera': '打开相机',
    'Open Vault': '打开保险库',
    'All': '全部',
    'Photos': '照片',
    'Videos': '视频',
    'Cancel': '取消',
    'Delete': '删除',
    'Restore Purchase': '恢复购买',
    'Privacy Policy': '隐私政策',
    'Terms': '条款',
    '1 Hour': '1 小时',
    '3 Hours': '3 小时',
    '12 Hours': '12 小时',
    '24 Hours': '24 小时',
    '3 Days': '3 天',
    '7 Days': '7 天',
    '5 Seconds': '5 秒',
    '15 Seconds': '15 秒',
    '30 Seconds': '30 秒',
    'Forever': '永久',
    'Expired': '已过期',
    'Capture': '拍摄',
    'Done': '完成',
    'Select': '选择',
    'FREE TRIAL': '免费试用',
    'ACTIVE': '已激活',
    'REQUIRED': '必需',
    'Start 15 Days Free': '开始 15 天免费试用',
    'Camera is unavailable.': '相机不可用。',
    'Flash auto': '闪光灯自动',
    'Flash on': '闪光灯开',
    'Flash torch': '闪光灯常亮',
    'Flash off': '闪光灯关',
    'Video': '视频',
    'Photo': '照片',
    '7 day timers are available with Premium.': 'Premium 提供 7 天计时器。',
    'A {price} yearly subscription keeps TempCam private, temporary, and fully unlocked.':
        '{price} 每年订阅可以使 TempCam 保持私有、临时且完全解锁。',
    'APP TOUR': '应用之旅',
    'Access Active': '访问活跃',
    'Access Required': '需要访问',
    'Access is recorded until {date}.': '访问被记录到 {date}。',
    'Access recorded until {date}': '访问记录直至 {date}',
    'After the trial ends, Google Play continues the subscription at {price} per year unless the user cancels in time.':
        '试用结束后，Google Play 继续按每年 {price} 订阅，除非用户及时取消。',
    'All Media': '所有媒体',
    'Annual Access': '每年访问',
    'Authenticating now. If the prompt does not appear, tap below to unlock TempCam.':
        '现在正在认证。如果未出现提示，请点击下方解锁 TempCam。',
    'Auto-renewing yearly subscription. Cancel anytime in Google Play or App Store subscriptions.':
        '每年自动续订订阅。随时取消 Google Play 或 App Store 订阅。',
    'Before release': '发布前',
    'Billing': '计费',
    'Biometric Lock': '生物识别锁',
    'Biometric protection is unavailable on this device.': '此设备上不提供生物识别保护。',
    'Biometrics are unavailable on this device. Continue without biometric lock from settings.':
        '该设备无法使用生物识别功能。继续，无需从设置中进行生物识别锁定。',
    'Biometrics, quick relock, and Panic Exit stay ready.':
        '生物识别、快速重新锁定和紧急退出已做好准备。',
    'Browse all temp photos and videos, focus on what is expiring, and clean up quickly when you need to.':
        '浏览所有临时照片和视频，重点关注即将过期的内容，并在需要时快速清理。',
    'Browse photos and videos in the private vault, filter by type, import existing media into TempCam, extend timers, or delete items when you need to.':
        '浏览私人保管库中的照片和视频、按类型过滤、将现有媒体导入 TempCam、延长计时器或在需要时删除项目。',
    'Buy 1 Year For {price}': '购买 1 年 {price}',
    'Buy or restore yearly access to open TempCam. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        '购买或恢复每年开放 TempCam 的访问权限。如果您的商店账户符合条件，平台可能会在结帐时申请 15 天免费试用。',
    'CAMERA': '相机',
    'Capture a photo or video and it will appear here with its self-destruct timer.':
        '拍摄照片或视频后，它会出现在此处并带有自毁计时器。',
    'Capture quickly with the private camera.': '使用私人相机快速捕捉。',
    'Choose a timer after capture or import. If you skip it, TempCam uses your default timer from Settings.':
        '捕获或导入后选择计时器。如果您跳过它，TempCam 将使用“设置”中的默认计时器。',
    'Choose how long TempCam can stay in the background before it asks for biometrics again.':
        '选择 TempCam 在再次要求生物识别信息之前可以在后台停留多长时间。',
    'Choose how long new captures stay available by default.':
        '选择默认情况下新捕获可用的时间长度。',
    'Choose items to delete.': '选择要删除的项目。',
    'Choose when this capture evaporates from the vault.': '选择此捕获物何时从保管库中消失。',
    'Close TempCam immediately and relock on return.':
        '立即关闭 TempCam 并在返回时重新锁定。',
    'Connecting To Store...': '正在连接到商店...',
    'Default Self-Destruct Timer': '默认自毁计时器',
    'Defaults to 24 hours if skipped.': '如果跳过，则默认为 24​​ 小时。',
    'Directly billed and renewed by the platform store.': '由平台商店直接计费和续订。',
    'Disable TEMPCAM_DISABLE_PAYMENTS before uploading to the store.':
        '在上传到商店之前禁用 TEMPCAM_DISABLE_PAYMENTS。',
    'Done ({count})': '完成 ({count})',
    'Enable Biometric Lock first to use instant session relocking.':
        '首先启用生物识别锁定以使用即时会话重新锁定。',
    'Encrypted Vault': '加密金库',
    'Every item gets a self-destruct timer.': '每个物品都有一个自毁计时器。',
    'Every temporary moment, in one calm vault.': '每一个短暂的时刻，都在一个平静的地窖里。',
    'Expiring Soon': '即将到期',
    'Expiry Notifications': '到期通知',
    'Fallback price shown until the store catalog loads.': '在商店目录加载之前显示回退价格。',
    'Fast under pressure': '压力下速度快',
    'Finish the current capture before importing media.': '在导入媒体之前完成当前捕获。',
    'Flash is unavailable on this camera.': '该相机不支持闪光灯。',
    'Get warned before temporary media disappears.': '在临时媒体消失之前收到警告。',
    'Google Play or the App Store can start a secure 15-day free trial for eligible accounts before yearly billing begins.':
        'Google Play 或 App Store 可以在年度计费开始之前为符合条件的帐户启动为期 15 天的安全免费试用。',
    'Google Play will start your 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        '当您开始每年订阅时，Google Play 将开始 15 天的免费试用。此试用版与商店帐户绑定，因此清除应用程序数据不会重新启动它。',
    'Hide photo and video wording in reminders for a quieter lock-screen presence.':
        '隐藏提醒中的照片和视频文字，以获得更安静的锁屏状态。',
    'If eligible, checkout starts with the store-managed 15-day free trial and then renews yearly.':
        '如果符合条件，结帐将从商店管理的 15 天免费试用开始，然后每年续订。',
    'If your Google Play account is eligible, the store will offer a 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        '如果您的 Google Play 帐户符合条件，商店将在您开始年度订阅时提供 15 天的免费试用。此试用版与商店帐户绑定，因此清除应用程序数据不会重新启动它。',
    'Keep Forever exports, manual deletions, and auto-deletions will appear here as a local trust log.':
        'Keep Forever 导出、手动删除和自动删除将作为本地信任日志显示在此处。',
    'Kept Forever': '永远保留',
    'LOCAL PRIVATE STORAGE': '本地私有存储',
    'LOCAL | TEMPORARY | PROTECTED': '本地|临时|受保护',
    'Local record of exports, deletions, and auto-deletions.':
        '导出、删除和自动删除的本地记录。',
    'Lock TempCam immediately whenever the app loses focus.':
        '每当应用程序失去焦点时立即锁定 TempCam。',
    'Manage TempCam Access': '管理 TempCam 访问',
    'Manage expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.':
        '管理到期通知、隐形通知措辞、默认计时器、订阅访问，并随时从“设置”重新打开此游览。',
    'Managing access': '管理访问',
    'Media no longer exists.': '媒体不再存在。',
    'No temp photos yet': '还没有临时照片',
    'No temp videos yet': '还没有临时视频',
    'Once the subscription or trial is active, TempCam unlocks fully and can re-lock with biometrics.':
        '一旦订阅或试用生效，TempCam 就会完全解锁，并可以通过生物识别技术重新锁定。',
    'One auto-renewing yearly subscription managed directly by Google Play or the App Store.':
        '由 Google Play 或 App Store 直接管理的一项自动续订年度订阅。',
    'Only Plan': '唯一计划',
    'Open, capture, review, and protect sensitive moments with fewer steps.':
        '通过更少的步骤打开、捕捉、查看和保护敏感时刻。',
    'PAYMENT OFF': '付款折扣',
    'Panic Exit': '紧急退出',
    'Panic Exit and quick relocking help when you need privacy right away.':
        '当您立即需要隐私时，紧急退出和快速重新锁定会有所帮助。',
    'Payment Disabled For Testing': '测试时禁用付款',
    'Payment is charged by Google Play or the App Store at confirmation of purchase. Subscriptions renew automatically unless canceled before the renewal date.':
        '付款由 Google Play 或 App Store 在确认购买时收取。订阅会自动续订，除非在续订日期之前取消。',
    'Payments Disabled Temporarily': '暂时停止付款',
    'Photo auto-deleted': '照片自动删除',
    'Photo deleted now': '照片现已删除',
    'Photo kept forever': '照片永久保存',
    'Photo kept forever and exported.': '照片永久保存并导出。',
    'Photos and videos auto-delete unless you decide to keep them forever.':
        '照片和视频会自动删除，除非您决定永久保留它们。',
    'Plan': '计划',
    'Premium Only': '仅限高级版',
    'Privacy Notes': '隐私说明',
    'Private Preview': '私人预览',
    'Private by design': '私人设计',
    'Protect app entry and sensitive actions with biometrics.':
        '使用生物识别技术保护应用程序进入和敏感操作。',
    'Quick Lock Timeout': '快速锁定超时',
    'Recording started': '录音开始',
    'Recover your yearly access from the App Store or Google Play on reinstall.':
        '重新安装时从 App Store 或 Google Play 恢复您的年度访问权限。',
    'Release setup': '发布设置',
    'Replay App Tour': '重播应用之旅',
    'Replay Tour': '重播之旅',
    'Restore Support': '恢复支持',
    'Restore request sent to the store.': '恢复请求发送到商店。',
    'Review this private photo before setting its timer.': '在设置计时器之前查看这张私人照片。',
    'Review this private video before setting its timer.': '在设置计时器之前查看此私人视频。',
    'SECURITY': '安全',
    'SETTINGS': '设置',
    'Secure Access': '安全访问',
    'Session Privacy Mode': '会话隐私模式',
    'Session Privacy Mode locks instantly, so timeout is bypassed.':
        '会话隐私模式会立即锁定，因此可以绕过超时。',
    'Set TEMPCAM_PRIVACY_POLICY_URL during your release build to open your hosted policy page from the app.':
        '在发布版本期间设置 TEMPCAM_PRIVACY_POLICY_URL 以从应用程序打开托管策略页面。',
    'Set TEMPCAM_SUBSCRIPTION_TERMS_URL during your release build to open your hosted terms page from the app.':
        '在发布版本期间设置 TEMPCAM_SUBSCRIPTION_TERMS_URL 以从应用程序打开托管条款页面。',
    'Settings controls reminders, stealth mode, and access.': '设置控制提醒、隐身模式和访问。',
    'Start': '开始',
    'Start or restore yearly access. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        '开始或恢复按年访问。如果您的商店账户符合条件，平台可能会在结帐时申请 15 天免费试用。',
    'Start the Google Play or App Store managed 15-day free trial, or restore your yearly access to open TempCam.':
        '开始 Google Play 或 App Store 管理的 15 天免费试用，或恢复您的年度访问权限以开放 TempCam。',
    'Start with 15 days free.': '从 15 天免费开始。',
    'Start your secure store-managed 15-day free trial, then continue with one yearly plan.':
        '开始由商店管理的安全 15 天免费试用，然后继续执行一年计划。',
    'Stealth Notifications': '隐形通知',
    'Store Trial': '商店试用',
    'Store billing is currently bypassed by a temporary app-wide test switch.':
        '目前，商店计费已被临时应用程序范围的测试开关绕过。',
    'Subscription Terms': '订阅条款',
    'TIMERS': '定时器',
    'Take private photos and videos inside TempCam, keep them out of the main gallery, and let them disappear unless you keep them forever.':
        '在 TempCam 内拍摄私人照片和视频，将它们保留在主图库之外，并让它们消失，除非您永远保留它们。',
    'Temp media stays local to your device until you explicitly keep it forever. Recent-app previews are shielded, and sensitive actions stay protected behind biometric confirmation when enabled.':
        '临时媒体保留在您的设备本地，直到您明确永久保留它。最近的应用程序预览会被屏蔽，敏感操作在启用后会在生物识别确认后受到保护。',
    'Temp photos and videos are stored locally on the device inside TempCam until they expire, are deleted, or are kept forever by the user.':
        '临时照片和视频存储在设备本地的 TempCam 内，直到过期、被删除或被用户永久保留。',
    'TempCam does not upload your temporary media to a cloud service inside the app flow. Subscription billing is handled by the platform store.':
        'TempCam 不会将您的临时媒体上传到应用程序流程内的云服务。订阅计费由平台商店处理。',
    'TempCam keeps sensitive captures temporary.': 'TempCam 暂时保留敏感捕获。',
    'TempCam offers one auto-renewing yearly subscription for access to the app.':
        'TempCam 提供一项自动续订的年度订阅来访问该应用程序。',
    'Temporary by default': '默认为临时',
    'Temporary captures stay inside TempCam instead of appearing in the main gallery.':
        '临时捕获保留在 TempCam 内，而不是出现在主画廊中。',
    'Testing': '测试',
    'The 15-day free trial is managed by Google Play or the App Store, so clearing app data will not restart it.':
        '15 天免费试用由 Google Play 或 App Store 管理，因此清除应用程序数据不会重新启动它。',
    'The vault keeps temp media private first.': '保险库首先保持临时媒体的私密性。',
    'This build bypasses subscriptions so you can test TempCam on your phone before store upload.':
        '此版本绕过订阅，因此您可以在商店上传之前在手机上测试 TempCam。',
    'This filter only shows temp photos stored inside TempCam.':
        '此过滤器仅显示存储在 TempCam 中的临时照片。',
    'This filter only shows temp videos stored inside TempCam.':
        '此过滤器仅显示存储在 TempCam 中的临时视频。',
    'Trial Then Yearly': '试用然后每年',
    'Trusted Vault History': '可信保管库历史记录',
    'Unable to export this item to the main gallery.': '无法将此项目导出到主图库。',
    'Unable to import media right now.': '目前无法导入媒体。',
    'Unable to use video recording right now.': '目前无法使用视频录制。',
    'Unlock Premium': '解锁高级版',
    'Unlock Premium to use the 7 day timer.': '解锁高级版以使用 7 天计时器。',
    'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and Panic Exit for faster privacy under pressure.':
        '使用生物识别保护、会话隐私模式、快速锁定超时、受保护的最近预览和紧急退出，在压力下更快地保护隐私。',
    'Use photo or video mode, tap to focus, pinch to zoom, control flash, and review the private preview before you apply the timer.':
        '使用照片或视频模式、点击对焦、捏合缩放、控制闪光灯以及在应用计时器之前查看私人预览。',
    'Users can restore purchases after reinstall and can manage or cancel subscriptions from their platform subscription settings.':
        '用户可以在重新安装后恢复购买，并可以从其平台订阅设置管理或取消订阅。',
    'VAULT': '保险库',
    'Video auto-deleted': '视频自动删除',
    'Video deleted now': '视频现已删除',
    'Video kept forever': '视频永久保存',
    'Video kept forever and exported.': '视频永久保存并导出。',
    'Video saved to TempCam': '视频保存到 TempCam',
    'View Access Options': '查看访问选项',
    'View Yearly Plan': '查看年度计划',
    'WELCOME': '欢迎',
    'Waiting for store confirmation...': '等待店铺确认...',
    'Walk through camera, timers, vault, security, and settings again any time.':
        '随时再次浏览摄像头、计时器、保险库、安全性和设置。',
    'What TempCam does not do': 'TempCam 不做什么',
    'What TempCam stores': 'TempCam 存储什么',
    'Why People Use TempCam': '人们为什么使用 TempCam',
    'YEARLY ACCESS': '每年访问',
    'Yearly Billing': '按年计费',
    'Yearly access powers TempCam.': '每年的访问权限TempCam。',
    'Yearly access unlocked. TempCam is ready to use.':
        '年度访问权限已解锁。 TempCam 可供使用。',
    'You can skip this now and reopen it any time from Settings.':
        '您现在可以跳过此操作，并随时从“设置”中重新打开它。',
    'Your access is live.': '您的访问是实时的。',
    'Your current subscription is active through the store.': '您当前的订阅已通过商店激活。',
    'Your subscription is handled directly by the App Store or Google Play with one yearly plan.':
        '您的订阅由 App Store 或 Google Play 直接处理，并包含一年计划。',
    'Your vault is empty': '你的金库是空的',
    'Your yearly subscription has been restored.': '您的年度订阅已恢复。',
    'Your yearly subscription is active.': '您的年度订阅已激活。',
    '{count} items deleted from TempCam.': '从 TempCam 中删除了 {count} 项。',
    '{count} items imported into TempCam, but {failed} original items could not be removed from the main gallery.':
        '{count} 项目已导入 TempCam，但 {failed} 原始项目无法从主图库中删除。',
    '{count} items moved into TempCam and removed from the main gallery.':
        '{count} 项目移至 TempCam 并从主画廊中删除。',
    '{count} items selected for deletion.': '选择删除 {count} 项。',
    '{count} temp items ready': '{count} 临时物品准备就绪',
    '{days}d {hours}h': '{days}d {hours}h',
    '{hours}h {minutes}m': '{hours}h {minutes}m',
    '{media} expired after {timer} and was removed from TempCam.':
        '{media} 在 {timer} 之后过期并从 TempCam 中删除。',
    '{media} exported to the main gallery and removed from TempCam expiry.':
        '{media} 导出到主图库并从 TempCam 到期中删除。',
    '{media} removed manually before its timer ended.': '{media} 在计时器结束之前手动删除。',
    '{minutes}m': '{minutes}米',
  },
  'es': {
    'System Default': 'Predeterminado del sistema',
    'Language': 'Idioma',
    'Choose the app language. System Default follows your phone language.':
        'Elige el idioma de la app. Predeterminado del sistema sigue el idioma del telefono.',
    'Press back again to exit TempCam':
        'Pulsa atras otra vez para salir de TempCam',
    'Protected Preview': 'Vista protegida',
    '15 DAYS FREE': '15 DIAS GRATIS',
    'Start with a secure free trial.':
        'Empieza con una prueba gratuita segura.',
    'Continue To Access': 'Continuar',
    'PRIVATE • TEMPORARY • LOCAL': 'PRIVADO • TEMPORAL • LOCAL',
    'Preparing secure vault experience': 'Preparando la caja fuerte segura',
    'Secure session initializing': 'Iniciando sesion segura',
    'Vault Locked': 'Caja bloqueada',
    'Unlocking...': 'Desbloqueando...',
    'Unlock TempCam': 'Desbloquear TempCam',
    'Switching camera...': 'Cambiando camara...',
    'PHOTO': 'FOTO',
    'VIDEO': 'VIDEO',
    'Tap to view': 'Toca para ver',
    'Set Self-Destruct Timer': 'Configurar temporizador',
    'Apply Timer': 'Aplicar temporizador',
    'Private Vault': 'Caja privada',
    'Expiring in': 'Caduca en',
    'Created': 'Creado',
    'Private Video': 'Video privado',
    'Private Photo': 'Foto privada',
    'Extend Timer': 'Extender temporizador',
    'Keep Forever': 'Guardar para siempre',
    'Delete Now': 'Eliminar ahora',
    'Skip': 'Omitir',
    'Back': 'Atras',
    'Get Started': 'Comenzar',
    'Next': 'Siguiente',
    'Capture Defaults': 'Valores de captura',
    'Security': 'Seguridad',
    'Help': 'Ayuda',
    'Manage Access': 'Gestionar acceso',
    'Open Camera': 'Abrir camara',
    'Open Vault': 'Abrir caja',
    'All': 'Todo',
    'Photos': 'Fotos',
    'Videos': 'Videos',
    'Cancel': 'Cancelar',
    'Delete': 'Eliminar',
    'Restore Purchase': 'Restaurar compra',
    'Privacy Policy': 'Politica de privacidad',
    'Terms': 'Terminos',
    '1 Hour': '1 hora',
    '3 Hours': '3 horas',
    '12 Hours': '12 horas',
    '24 Hours': '24 horas',
    '3 Days': '3 dias',
    '7 Days': '7 dias',
    '5 Seconds': '5 segundos',
    '15 Seconds': '15 segundos',
    '30 Seconds': '30 segundos',
    'Forever': 'Para siempre',
    'Expired': 'Caducado',
    'Capture': 'Capturar',
    'Done': 'Listo',
    'Select': 'Seleccionar',
    'FREE TRIAL': 'PRUEBA GRATIS',
    'ACTIVE': 'ACTIVO',
    'REQUIRED': 'REQUERIDO',
    'Start 15 Days Free': 'Empezar 15 dias gratis',
    'Camera is unavailable.': 'La camara no esta disponible.',
    'Flash auto': 'Flash automatico',
    'Flash on': 'Flash encendido',
    'Flash torch': 'Flash antorcha',
    'Flash off': 'Flash apagado',
    'Video': 'Video',
    'Photo': 'Foto',
    '7 day timers are available with Premium.':
        'Los temporizadores de 7 días están disponibles con Premium.',
    'A {price} yearly subscription keeps TempCam private, temporary, and fully unlocked.':
        'Una suscripción anual {price} mantiene a TempCam privado, temporal y completamente desbloqueado.',
    'APP TOUR': 'RECORRIDO DE LA APLICACIÓN',
    'Access Active': 'Acceso Activo',
    'Access Required': 'Acceso requerido',
    'Access is recorded until {date}.':
        'El acceso queda registrado hasta el {date}.',
    'Access recorded until {date}': 'Acceso registrado hasta el {date}',
    'After the trial ends, Google Play continues the subscription at {price} per year unless the user cancels in time.':
        'Una vez finalizada la prueba, Google Play continúa la suscripción a {price} por año a menos que el usuario la cancele a tiempo.',
    'All Media': 'Todos los medios',
    'Annual Access': 'Acceso Anual',
    'Authenticating now. If the prompt does not appear, tap below to unlock TempCam.':
        'Autenticándose ahora. Si el mensaje no aparece, toque a continuación para desbloquear TempCam.',
    'Auto-renewing yearly subscription. Cancel anytime in Google Play or App Store subscriptions.':
        'Suscripción anual de renovación automática. Cancele en cualquier momento en Google Play o App Store suscripciones.',
    'Before release': 'Antes del lanzamiento',
    'Billing': 'Facturación',
    'Biometric Lock': 'Cerradura biométrica',
    'Biometric protection is unavailable on this device.':
        'La protección biométrica no está disponible en este dispositivo.',
    'Biometrics are unavailable on this device. Continue without biometric lock from settings.':
        'Los datos biométricos no están disponibles en este dispositivo. Continuar sin bloqueo biométrico desde ajustes.',
    'Biometrics, quick relock, and Panic Exit stay ready.':
        'La biometría, el rebloqueo rápido y la salida de pánico permanecen listos.',
    'Browse all temp photos and videos, focus on what is expiring, and clean up quickly when you need to.':
        'Explora todas las fotos y vídeos temporales, concéntrate en lo que está por caducar y limpia rápidamente cuando sea necesario.',
    'Browse photos and videos in the private vault, filter by type, import existing media into TempCam, extend timers, or delete items when you need to.':
        'Explore fotos y videos en la bóveda privada, filtre por tipo, importe medios existentes en TempCam, extienda los temporizadores o elimine elementos cuando sea necesario.',
    'Buy 1 Year For {price}': 'Compre 1 año por {price}',
    'Buy or restore yearly access to open TempCam. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'Compre o restaure el acceso anual para abrir TempCam. Si la cuenta de su tienda es elegible, la plataforma puede aplicar la prueba gratuita de 15 días durante el proceso de pago.',
    'CAMERA': 'CÁMARA',
    'Capture a photo or video and it will appear here with its self-destruct timer.':
        'Captura una foto o un vídeo y aparecerá aquí con su temporizador de autodestrucción.',
    'Capture quickly with the private camera.':
        'Capture rápidamente con la cámara privada.',
    'Choose a timer after capture or import. If you skip it, TempCam uses your default timer from Settings.':
        'Elija un temporizador después de la captura o importación. Si lo omite, TempCam usa su temporizador predeterminado desde Configuración.',
    'Choose how long TempCam can stay in the background before it asks for biometrics again.':
        'Elija cuánto tiempo puede permanecer TempCam en segundo plano antes de que vuelva a solicitar datos biométricos.',
    'Choose how long new captures stay available by default.':
        'Elija cuánto tiempo permanecerán disponibles las nuevas capturas de forma predeterminada.',
    'Choose items to delete.': 'Elija elementos para eliminar.',
    'Choose when this capture evaporates from the vault.':
        'Elige cuándo esta captura se evapora de la bóveda.',
    'Close TempCam immediately and relock on return.':
        'Cierre TempCam inmediatamente y vuelva a bloquearlo al regresar.',
    'Connecting To Store...': 'Conectándose a la tienda...',
    'Default Self-Destruct Timer':
        'Temporizador de autodestrucción predeterminado',
    'Default {timer}': 'Predeterminado {timer}',
    'Defaults to 24 hours if skipped.':
        'El valor predeterminado es 24 horas si se omite.',
    'Directly billed and renewed by the platform store.':
        'Facturado y renovado directamente por la tienda de la plataforma.',
    'Disable TEMPCAM_DISABLE_PAYMENTS before uploading to the store.':
        'Deshabilite TEMPCAM_DISABLE_PAYMENTS antes de cargarlo en la tienda.',
    'Done ({count})': 'Hecho ({count})',
    'Enable Biometric Lock first to use instant session relocking.':
        'Habilite primero el bloqueo biométrico para utilizar el bloqueo instantáneo de sesión.',
    'Encrypted Vault': 'Bóveda cifrada',
    'Every item gets a self-destruct timer.':
        'Cada elemento tiene un temporizador de autodestrucción.',
    'Every temporary moment, in one calm vault.':
        'Cada momento temporal, en una bóveda tranquila.',
    'Expiring Soon': 'Expira pronto',
    'Expiry Notifications': 'Notificaciones de vencimiento',
    'Fallback price shown until the store catalog loads.':
        'El precio alternativo se muestra hasta que se carga el catálogo de la tienda.',
    'Fast under pressure': 'Rápido bajo presión',
    'Finish the current capture before importing media.':
        'Finalice la captura actual antes de importar medios.',
    'Flash is unavailable on this camera.':
        'El flash no está disponible en esta cámara.',
    'Get warned before temporary media disappears.':
        'Reciba una advertencia antes de que desaparezcan los medios temporales.',
    'Google Play or the App Store can start a secure 15-day free trial for eligible accounts before yearly billing begins.':
        'Google Play o App Store pueden iniciar una prueba gratuita segura de 15 días para cuentas elegibles antes de que comience la facturación anual.',
    'Google Play will start your 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'Google Play comenzará su prueba gratuita de 15 días cuando comience la suscripción anual. Esta prueba está vinculada a la cuenta de la tienda, por lo que borrar los datos de la aplicación no la reiniciará.',
    'Hide photo and video wording in reminders for a quieter lock-screen presence.':
        'Oculte textos de fotos y videos en recordatorios para una presencia más silenciosa en la pantalla de bloqueo.',
    'If eligible, checkout starts with the store-managed 15-day free trial and then renews yearly.':
        'Si es elegible, el pago comienza con la prueba gratuita de 15 días administrada por la tienda y luego se renueva anualmente.',
    'If your Google Play account is eligible, the store will offer a 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'Si su cuenta Google Play es elegible, la tienda le ofrecerá una prueba gratuita de 15 días cuando comience la suscripción anual. Esta prueba está vinculada a la cuenta de la tienda, por lo que borrar los datos de la aplicación no la reiniciará.',
    'Keep Forever exports, manual deletions, and auto-deletions will appear here as a local trust log.':
        'Las exportaciones, eliminaciones manuales y eliminaciones automáticas de Keep Forever aparecerán aquí como un registro de confianza local.',
    'Kept Forever': 'Mantenido para siempre',
    'LOCAL PRIVATE STORAGE': 'ALMACENAJE PRIVADO LOCAL',
    'LOCAL | TEMPORARY | PROTECTED': 'LOCALES | TEMPORAL | PROTEGIDO',
    'Local record of exports, deletions, and auto-deletions.':
        'Registro local de exportaciones, eliminaciones y autoeliminaciones.',
    'Lock TempCam immediately whenever the app loses focus.':
        'Bloquee TempCam inmediatamente cuando la aplicación pierda el foco.',
    'Manage TempCam Access': 'Administrar acceso TempCam',
    'Manage expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.':
        'Administre las notificaciones de vencimiento, la redacción de las notificaciones ocultas, los temporizadores predeterminados, el acceso a la suscripción y vuelva a abrir este recorrido en cualquier momento desde Configuración.',
    'Managing access': 'Gestionar el acceso',
    'Media no longer exists.': 'Los medios ya no existen.',
    'No temp photos yet': 'Aún no hay fotos temporales',
    'No temp videos yet': 'Aún no hay vídeos temporales',
    'Once the subscription or trial is active, TempCam unlocks fully and can re-lock with biometrics.':
        'Una vez que la suscripción o prueba está activa, TempCam se desbloquea completamente y puede volver a bloquearse con datos biométricos.',
    'One auto-renewing yearly subscription managed directly by Google Play or the App Store.':
        'Una suscripción anual de renovación automática administrada directamente por Google Play o App Store.',
    'Only Plan': 'Sólo plan',
    'Open, capture, review, and protect sensitive moments with fewer steps.':
        'Abra, capture, revise y proteja momentos delicados con menos pasos.',
    'PAYMENT OFF': 'PAGO APAGADO',
    'Panic Exit': 'Salida de pánico',
    'Panic Exit and quick relocking help when you need privacy right away.':
        'La salida de pánico y el rebloqueo rápido ayudan cuando necesita privacidad de inmediato.',
    'Payment Disabled For Testing': 'Pago deshabilitado para pruebas',
    'Payment is charged by Google Play or the App Store at confirmation of purchase. Subscriptions renew automatically unless canceled before the renewal date.':
        'El pago se cobra mediante Google Play o App Store en la confirmación de la compra. Las suscripciones se renuevan automáticamente a menos que se cancelen antes de la fecha de renovación.',
    'Payments Disabled Temporarily': 'Pagos deshabilitados temporalmente',
    'Photo auto-deleted': 'Foto eliminada automáticamente',
    'Photo deleted now': 'Foto eliminada ahora',
    'Photo kept forever': 'Foto guardada para siempre.',
    'Photo kept forever and exported.':
        'Foto guardada para siempre y exportada.',
    'Photos and videos auto-delete unless you decide to keep them forever.':
        'Las fotos y los vídeos se eliminan automáticamente a menos que decidas conservarlos para siempre.',
    'Plan': 'Plan',
    'Premium Only': 'Sólo Premium',
    'Privacy Notes': 'Notas de privacidad',
    'Private Preview': 'Vista previa privada',
    'Private by design': 'Privado por diseño',
    'Protect app entry and sensitive actions with biometrics.':
        'Proteja el acceso a aplicaciones y acciones sensibles con datos biométricos.',
    'Quick Lock Timeout': 'Tiempo de espera de bloqueo rápido',
    'Recording started': 'Grabación iniciada',
    'Recover your yearly access from the App Store or Google Play on reinstall.':
        'Recupere su acceso anual desde App Store o Google Play al reinstalar.',
    'Release setup': 'Configuración de lanzamiento',
    'Replay App Tour': 'Repetir recorrido por la aplicación',
    'Replay Tour': 'Gira de repetición',
    'Restore Support': 'Restaurar soporte',
    'Restore request sent to the store.':
        'Solicitud de restauración enviada a la tienda.',
    'Review this private photo before setting its timer.':
        'Revise esta foto privada antes de configurar el temporizador.',
    'Review this private video before setting its timer.':
        'Revise este video privado antes de configurar el temporizador.',
    'SECURITY': 'SEGURIDAD',
    'SETTINGS': 'AJUSTES',
    'Secure Access': 'Acceso seguro',
    'Session Privacy Mode': 'Modo de privacidad de sesión',
    'Session Privacy Mode locks instantly, so timeout is bypassed.':
        'El modo de privacidad de sesión se bloquea instantáneamente, por lo que se omite el tiempo de espera.',
    'Set TEMPCAM_PRIVACY_POLICY_URL during your release build to open your hosted policy page from the app.':
        'Configure TEMPCAM_PRIVACY_POLICY_URL durante la compilación de su lanzamiento para abrir su página de política alojada desde la aplicación.',
    'Set TEMPCAM_SUBSCRIPTION_TERMS_URL during your release build to open your hosted terms page from the app.':
        'Configure TEMPCAM_SUBSCRIPTION_TERMS_URL durante la compilación de su lanzamiento para abrir su página de términos alojados desde la aplicación.',
    'Settings controls reminders, stealth mode, and access.':
        'La configuración controla los recordatorios, el modo oculto y el acceso.',
    'Start': 'Comenzar',
    'Start or restore yearly access. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'Iniciar o restaurar el acceso anual. Si la cuenta de su tienda es elegible, la plataforma puede aplicar la prueba gratuita de 15 días durante el proceso de pago.',
    'Start the Google Play or App Store managed 15-day free trial, or restore your yearly access to open TempCam.':
        'Inicie la prueba gratuita administrada de 15 días de Google Play o App Store o restaure su acceso anual para abrir TempCam.',
    'Start with 15 days free.': 'Comienza con 15 días gratis.',
    'Start your secure store-managed 15-day free trial, then continue with one yearly plan.':
        'Comience su prueba gratuita de 15 días administrada de forma segura en la tienda y luego continúe con un plan anual.',
    'Stealth Notifications': 'Notificaciones sigilosas',
    'Store Trial': 'Prueba de tienda',
    'Store billing is currently bypassed by a temporary app-wide test switch.':
        'Actualmente, la facturación de la tienda se omite mediante un cambio de prueba temporal en toda la aplicación.',
    'Subscription Terms': 'Términos de suscripción',
    'TIMERS': 'TEMPORIZADORES',
    'Take private photos and videos inside TempCam, keep them out of the main gallery, and let them disappear unless you keep them forever.':
        'Toma fotos y vídeos privados dentro de TempCam, mantenlos fuera de la galería principal y déjalos desaparecer a menos que los conserves para siempre.',
    'Temp media stays local to your device until you explicitly keep it forever. Recent-app previews are shielded, and sensitive actions stay protected behind biometric confirmation when enabled.':
        'Los medios temporales permanecen locales en su dispositivo hasta que los conserve explícitamente para siempre. Las vistas previas de aplicaciones recientes están protegidas y las acciones sensibles permanecen protegidas detrás de la confirmación biométrica cuando están habilitadas.',
    'Temp photos and videos are stored locally on the device inside TempCam until they expire, are deleted, or are kept forever by the user.':
        'Las fotos y videos temporales se almacenan localmente en el dispositivo dentro de TempCam hasta que caduquen, se eliminen o el usuario los conserve para siempre.',
    'TempCam does not upload your temporary media to a cloud service inside the app flow. Subscription billing is handled by the platform store.':
        'TempCam no carga sus medios temporales a un servicio en la nube dentro del flujo de la aplicación. La facturación de las suscripciones la gestiona la tienda de la plataforma.',
    'TempCam keeps sensitive captures temporary.':
        'TempCam mantiene capturas confidenciales temporales.',
    'TempCam offers one auto-renewing yearly subscription for access to the app.':
        'TempCam ofrece una suscripción anual que se renueva automáticamente para acceder a la aplicación.',
    'Temporary by default': 'Temporal por defecto',
    'Temporary captures stay inside TempCam instead of appearing in the main gallery.':
        'Las capturas temporales permanecen dentro de TempCam en lugar de aparecer en la galería principal.',
    'Testing': 'Pruebas',
    'The 15-day free trial is managed by Google Play or the App Store, so clearing app data will not restart it.':
        'La prueba gratuita de 15 días la administra Google Play o App Store, por lo que borrar los datos de la aplicación no la reiniciará.',
    'The vault keeps temp media private first.':
        'La bóveda mantiene privados los medios temporales primero.',
    'This build bypasses subscriptions so you can test TempCam on your phone before store upload.':
        'Esta compilación omite las suscripciones para que puedas probar TempCam en tu teléfono antes de cargar la tienda.',
    'This filter only shows temp photos stored inside TempCam.':
        'Este filtro solo muestra fotografías temporales almacenadas dentro de TempCam.',
    'This filter only shows temp videos stored inside TempCam.':
        'Este filtro solo muestra videos temporales almacenados dentro de TempCam.',
    'Trial Then Yearly': 'Prueba luego anualmente',
    'Trusted Vault History': 'Historial de bóveda confiable',
    'Unable to export this item to the main gallery.':
        'No se puede exportar este elemento a la galería principal.',
    'Unable to import media right now.':
        'No se pueden importar medios en este momento.',
    'Unable to use video recording right now.':
        'No se puede utilizar la grabación de vídeo en este momento.',
    'Unlock Premium': 'Desbloquear Premium',
    'Unlock Premium to use the 7 day timer.':
        'Desbloquea Premium para usar el temporizador de 7 días.',
    'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and Panic Exit for faster privacy under pressure.':
        'Utilice protección biométrica, modo de privacidad de sesión, tiempo de espera de bloqueo rápido, vista previa protegida de recientes y salida de pánico para una privacidad más rápida bajo presión.',
    'Use photo or video mode, tap to focus, pinch to zoom, control flash, and review the private preview before you apply the timer.':
        'Utilice el modo de foto o vídeo, toque para enfocar, pellizque para hacer zoom, controle el flash y revise la vista previa privada antes de aplicar el temporizador.',
    'Users can restore purchases after reinstall and can manage or cancel subscriptions from their platform subscription settings.':
        'Los usuarios pueden restaurar las compras después de la reinstalación y pueden administrar o cancelar suscripciones desde la configuración de suscripción de su plataforma.',
    'VAULT': 'BÓVEDA',
    'Video auto-deleted': 'Vídeo eliminado automáticamente',
    'Video deleted now': 'Vídeo eliminado ahora',
    'Video kept forever': 'Vídeo guardado para siempre.',
    'Video kept forever and exported.':
        'Vídeo guardado para siempre y exportado.',
    'Video saved to TempCam': 'Vídeo guardado en TempCam',
    'View Access Options': 'Ver opciones de acceso',
    'View Yearly Plan': 'Ver plan anual',
    'WELCOME': 'BIENVENIDO',
    'Waiting for store confirmation...':
        'Esperando confirmación de la tienda...',
    'Walk through camera, timers, vault, security, and settings again any time.':
        'Recorra la cámara, los temporizadores, la bóveda, la seguridad y la configuración nuevamente en cualquier momento.',
    'What TempCam does not do': 'Lo que TempCam no hace',
    'What TempCam stores': 'Qué almacena TempCam',
    'Why People Use TempCam': 'Por qué la gente usa TempCam',
    'YEARLY ACCESS': 'ACCESO ANUAL',
    'Yearly Billing': 'Facturación anual',
    'Yearly access powers TempCam.': 'Facultades de acceso anual TempCam.',
    'Yearly access unlocked. TempCam is ready to use.':
        'Acceso anual desbloqueado. TempCam está listo para usar.',
    'You can skip this now and reopen it any time from Settings.':
        'Puedes omitir esto ahora y volver a abrirlo en cualquier momento desde Configuración.',
    'Your access is live.': 'Su acceso es en vivo.',
    'Your current subscription is active through the store.':
        'Tu suscripción actual está activa a través de la tienda.',
    'Your subscription is handled directly by the App Store or Google Play with one yearly plan.':
        'Su suscripción es manejada directamente por App Store o Google Play con un plan anual.',
    'Your vault is empty': 'Tu bóveda está vacía',
    'Your yearly subscription has been restored.':
        'Su suscripción anual ha sido restaurada.',
    'Your yearly subscription is active.': 'Tu suscripción anual está activa.',
    '{count} items deleted from TempCam.':
        '{count} elementos eliminados de TempCam.',
    '{count} items imported into TempCam, but {failed} original items could not be removed from the main gallery.':
        '{count} elementos importados a TempCam, pero {failed} elementos originales no se pudieron eliminar de la galería principal.',
    '{count} items moved into TempCam and removed from the main gallery.':
        '{count} elementos se movieron a TempCam y se eliminaron de la galería principal.',
    '{count} items selected for deletion.':
        '{count} elementos seleccionados para su eliminación.',
    '{count} temp items ready': '{count} artículos temporales listos',
    '{days}d {hours}h': '{days}d {hours}h',
    '{hours}h {minutes}m': '{hours}h {minutes}m',
    '{media} expired after {timer} and was removed from TempCam.':
        '{media} expiró después de {timer} y se eliminó de TempCam.',
    '{media} exported to the main gallery and removed from TempCam expiry.':
        '{media} exportado a la galería principal y eliminado del vencimiento de TempCam.',
    '{media} removed manually before its timer ended.':
        '{media} se eliminó manualmente antes de que terminara el cronómetro.',
    '{minutes}m': '{minutes}m',
  },
  'de': {
    'System Default': 'Systemstandard',
    'Language': 'Sprache',
    'Choose the app language. System Default follows your phone language.':
        'Wahle die App-Sprache. Systemstandard folgt der Sprache deines Telefons.',
    'Press back again to exit TempCam':
        'Noch einmal zuruck drucken, um TempCam zu beenden',
    'Protected Preview': 'Geschutzte Vorschau',
    '15 DAYS FREE': '15 TAGE GRATIS',
    'Start with a secure free trial.': 'Starte mit einer sicheren Gratisphase.',
    'Continue To Access': 'Weiter',
    'PRIVATE • TEMPORARY • LOCAL': 'PRIVAT • TEMPORAR • LOKAL',
    'Preparing secure vault experience': 'Sicherer Tresor wird vorbereitet',
    'Secure session initializing': 'Sichere Sitzung wird gestartet',
    'Vault Locked': 'Tresor gesperrt',
    'Unlocking...': 'Wird entsperrt...',
    'Unlock TempCam': 'TempCam entsperren',
    'Switching camera...': 'Kamera wird gewechselt...',
    'PHOTO': 'FOTO',
    'VIDEO': 'VIDEO',
    'Tap to view': 'Zum Anzeigen tippen',
    'Set Self-Destruct Timer': 'Selbstzerstorungs-Timer setzen',
    'Apply Timer': 'Timer anwenden',
    'Private Vault': 'Privater Tresor',
    'Expiring in': 'Lauft ab in',
    'Created': 'Erstellt',
    'Private Video': 'Privates Video',
    'Private Photo': 'Privates Foto',
    'Extend Timer': 'Timer verlangern',
    'Keep Forever': 'Fur immer behalten',
    'Delete Now': 'Jetzt loschen',
    'Skip': 'Uberspringen',
    'Back': 'Zuruck',
    'Get Started': 'Loslegen',
    'Next': 'Weiter',
    'Manage Access': 'Zugriff verwalten',
    'Open Camera': 'Kamera offnen',
    'Open Vault': 'Tresor offnen',
    'All': 'Alle',
    'Photos': 'Fotos',
    'Videos': 'Videos',
    'Cancel': 'Abbrechen',
    'Delete': 'Loschen',
    'Restore Purchase': 'Kauf wiederherstellen',
    'Privacy Policy': 'Datenschutz',
    'Terms': 'Bedingungen',
    'Capture': 'Aufnehmen',
    'Done': 'Fertig',
    'Select': 'Auswahlen',
    'FREE TRIAL': 'GRATIS TESTEN',
    'ACTIVE': 'AKTIV',
    'REQUIRED': 'ERFORDERLICH',
    'Camera is unavailable.': 'Kamera ist nicht verfugbar.',
    'Video': 'Video',
    'Photo': 'Foto',
    '1 Hour': '1 Stunde',
    '12 Hours': '12 Stunden',
    '15 Seconds': '15 Sekunden',
    '24 Hours': '24 Stunden',
    '3 Days': '3 Tage',
    '3 Hours': '3 Stunden',
    '30 Seconds': '30 Sekunden',
    '5 Seconds': '5 Sekunden',
    '7 Days': '7 Tage',
    '7 day timers are available with Premium.':
        '7-Tage-Timer sind mit Premium verfügbar.',
    'A {price} yearly subscription keeps TempCam private, temporary, and fully unlocked.':
        'Mit einem {price}-Jahresabonnement bleibt TempCam privat, vorübergehend und vollständig freigeschaltet.',
    'APP TOUR': 'APP-TOUR',
    'Access Active': 'Zugriff aktiv',
    'Access Required': 'Zugriff erforderlich',
    'Access is recorded until {date}.':
        'Der Zugriff wird bis {date} protokolliert.',
    'Access recorded until {date}': 'Zugriff erfasst bis {date}',
    'After the trial ends, Google Play continues the subscription at {price} per year unless the user cancels in time.':
        'Nach Ablauf der Testphase setzt Google Play das Abonnement für {price} pro Jahr fort, sofern der Benutzer nicht rechtzeitig kündigt.',
    'All Media': 'Alle Medien',
    'Annual Access': 'Jährlicher Zugang',
    'Authenticating now. If the prompt does not appear, tap below to unlock TempCam.':
        'Jetzt authentifizieren. Wenn die Eingabeaufforderung nicht angezeigt wird, tippen Sie unten, um TempCam zu entsperren.',
    'Auto-renewing yearly subscription. Cancel anytime in Google Play or App Store subscriptions.':
        'Jahresabonnement mit automatischer Verlängerung. Bei Abonnements vom Typ Google Play oder App Store können Sie jederzeit kündigen.',
    'Before release': 'Vor der Veröffentlichung',
    'Billing': 'Abrechnung',
    'Biometric Lock': 'Biometrisches Schloss',
    'Biometric protection is unavailable on this device.':
        'Der biometrische Schutz ist auf diesem Gerät nicht verfügbar.',
    'Biometrics are unavailable on this device. Continue without biometric lock from settings.':
        'Auf diesem Gerät sind keine biometrischen Daten verfügbar. Fahren Sie ohne biometrische Sperre in den Einstellungen fort.',
    'Biometrics, quick relock, and Panic Exit stay ready.':
        'Biometrie, schnelle Wiederverriegelung und Panic Exit bleiben bereit.',
    'Browse all temp photos and videos, focus on what is expiring, and clean up quickly when you need to.':
        'Durchsuchen Sie alle temporären Fotos und Videos, konzentrieren Sie sich auf das, was abläuft, und räumen Sie bei Bedarf schnell auf.',
    'Browse photos and videos in the private vault, filter by type, import existing media into TempCam, extend timers, or delete items when you need to.':
        'Durchsuchen Sie Fotos und Videos im privaten Tresor, filtern Sie nach Typ, importieren Sie vorhandene Medien in TempCam, verlängern Sie Timer oder löschen Sie Elemente bei Bedarf.',
    'Buy 1 Year For {price}': 'Kaufen Sie 1 Jahr für {price}',
    'Buy or restore yearly access to open TempCam. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'Kaufen oder stellen Sie den jährlichen Zugang zum Öffnen von TempCam wieder her. Wenn Ihr Shop-Konto berechtigt ist, kann die Plattform beim Bezahlvorgang die 15-tägige kostenlose Testversion anwenden.',
    'CAMERA': 'KAMERA',
    'Capture Defaults': 'Capture-Standards',
    'Capture a photo or video and it will appear here with its self-destruct timer.':
        'Nehmen Sie ein Foto oder Video auf und es wird hier mit seinem Selbstzerstörungstimer angezeigt.',
    'Capture quickly with the private camera.':
        'Nehmen Sie schnell mit der privaten Kamera auf.',
    'Choose a timer after capture or import. If you skip it, TempCam uses your default timer from Settings.':
        'Wählen Sie einen Timer nach der Aufnahme oder dem Import. Wenn Sie es überspringen, verwendet TempCam Ihren Standard-Timer aus den Einstellungen.',
    'Choose how long TempCam can stay in the background before it asks for biometrics again.':
        'Wählen Sie aus, wie lange TempCam im Hintergrund bleiben kann, bevor erneut nach biometrischen Daten gefragt wird.',
    'Choose how long new captures stay available by default.':
        'Wählen Sie aus, wie lange neue Aufnahmen standardmäßig verfügbar bleiben.',
    'Choose items to delete.': 'Wählen Sie die zu löschenden Elemente aus.',
    'Choose when this capture evaporates from the vault.':
        'Wählen Sie, wann diese Aufnahme aus dem Tresor verschwindet.',
    'Close TempCam immediately and relock on return.':
        'TempCam sofort schließen und bei Rückkehr wieder verriegeln.',
    'Connecting To Store...': 'Verbindung zum Store herstellen...',
    'Default Self-Destruct Timer': 'Standard-Selbstzerstörungstimer',
    'Default {timer}': 'Standard {timer}',
    'Defaults to 24 hours if skipped.':
        'Wird dieser Wert übersprungen, beträgt er standardmäßig 24 Stunden.',
    'Directly billed and renewed by the platform store.':
        'Direkte Abrechnung und Verlängerung durch den Plattform-Store.',
    'Disable TEMPCAM_DISABLE_PAYMENTS before uploading to the store.':
        'Deaktivieren Sie TEMPCAM_DISABLE_PAYMENTS vor dem Hochladen in den Store.',
    'Done ({count})': 'Fertig ({count})',
    'Enable Biometric Lock first to use instant session relocking.':
        'Aktivieren Sie zuerst die biometrische Sperre, um die sofortige erneute Sitzungssperre zu verwenden.',
    'Encrypted Vault': 'Verschlüsselter Tresor',
    'Every item gets a self-destruct timer.':
        'Jeder Gegenstand erhält einen Selbstzerstörungstimer.',
    'Every temporary moment, in one calm vault.':
        'Jeder vorübergehende Moment, in einem ruhigen Gewölbe.',
    'Expired': 'Abgelaufen',
    'Expiring Soon': 'Läuft bald ab',
    'Expiry Notifications': 'Ablaufbenachrichtigungen',
    'Fallback price shown until the store catalog loads.':
        'Der Ersatzpreis wird angezeigt, bis der Store-Katalog geladen wird.',
    'Fast under pressure': 'Schnell unter Druck',
    'Finish the current capture before importing media.':
        'Beenden Sie die aktuelle Aufnahme, bevor Sie Medien importieren.',
    'Flash auto': 'Blitz automatisch',
    'Flash is unavailable on this camera.':
        'Der Blitz ist bei dieser Kamera nicht verfügbar.',
    'Flash off': 'Ablüften',
    'Flash on': 'Blitz an',
    'Flash torch': 'Taschenlampe',
    'Forever': 'Für immer',
    'Get warned before temporary media disappears.':
        'Lassen Sie sich warnen, bevor temporäre Medien verschwinden.',
    'Google Play or the App Store can start a secure 15-day free trial for eligible accounts before yearly billing begins.':
        'Google Play oder App Store können für berechtigte Konten eine sichere 15-tägige kostenlose Testversion starten, bevor die jährliche Abrechnung beginnt.',
    'Google Play will start your 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'Google Play startet Ihre 15-tägige kostenlose Testversion, wenn Sie das Jahresabonnement beginnen. Diese Testversion ist an das Store-Konto gebunden, daher wird sie durch das Löschen der App-Daten nicht neu gestartet.',
    'Help': 'Helfen',
    'Hide photo and video wording in reminders for a quieter lock-screen presence.':
        'Blenden Sie Foto- und Videotexte in Erinnerungen aus, um die Präsenz auf dem Sperrbildschirm leiser zu gestalten.',
    'If eligible, checkout starts with the store-managed 15-day free trial and then renews yearly.':
        'Wenn Sie berechtigt sind, beginnt der Checkout mit der vom Store verwalteten 15-tägigen kostenlosen Testversion und verlängert sich dann jährlich.',
    'If your Google Play account is eligible, the store will offer a 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'Wenn Ihr Google Play-Konto berechtigt ist, bietet der Shop zu Beginn des Jahresabonnements eine 15-tägige kostenlose Testversion an. Diese Testversion ist an das Store-Konto gebunden, daher wird sie durch das Löschen der App-Daten nicht neu gestartet.',
    'Keep Forever exports, manual deletions, and auto-deletions will appear here as a local trust log.':
        'Keep Forever-Exporte, manuelle Löschungen und automatische Löschungen werden hier als lokales Vertrauensprotokoll angezeigt.',
    'Kept Forever': 'Für immer aufbewahrt',
    'LOCAL PRIVATE STORAGE': 'LOKALER PRIVATSPEICHER',
    'LOCAL | TEMPORARY | PROTECTED': 'LOKAL | VORÜBERGEHEND | GESCHÜTZT',
    'Local record of exports, deletions, and auto-deletions.':
        'Lokale Aufzeichnung von Exporten, Löschungen und automatischen Löschungen.',
    'Lock TempCam immediately whenever the app loses focus.':
        'Sperren Sie TempCam sofort, wenn die App den Fokus verliert.',
    'Manage TempCam Access': 'TempCam-Zugriff verwalten',
    'Manage expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.':
        'Verwalten Sie Ablaufbenachrichtigungen, den Wortlaut von Stealth-Benachrichtigungen, Standard-Timer und den Abonnementzugriff und öffnen Sie diese Tour jederzeit über die Einstellungen erneut.',
    'Managing access': 'Zugriff verwalten',
    'Media no longer exists.': 'Medien gibt es nicht mehr.',
    'No temp photos yet': 'Noch keine temporären Fotos',
    'No temp videos yet': 'Noch keine temporären Videos',
    'Once the subscription or trial is active, TempCam unlocks fully and can re-lock with biometrics.':
        'Sobald das Abonnement oder die Testversion aktiv ist, wird TempCam vollständig entsperrt und kann mithilfe biometrischer Daten erneut gesperrt werden.',
    'One auto-renewing yearly subscription managed directly by Google Play or the App Store.':
        'Ein Jahresabonnement mit automatischer Verlängerung, das direkt von Google Play oder App Store verwaltet wird.',
    'Only Plan': 'Nur planen',
    'Open, capture, review, and protect sensitive moments with fewer steps.':
        'Öffnen, erfassen, überprüfen und schützen Sie sensible Momente mit weniger Schritten.',
    'PAYMENT OFF': 'ZAHLUNG AUS',
    'Panic Exit': 'Panischer Ausgang',
    'Panic Exit and quick relocking help when you need privacy right away.':
        'Panikausgang und schnelles Wiederverriegeln helfen, wenn Sie sofort Privatsphäre benötigen.',
    'Payment Disabled For Testing': 'Zahlung zum Testen deaktiviert',
    'Payment is charged by Google Play or the App Store at confirmation of purchase. Subscriptions renew automatically unless canceled before the renewal date.':
        'Die Zahlung erfolgt per Google Play oder App Store bei der Kaufbestätigung. Abonnements verlängern sich automatisch, sofern sie nicht vor dem Verlängerungsdatum gekündigt werden.',
    'Payments Disabled Temporarily': 'Zahlungen vorübergehend deaktiviert',
    'Photo auto-deleted': 'Foto automatisch gelöscht',
    'Photo deleted now': 'Foto jetzt gelöscht',
    'Photo kept forever': 'Foto für immer aufbewahrt',
    'Photo kept forever and exported.':
        'Foto für immer aufbewahrt und exportiert.',
    'Photos and videos auto-delete unless you decide to keep them forever.':
        'Fotos und Videos werden automatisch gelöscht, es sei denn, Sie möchten sie für immer behalten.',
    'Plan': 'Planen',
    'Premium Only': 'Nur Premium',
    'Privacy Notes': 'Datenschutzhinweise',
    'Private Preview': 'Private Vorschau',
    'Private by design': 'Von Natur aus privat',
    'Protect app entry and sensitive actions with biometrics.':
        'Schützen Sie App-Eingaben und sensible Aktionen mit Biometrie.',
    'Quick Lock Timeout': 'Zeitüberschreitung bei Schnellsperre',
    'Recording started': 'Aufnahme gestartet',
    'Recover your yearly access from the App Store or Google Play on reinstall.':
        'Stellen Sie bei der Neuinstallation Ihren jährlichen Zugriff von App Store oder Google Play wieder her.',
    'Release setup': 'Release-Setup',
    'Replay App Tour': 'App-Tour erneut abspielen',
    'Replay Tour': 'Wiederholungstour',
    'Restore Support': 'Unterstützung wiederherstellen',
    'Restore request sent to the store.':
        'Wiederherstellungsanfrage an den Store gesendet.',
    'Review this private photo before setting its timer.':
        'Sehen Sie sich dieses private Foto an, bevor Sie den Timer einstellen.',
    'Review this private video before setting its timer.':
        'Sehen Sie sich dieses private Video an, bevor Sie den Timer einstellen.',
    'SECURITY': 'SICHERHEIT',
    'SETTINGS': 'EINSTELLUNGEN',
    'Secure Access': 'Sicherer Zugriff',
    'Security': 'Sicherheit',
    'Session Privacy Mode': 'Sitzungs-Privatsphärenmodus',
    'Session Privacy Mode locks instantly, so timeout is bypassed.':
        'Der Sitzungs-Datenschutzmodus wird sofort gesperrt, sodass eine Zeitüberschreitung umgangen wird.',
    'Set TEMPCAM_PRIVACY_POLICY_URL during your release build to open your hosted policy page from the app.':
        'Legen Sie während Ihres Release-Builds TEMPCAM_PRIVACY_POLICY_URL fest, um Ihre gehostete Richtlinienseite über die App zu öffnen.',
    'Set TEMPCAM_SUBSCRIPTION_TERMS_URL during your release build to open your hosted terms page from the app.':
        'Legen Sie während Ihres Release-Builds TEMPCAM_SUBSCRIPTION_TERMS_URL fest, um Ihre gehostete Seite mit Bedingungen über die App zu öffnen.',
    'Settings controls reminders, stealth mode, and access.':
        'Die Einstellungen steuern Erinnerungen, Stealth-Modus und Zugriff.',
    'Start': 'Start',
    'Start 15 Days Free': 'Starten Sie 15 Tage kostenlos',
    'Start or restore yearly access. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'Starten Sie den jährlichen Zugriff oder stellen Sie ihn wieder her. Wenn Ihr Shop-Konto berechtigt ist, kann die Plattform beim Bezahlvorgang die 15-tägige kostenlose Testversion anwenden.',
    'Start the Google Play or App Store managed 15-day free trial, or restore your yearly access to open TempCam.':
        'Starten Sie die verwaltete 15-tägige kostenlose Testversion von Google Play oder App Store oder stellen Sie Ihren jährlichen Zugriff wieder her, um TempCam zu öffnen.',
    'Start with 15 days free.': 'Beginnen Sie mit 15 Tagen kostenlos.',
    'Start your secure store-managed 15-day free trial, then continue with one yearly plan.':
        'Starten Sie Ihre sichere, vom Store verwaltete 15-tägige kostenlose Testversion und fahren Sie dann mit einem Jahresplan fort.',
    'Stealth Notifications': 'Stealth-Benachrichtigungen',
    'Store Trial': 'Store-Testversion',
    'Store billing is currently bypassed by a temporary app-wide test switch.':
        'Die Store-Abrechnung wird derzeit durch einen vorübergehenden App-weiten Testschalter umgangen.',
    'Subscription Terms': 'Abonnementbedingungen',
    'TIMERS': 'TIMER',
    'Take private photos and videos inside TempCam, keep them out of the main gallery, and let them disappear unless you keep them forever.':
        'Nehmen Sie private Fotos und Videos in TempCam auf, halten Sie sie aus der Hauptgalerie fern und lassen Sie sie verschwinden, es sei denn, Sie behalten sie für immer.',
    'Temp media stays local to your device until you explicitly keep it forever. Recent-app previews are shielded, and sensitive actions stay protected behind biometric confirmation when enabled.':
        'Temporäre Medien bleiben lokal auf Ihrem Gerät, bis Sie sie ausdrücklich für immer behalten. Vorschauen aktueller Apps werden abgeschirmt und vertrauliche Aktionen bleiben bei Aktivierung hinter der biometrischen Bestätigung geschützt.',
    'Temp photos and videos are stored locally on the device inside TempCam until they expire, are deleted, or are kept forever by the user.':
        'Temporäre Fotos und Videos werden lokal auf dem Gerät in TempCam gespeichert, bis sie ablaufen, gelöscht werden oder vom Benutzer für immer aufbewahrt werden.',
    'TempCam does not upload your temporary media to a cloud service inside the app flow. Subscription billing is handled by the platform store.':
        'TempCam lädt Ihre temporären Medien nicht auf einen Cloud-Dienst innerhalb des App-Flows hoch. Die Abrechnung des Abonnements erfolgt über den Plattform-Store.',
    'TempCam keeps sensitive captures temporary.':
        'TempCam speichert vertrauliche Erfassungen vorübergehend.',
    'TempCam offers one auto-renewing yearly subscription for access to the app.':
        'TempCam bietet ein sich automatisch verlängerndes Jahresabonnement für den Zugriff auf die App.',
    'Temporary by default': 'Standardmäßig temporär',
    'Temporary captures stay inside TempCam instead of appearing in the main gallery.':
        'Temporäre Aufnahmen bleiben in TempCam, anstatt in der Hauptgalerie zu erscheinen.',
    'Testing': 'Testen',
    'The 15-day free trial is managed by Google Play or the App Store, so clearing app data will not restart it.':
        'Die 15-tägige kostenlose Testversion wird von Google Play oder App Store verwaltet, sodass sie durch das Löschen der App-Daten nicht neu gestartet wird.',
    'The vault keeps temp media private first.':
        'Der Tresor hält temporäre Medien zunächst privat.',
    'This build bypasses subscriptions so you can test TempCam on your phone before store upload.':
        'Dieser Build umgeht Abonnements, sodass Sie TempCam auf Ihrem Telefon testen können, bevor Sie es in den Store hochladen.',
    'This filter only shows temp photos stored inside TempCam.':
        'Dieser Filter zeigt nur temporäre Fotos an, die in TempCam gespeichert sind.',
    'This filter only shows temp videos stored inside TempCam.':
        'Dieser Filter zeigt nur temporäre Videos an, die in TempCam gespeichert sind.',
    'Trial Then Yearly': 'Probezeit, dann jährlich',
    'Trusted Vault History': 'Vertrauenswürdiger Tresorverlauf',
    'Unable to export this item to the main gallery.':
        'Dieses Element kann nicht in die Hauptgalerie exportiert werden.',
    'Unable to import media right now.':
        'Medien können derzeit nicht importiert werden.',
    'Unable to use video recording right now.':
        'Die Videoaufzeichnung kann derzeit nicht verwendet werden.',
    'Unlock Premium': 'Premium freischalten',
    'Unlock Premium to use the 7 day timer.':
        'Schalten Sie Premium frei, um den 7-Tage-Timer zu verwenden.',
    'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and Panic Exit for faster privacy under pressure.':
        'Verwenden Sie biometrischen Schutz, Sitzungs-Privatsphärenmodus, schnelles Sperr-Timeout, geschützte Vorschau der letzten Nachrichten und Panic Exit für schnelleren Datenschutz unter Druck.',
    'Use photo or video mode, tap to focus, pinch to zoom, control flash, and review the private preview before you apply the timer.':
        'Verwenden Sie den Foto- oder Videomodus, tippen Sie zum Fokussieren, ziehen Sie die Finger zusammen, um zu zoomen, steuern Sie den Blitz und sehen Sie sich die private Vorschau an, bevor Sie den Timer anwenden.',
    'Users can restore purchases after reinstall and can manage or cancel subscriptions from their platform subscription settings.':
        'Benutzer können Käufe nach der Neuinstallation wiederherstellen und Abonnements über die Abonnementeinstellungen ihrer Plattform verwalten oder kündigen.',
    'VAULT': 'GEWÖLBE',
    'Video auto-deleted': 'Video automatisch gelöscht',
    'Video deleted now': 'Video jetzt gelöscht',
    'Video kept forever': 'Video für immer aufbewahrt',
    'Video kept forever and exported.':
        'Video für immer aufbewahrt und exportiert.',
    'Video saved to TempCam': 'Video gespeichert unter TempCam',
    'View Access Options': 'Zugriffsoptionen anzeigen',
    'View Yearly Plan': 'Jahresplan anzeigen',
    'WELCOME': 'WILLKOMMEN',
    'Waiting for store confirmation...': 'Warten auf Shop-Bestätigung...',
    'Walk through camera, timers, vault, security, and settings again any time.':
        'Gehen Sie jederzeit erneut durch Kamera, Timer, Tresor, Sicherheit und Einstellungen.',
    'What TempCam does not do': 'Was TempCam nicht tut',
    'What TempCam stores': 'Was TempCam speichert',
    'Why People Use TempCam': 'Warum Menschen TempCam verwenden',
    'YEARLY ACCESS': 'JÄHRLICHER ZUGRIFF',
    'Yearly Billing': 'Jährliche Abrechnung',
    'Yearly access powers TempCam.': 'Jährliche Zugangsbefugnisse TempCam.',
    'Yearly access unlocked. TempCam is ready to use.':
        'Jährlicher Zugang freigeschaltet. TempCam ist einsatzbereit.',
    'You can skip this now and reopen it any time from Settings.':
        'Sie können dies jetzt überspringen und es jederzeit über die Einstellungen erneut öffnen.',
    'Your access is live.': 'Ihr Zugang ist live.',
    'Your current subscription is active through the store.':
        'Ihr aktuelles Abonnement ist über den Store aktiv.',
    'Your subscription is handled directly by the App Store or Google Play with one yearly plan.':
        'Ihr Abonnement wird direkt von App Store oder Google Play mit einem Jahresplan verwaltet.',
    'Your vault is empty': 'Ihr Tresor ist leer',
    'Your yearly subscription has been restored.':
        'Ihr Jahresabonnement wurde wiederhergestellt.',
    'Your yearly subscription is active.': 'Ihr Jahresabonnement ist aktiv.',
    '{count} items deleted from TempCam.':
        '{count} Elemente aus TempCam gelöscht.',
    '{count} items imported into TempCam, but {failed} original items could not be removed from the main gallery.':
        '{count} Artikel wurden in TempCam importiert, aber {failed} Originalartikel konnten nicht aus der Hauptgalerie entfernt werden.',
    '{count} items moved into TempCam and removed from the main gallery.':
        '{count} Elemente wurden nach TempCam verschoben und aus der Hauptgalerie entfernt.',
    '{count} items selected for deletion.':
        '{count} Elemente zum Löschen ausgewählt.',
    '{count} temp items ready': '{count} temporäre Elemente bereit',
    '{days}d {hours}h': '{days}d {hours}h',
    '{hours}h {minutes}m': '{hours}h {minutes}m',
    '{media} expired after {timer} and was removed from TempCam.':
        '{media} ist nach {timer} abgelaufen und wurde aus TempCam entfernt.',
    '{media} exported to the main gallery and removed from TempCam expiry.':
        '{media} wurde in die Hauptgalerie exportiert und aus dem Ablauf von TempCam entfernt.',
    '{media} removed manually before its timer ended.':
        '{media} wurde manuell entfernt, bevor der Timer abgelaufen ist.',
    '{minutes}m': '{minutes}m',
  },
  'fr': {
    'System Default': 'Par defaut du systeme',
    'Language': 'Langue',
    'Choose the app language. System Default follows your phone language.':
        'Choisissez la langue de l'
            'application. Le mode systeme suit la langue du telephone.',
    'Press back again to exit TempCam':
        'Appuyez encore sur retour pour quitter TempCam',
    'Protected Preview': 'Apercu protege',
    '15 DAYS FREE': '15 JOURS GRATUITS',
    'Start with a secure free trial.':
        'Commencez avec un essai gratuit securise.',
    'Continue To Access': 'Continuer',
    'PRIVATE • TEMPORARY • LOCAL': 'PRIVE • TEMPORAIRE • LOCAL',
    'Preparing secure vault experience': 'Preparation du coffre securise',
    'Secure session initializing': 'Initialisation de la session securisee',
    'Vault Locked': 'Coffre verrouille',
    'Unlocking...': 'Deverrouillage...',
    'Unlock TempCam': 'Deverrouiller TempCam',
    'Switching camera...': 'Changement de camera...',
    'PHOTO': 'PHOTO',
    'VIDEO': 'VIDEO',
    'Tap to view': 'Touchez pour voir',
    'Set Self-Destruct Timer': 'Definir le minuteur',
    'Apply Timer': 'Appliquer le minuteur',
    'Private Vault': 'Coffre prive',
    'Expiring in': 'Expire dans',
    'Created': 'Cree',
    'Private Video': 'Video privee',
    'Private Photo': 'Photo privee',
    'Extend Timer': 'Prolonger le minuteur',
    'Keep Forever': 'Conserver pour toujours',
    'Delete Now': 'Supprimer maintenant',
    'Skip': 'Passer',
    'Back': 'Retour',
    'Get Started': 'Commencer',
    'Next': 'Suivant',
    'Manage Access': 'Gerer l' 'acces',
    'Open Camera': 'Ouvrir la camera',
    'Open Vault': 'Ouvrir le coffre',
    'All': 'Tout',
    'Photos': 'Photos',
    'Videos': 'Videos',
    'Cancel': 'Annuler',
    'Delete': 'Supprimer',
    'Restore Purchase': 'Restaurer l' 'achat',
    'Privacy Policy': 'Confidentialite',
    'Terms': 'Conditions',
    'Capture': 'Capturer',
    'Done': 'Termine',
    'Select': 'Selectionner',
    'FREE TRIAL': 'ESSAI GRATUIT',
    'ACTIVE': 'ACTIF',
    'REQUIRED': 'REQUIS',
    'Camera is unavailable.': 'La camera est indisponible.',
    'Video': 'Video',
    'Photo': 'Photo',
    '1 Hour': '1 heure',
    '12 Hours': '12 heures',
    '15 Seconds': '15 secondes',
    '24 Hours': '24 heures',
    '3 Days': '3 jours',
    '3 Hours': '3 heures',
    '30 Seconds': '30 secondes',
    '5 Seconds': '5 secondes',
    '7 Days': '7 jours',
    '7 day timers are available with Premium.':
        'Des minuteries sur 7 jours sont disponibles avec Premium.',
    'A {price} yearly subscription keeps TempCam private, temporary, and fully unlocked.':
        'Un abonnement annuel {price} maintient TempCam privé, temporaire et entièrement déverrouillé.',
    'APP TOUR': 'VISITE DE L\'APPLICATION',
    'Access Active': 'Accès actif',
    'Access Required': 'Accès requis',
    'Access is recorded until {date}.':
        'L\'accès est enregistré jusqu\'au {date}.',
    'Access recorded until {date}': 'Accès enregistré jusqu\'au {date}',
    'After the trial ends, Google Play continues the subscription at {price} per year unless the user cancels in time.':
        'Une fois la période d\'essai terminée, Google Play continue l\'abonnement à {price} par an, à moins que l\'utilisateur n\'annule à temps.',
    'All Media': 'Tous les médias',
    'Annual Access': 'Accès annuel',
    'Authenticating now. If the prompt does not appear, tap below to unlock TempCam.':
        'Authentification maintenant. Si l\'invite n\'apparaît pas, appuyez ci-dessous pour déverrouiller TempCam.',
    'Auto-renewing yearly subscription. Cancel anytime in Google Play or App Store subscriptions.':
        'Abonnement annuel à renouvellement automatique. Annulez à tout moment dans les abonnements Google Play ou App Store.',
    'Before release': 'Avant la sortie',
    'Billing': 'Facturation',
    'Biometric Lock': 'Verrouillage biométrique',
    'Biometric protection is unavailable on this device.':
        'La protection biométrique n\'est pas disponible sur cet appareil.',
    'Biometrics are unavailable on this device. Continue without biometric lock from settings.':
        'La biométrie n\'est pas disponible sur cet appareil. Continuez sans verrouillage biométrique depuis les paramètres.',
    'Biometrics, quick relock, and Panic Exit stay ready.':
        'La biométrie, le reverrouillage rapide et la sortie panique restent prêts.',
    'Browse all temp photos and videos, focus on what is expiring, and clean up quickly when you need to.':
        'Parcourez toutes les photos et vidéos temporaires, concentrez-vous sur ce qui arrive à expiration et nettoyez rapidement lorsque vous en avez besoin.',
    'Browse photos and videos in the private vault, filter by type, import existing media into TempCam, extend timers, or delete items when you need to.':
        'Parcourez les photos et les vidéos dans le coffre-fort privé, filtrez par type, importez les médias existants dans TempCam, prolongez les minuteries ou supprimez des éléments lorsque vous en avez besoin.',
    'Buy 1 Year For {price}': 'Achetez 1 an pour {price}',
    'Buy or restore yearly access to open TempCam. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'Achetez ou restaurez l\'accès annuel pour ouvrir TempCam. Si votre compte magasin est éligible, la plateforme peut appliquer l\'essai gratuit de 15 jours lors du paiement.',
    'CAMERA': 'CAMÉRA',
    'Capture Defaults': 'Capturer les valeurs par défaut',
    'Capture a photo or video and it will appear here with its self-destruct timer.':
        'Capturez une photo ou une vidéo et elle apparaîtra ici avec son minuteur d\'autodestruction.',
    'Capture quickly with the private camera.':
        'Capturez rapidement avec la caméra privée.',
    'Choose a timer after capture or import. If you skip it, TempCam uses your default timer from Settings.':
        'Choisissez une minuterie après la capture ou l\'importation. Si vous l\'ignorez, TempCam utilise votre minuterie par défaut dans Paramètres.',
    'Choose how long TempCam can stay in the background before it asks for biometrics again.':
        'Choisissez combien de temps TempCam peut rester en arrière-plan avant de demander à nouveau des données biométriques.',
    'Choose how long new captures stay available by default.':
        'Choisissez la durée pendant laquelle les nouvelles captures restent disponibles par défaut.',
    'Choose items to delete.': 'Choisissez les éléments à supprimer.',
    'Choose when this capture evaporates from the vault.':
        'Choisissez quand cette capture s’évapore du coffre-fort.',
    'Close TempCam immediately and relock on return.':
        'Fermez immédiatement TempCam et reverrouillez-le au retour.',
    'Connecting To Store...': 'Connexion au magasin...',
    'Default Self-Destruct Timer': 'Minuterie d\'autodestruction par défaut',
    'Default {timer}': 'Par défaut {timer}',
    'Defaults to 24 hours if skipped.':
        'La valeur par défaut est 24 heures si elle est ignorée.',
    'Directly billed and renewed by the platform store.':
        'Directement facturé et renouvelé par la boutique plateforme.',
    'Disable TEMPCAM_DISABLE_PAYMENTS before uploading to the store.':
        'Désactivez TEMPCAM_DISABLE_PAYMENTS avant de télécharger sur le magasin.',
    'Done ({count})': 'Terminé ({count})',
    'Enable Biometric Lock first to use instant session relocking.':
        'Activez d\'abord le verrouillage biométrique pour utiliser le reverrouillage instantané de la session.',
    'Encrypted Vault': 'Coffre-fort crypté',
    'Every item gets a self-destruct timer.':
        'Chaque élément reçoit une minuterie d\'autodestruction.',
    'Every temporary moment, in one calm vault.':
        'Chaque instant temporaire, dans un caveau calme.',
    'Expired': 'Expiré',
    'Expiring Soon': 'Expire bientôt',
    'Expiry Notifications': 'Notifications d\'expiration',
    'Fallback price shown until the store catalog loads.':
        'Prix ​​de secours affiché jusqu\'au chargement du catalogue du magasin.',
    'Fast under pressure': 'Rapide sous pression',
    'Finish the current capture before importing media.':
        'Terminez la capture en cours avant d\'importer le média.',
    'Flash auto': 'Flash automatique',
    'Flash is unavailable on this camera.':
        'Le flash n\'est pas disponible sur cet appareil photo.',
    'Flash off': 'Flash éteint',
    'Flash on': 'Flash activé',
    'Flash torch': 'Torche éclair',
    'Forever': 'Pour toujours',
    'Get warned before temporary media disappears.':
        'Soyez averti avant que les médias temporaires ne disparaissent.',
    'Google Play or the App Store can start a secure 15-day free trial for eligible accounts before yearly billing begins.':
        'Google Play ou App Store peuvent démarrer un essai gratuit sécurisé de 15 jours pour les comptes éligibles avant le début de la facturation annuelle.',
    'Google Play will start your 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'Google Play commencera votre essai gratuit de 15 jours lorsque vous commencerez l\'abonnement annuel. Cet essai est lié au compte du magasin, donc la suppression des données de l\'application ne la redémarrera pas.',
    'Help': 'Aide',
    'Hide photo and video wording in reminders for a quieter lock-screen presence.':
        'Masquez le texte des photos et des vidéos dans les rappels pour une présence plus silencieuse sur l\'écran de verrouillage.',
    'If eligible, checkout starts with the store-managed 15-day free trial and then renews yearly.':
        'Si vous êtes éligible, le paiement commence par l\'essai gratuit de 15 jours géré par le magasin, puis se renouvelle chaque année.',
    'If your Google Play account is eligible, the store will offer a 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'Si votre compte Google Play est éligible, le magasin vous proposera un essai gratuit de 15 jours lorsque vous commencerez l\'abonnement annuel. Cet essai est lié au compte du magasin, donc la suppression des données de l\'application ne la redémarrera pas.',
    'Keep Forever exports, manual deletions, and auto-deletions will appear here as a local trust log.':
        'Les exportations Keep Forever, les suppressions manuelles et les suppressions automatiques apparaîtront ici sous forme de journal de confiance local.',
    'Kept Forever': 'Gardé pour toujours',
    'LOCAL PRIVATE STORAGE': 'STOCKAGE PRIVÉ LOCAL',
    'LOCAL | TEMPORARY | PROTECTED': 'LOCALE | TEMPORAIRE | PROTÉGÉ',
    'Local record of exports, deletions, and auto-deletions.':
        'Enregistrement local des exportations, suppressions et suppressions automatiques.',
    'Lock TempCam immediately whenever the app loses focus.':
        'Verrouillez TempCam immédiatement chaque fois que l\'application perd le focus.',
    'Manage TempCam Access': 'Gérer l\'accès TempCam',
    'Manage expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.':
        'Gérez les notifications d\'expiration, le libellé des notifications furtives, les minuteries par défaut, l\'accès aux abonnements et rouvrez cette visite à tout moment à partir des paramètres.',
    'Managing access': 'Gestion des accès',
    'Media no longer exists.': 'Les médias n\'existent plus.',
    'No temp photos yet': 'Pas encore de photos temporaires',
    'No temp videos yet': 'Aucune vidéo temporaire pour l\'instant',
    'Once the subscription or trial is active, TempCam unlocks fully and can re-lock with biometrics.':
        'Une fois l\'abonnement ou l\'essai actif, TempCam se déverrouille entièrement et peut se reverrouiller avec la biométrie.',
    'One auto-renewing yearly subscription managed directly by Google Play or the App Store.':
        'Un abonnement annuel à renouvellement automatique géré directement par Google Play ou le App Store.',
    'Only Plan': 'Forfait uniquement',
    'Open, capture, review, and protect sensitive moments with fewer steps.':
        'Ouvrez, capturez, examinez et protégez les moments sensibles en moins d\'étapes.',
    'PAYMENT OFF': 'PAIEMENT',
    'Panic Exit': 'Sortie de panique',
    'Panic Exit and quick relocking help when you need privacy right away.':
        'Sortie de panique et aide au reverrouillage rapide lorsque vous avez immédiatement besoin d\'intimité.',
    'Payment Disabled For Testing': 'Paiement désactivé pour les tests',
    'Payment is charged by Google Play or the App Store at confirmation of purchase. Subscriptions renew automatically unless canceled before the renewal date.':
        'Le paiement est facturé par Google Play ou par App Store lors de la confirmation de l\'achat. Les abonnements se renouvellent automatiquement sauf annulation avant la date de renouvellement.',
    'Payments Disabled Temporarily': 'Paiements temporairement désactivés',
    'Photo auto-deleted': 'Photo supprimée automatiquement',
    'Photo deleted now': 'Photo supprimée maintenant',
    'Photo kept forever': 'Photo conservée pour toujours',
    'Photo kept forever and exported.':
        'Photo conservée pour toujours et exportée.',
    'Photos and videos auto-delete unless you decide to keep them forever.':
        'Les photos et vidéos sont automatiquement supprimées, sauf si vous décidez de les conserver pour toujours.',
    'Plan': 'Plan',
    'Premium Only': 'Premium uniquement',
    'Privacy Notes': 'Notes de confidentialité',
    'Private Preview': 'Aperçu privé',
    'Private by design': 'Privé par conception',
    'Protect app entry and sensitive actions with biometrics.':
        'Protégez l’accès aux applications et les actions sensibles grâce à la biométrie.',
    'Quick Lock Timeout': 'Délai de verrouillage rapide',
    'Recording started': 'L\'enregistrement a commencé',
    'Recover your yearly access from the App Store or Google Play on reinstall.':
        'Récupérez votre accès annuel à partir du App Store ou du Google Play lors de la réinstallation.',
    'Release setup': 'Configuration de la version',
    'Replay App Tour': 'Replay de la visite guidée de l\'application',
    'Replay Tour': 'Replay de la tournée',
    'Restore Support': 'Restaurer la prise en charge',
    'Restore request sent to the store.':
        'Demande de restauration envoyée au magasin.',
    'Review this private photo before setting its timer.':
        'Revoyez cette photo privée avant de régler sa minuterie.',
    'Review this private video before setting its timer.':
        'Revoyez cette vidéo privée avant de régler sa minuterie.',
    'SECURITY': 'SÉCURITÉ',
    'SETTINGS': 'PARAMÈTRES',
    'Secure Access': 'Accès sécurisé',
    'Security': 'Sécurité',
    'Session Privacy Mode': 'Mode de confidentialité de la session',
    'Session Privacy Mode locks instantly, so timeout is bypassed.':
        'Le mode de confidentialité de session se verrouille instantanément, de sorte que le délai d\'attente est contourné.',
    'Set TEMPCAM_PRIVACY_POLICY_URL during your release build to open your hosted policy page from the app.':
        'Définissez TEMPCAM_PRIVACY_POLICY_URL lors de la version de votre version pour ouvrir votre page de stratégie hébergée à partir de l\'application.',
    'Set TEMPCAM_SUBSCRIPTION_TERMS_URL during your release build to open your hosted terms page from the app.':
        'Définissez TEMPCAM_SUBSCRIPTION_TERMS_URL lors de la version de votre version pour ouvrir votre page de conditions hébergées à partir de l\'application.',
    'Settings controls reminders, stealth mode, and access.':
        'Les paramètres contrôlent les rappels, le mode furtif et l\'accès.',
    'Start': 'Commencer',
    'Start 15 Days Free': 'Commencez 15 jours gratuits',
    'Start or restore yearly access. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'Démarrez ou restaurez l’accès annuel. Si votre compte magasin est éligible, la plateforme peut appliquer l\'essai gratuit de 15 jours lors du paiement.',
    'Start the Google Play or App Store managed 15-day free trial, or restore your yearly access to open TempCam.':
        'Démarrez l\'essai gratuit géré de Google Play ou App Store de 15 jours, ou restaurez votre accès annuel pour ouvrir TempCam.',
    'Start with 15 days free.': 'Commencez avec 15 jours gratuits.',
    'Start your secure store-managed 15-day free trial, then continue with one yearly plan.':
        'Démarrez votre essai gratuit de 15 jours géré par la boutique sécurisée, puis poursuivez avec un forfait annuel.',
    'Stealth Notifications': 'Notifications furtives',
    'Store Trial': 'Essai en magasin',
    'Store billing is currently bypassed by a temporary app-wide test switch.':
        'La facturation du magasin est actuellement contournée par un commutateur de test temporaire à l\'échelle de l\'application.',
    'Subscription Terms': 'Conditions d\'abonnement',
    'TIMERS': 'MINUTERIES',
    'Take private photos and videos inside TempCam, keep them out of the main gallery, and let them disappear unless you keep them forever.':
        'Prenez des photos et des vidéos privées dans TempCam, gardez-les en dehors de la galerie principale et laissez-les disparaître à moins que vous ne les conserviez pour toujours.',
    'Temp media stays local to your device until you explicitly keep it forever. Recent-app previews are shielded, and sensitive actions stay protected behind biometric confirmation when enabled.':
        'Le média temporaire reste local sur votre appareil jusqu\'à ce que vous le conserviez explicitement pour toujours. Les aperçus des applications récentes sont protégés et les actions sensibles restent protégées derrière une confirmation biométrique lorsqu\'elles sont activées.',
    'Temp photos and videos are stored locally on the device inside TempCam until they expire, are deleted, or are kept forever by the user.':
        'Les photos et vidéos temporaires sont stockées localement sur l\'appareil dans TempCam jusqu\'à ce qu\'elles expirent, soient supprimées ou conservées pour toujours par l\'utilisateur.',
    'TempCam does not upload your temporary media to a cloud service inside the app flow. Subscription billing is handled by the platform store.':
        'TempCam ne télécharge pas vos médias temporaires sur un service cloud dans le flux de l\'application. La facturation des abonnements est gérée par la boutique de la plateforme.',
    'TempCam keeps sensitive captures temporary.':
        'TempCam conserve les captures sensibles temporaires.',
    'TempCam offers one auto-renewing yearly subscription for access to the app.':
        'TempCam propose un abonnement annuel à renouvellement automatique pour accéder à l\'application.',
    'Temporary by default': 'Temporaire par défaut',
    'Temporary captures stay inside TempCam instead of appearing in the main gallery.':
        'Les captures temporaires restent dans TempCam au lieu d\'apparaître dans la galerie principale.',
    'Testing': 'Essai',
    'The 15-day free trial is managed by Google Play or the App Store, so clearing app data will not restart it.':
        'L\'essai gratuit de 15 jours est géré par Google Play ou App Store, donc la suppression des données de l\'application ne la redémarrera pas.',
    'The vault keeps temp media private first.':
        'Le coffre-fort garde d\'abord les médias temporaires privés.',
    'This build bypasses subscriptions so you can test TempCam on your phone before store upload.':
        'Cette version contourne les abonnements afin que vous puissiez tester TempCam sur votre téléphone avant le téléchargement dans la boutique.',
    'This filter only shows temp photos stored inside TempCam.':
        'Ce filtre affiche uniquement les photos temporaires stockées dans TempCam.',
    'This filter only shows temp videos stored inside TempCam.':
        'Ce filtre affiche uniquement les vidéos temporaires stockées dans TempCam.',
    'Trial Then Yearly': 'Essai puis annuel',
    'Trusted Vault History': 'Historique du coffre-fort approuvé',
    'Unable to export this item to the main gallery.':
        'Impossible d\'exporter cet élément vers la galerie principale.',
    'Unable to import media right now.':
        'Impossible d\'importer des médias pour le moment.',
    'Unable to use video recording right now.':
        'Impossible d\'utiliser l\'enregistrement vidéo pour le moment.',
    'Unlock Premium': 'Débloquez la prime',
    'Unlock Premium to use the 7 day timer.':
        'Débloquez Premium pour utiliser la minuterie de 7 jours.',
    'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and Panic Exit for faster privacy under pressure.':
        'Utilisez la protection biométrique, le mode de confidentialité de session, le délai d\'expiration rapide du verrouillage, l\'aperçu des données récentes protégées et la sortie panique pour une confidentialité plus rapide sous pression.',
    'Use photo or video mode, tap to focus, pinch to zoom, control flash, and review the private preview before you apply the timer.':
        'Utilisez le mode photo ou vidéo, appuyez pour faire la mise au point, pincez pour zoomer, contrôlez le flash et consultez l\'aperçu privé avant d\'appliquer la minuterie.',
    'Users can restore purchases after reinstall and can manage or cancel subscriptions from their platform subscription settings.':
        'Les utilisateurs peuvent restaurer leurs achats après la réinstallation et gérer ou annuler les abonnements à partir des paramètres d\'abonnement de leur plateforme.',
    'VAULT': 'SAUTER',
    'Video auto-deleted': 'Vidéo supprimée automatiquement',
    'Video deleted now': 'Vidéo supprimée maintenant',
    'Video kept forever': 'Vidéo conservée pour toujours',
    'Video kept forever and exported.':
        'Vidéo conservée pour toujours et exportée.',
    'Video saved to TempCam': 'Vidéo enregistrée sur TempCam',
    'View Access Options': 'Afficher les options d\'accès',
    'View Yearly Plan': 'Voir le plan annuel',
    'WELCOME': 'ACCUEILLIR',
    'Waiting for store confirmation...':
        'En attente de confirmation du magasin...',
    'Walk through camera, timers, vault, security, and settings again any time.':
        'Parcourez à tout moment la caméra, les minuteries, le coffre-fort, la sécurité et les paramètres.',
    'What TempCam does not do': 'Ce que TempCam ne fait pas',
    'What TempCam stores': 'Ce que TempCam stocke',
    'Why People Use TempCam': 'Pourquoi les gens utilisent TempCam',
    'YEARLY ACCESS': 'ACCÈS ANNUEL',
    'Yearly Billing': 'Facturation annuelle',
    'Yearly access powers TempCam.': 'Pouvoirs d\'accès annuels TempCam.',
    'Yearly access unlocked. TempCam is ready to use.':
        'Accès annuel débloqué. TempCam est prêt à être utilisé.',
    'You can skip this now and reopen it any time from Settings.':
        'Vous pouvez ignorer cette opération maintenant et la rouvrir à tout moment à partir des paramètres.',
    'Your access is live.': 'Votre accès est en direct.',
    'Your current subscription is active through the store.':
        'Votre abonnement actuel est actif via la boutique.',
    'Your subscription is handled directly by the App Store or Google Play with one yearly plan.':
        'Votre abonnement est géré directement par le App Store ou le Google Play avec un forfait annuel.',
    'Your vault is empty': 'Votre coffre-fort est vide',
    'Your yearly subscription has been restored.':
        'Votre abonnement annuel a été rétabli.',
    'Your yearly subscription is active.': 'Votre abonnement annuel est actif.',
    '{count} items deleted from TempCam.':
        '{count} éléments supprimés de TempCam.',
    '{count} items imported into TempCam, but {failed} original items could not be removed from the main gallery.':
        'Les éléments {count} ont été importés dans TempCam, mais les éléments originaux {failed} n\'ont pas pu être supprimés de la galerie principale.',
    '{count} items moved into TempCam and removed from the main gallery.':
        'Les éléments {count} ont été déplacés vers TempCam et supprimés de la galerie principale.',
    '{count} items selected for deletion.':
        '{count} éléments sélectionnés pour suppression.',
    '{count} temp items ready': '{count} articles temporaires prêts',
    '{days}d {hours}h': '{days}d {hours}h',
    '{hours}h {minutes}m': '{hours}h {minutes}m',
    '{media} expired after {timer} and was removed from TempCam.':
        '{media} a expiré après {timer} et a été supprimé de TempCam.',
    '{media} exported to the main gallery and removed from TempCam expiry.':
        '{media} exporté vers la galerie principale et supprimé à l\'expiration de TempCam.',
    '{media} removed manually before its timer ended.':
        '{media} a été supprimé manuellement avant la fin de son minuteur.',
    '{minutes}m': '{minutes}m',
  },
  'pt_BR': {
    'System Default': 'Padrao do sistema',
    'Language': 'Idioma',
    'Choose the app language. System Default follows your phone language.':
        'Escolha o idioma do app. Padrao do sistema segue o idioma do telefone.',
    'Press back again to exit TempCam':
        'Pressione voltar novamente para sair do TempCam',
    'Protected Preview': 'Previa protegida',
    '15 DAYS FREE': '15 DIAS GRATIS',
    'Start with a secure free trial.': 'Comece com um teste gratis seguro.',
    'Continue To Access': 'Continuar',
    'PRIVATE • TEMPORARY • LOCAL': 'PRIVADO • TEMPORARIO • LOCAL',
    'Preparing secure vault experience': 'Preparando cofre seguro',
    'Secure session initializing': 'Inicializando sessao segura',
    'Vault Locked': 'Cofre bloqueado',
    'Unlocking...': 'Desbloqueando...',
    'Unlock TempCam': 'Desbloquear TempCam',
    'Switching camera...': 'Trocando camera...',
    'PHOTO': 'FOTO',
    'VIDEO': 'VIDEO',
    'Tap to view': 'Toque para ver',
    'Set Self-Destruct Timer': 'Definir temporizador',
    'Apply Timer': 'Aplicar temporizador',
    'Private Vault': 'Cofre privado',
    'Expiring in': 'Expira em',
    'Created': 'Criado',
    'Private Video': 'Video privado',
    'Private Photo': 'Foto privada',
    'Extend Timer': 'Estender temporizador',
    'Keep Forever': 'Manter para sempre',
    'Delete Now': 'Excluir agora',
    'Skip': 'Pular',
    'Back': 'Voltar',
    'Get Started': 'Comecar',
    'Next': 'Proximo',
    'Manage Access': 'Gerenciar acesso',
    'Open Camera': 'Abrir camera',
    'Open Vault': 'Abrir cofre',
    'All': 'Tudo',
    'Photos': 'Fotos',
    'Videos': 'Videos',
    'Cancel': 'Cancelar',
    'Delete': 'Excluir',
    'Restore Purchase': 'Restaurar compra',
    'Privacy Policy': 'Politica de privacidade',
    'Terms': 'Termos',
    'Capture': 'Capturar',
    'Done': 'Concluido',
    'Select': 'Selecionar',
    'FREE TRIAL': 'TESTE GRATIS',
    'ACTIVE': 'ATIVO',
    'REQUIRED': 'OBRIGATORIO',
    'Camera is unavailable.': 'A camera nao esta disponivel.',
    'Video': 'Video',
    'Photo': 'Foto',
    '1 Hour': '1 hora',
    '12 Hours': '12 horas',
    '15 Seconds': '15 segundos',
    '24 Hours': '24 horas',
    '3 Days': '3 dias',
    '3 Hours': '3 horas',
    '30 Seconds': '30 segundos',
    '5 Seconds': '5 segundos',
    '7 Days': '7 dias',
    '7 day timers are available with Premium.':
        'Temporizadores de 7 dias estão disponíveis no Premium.',
    'A {price} yearly subscription keeps TempCam private, temporary, and fully unlocked.':
        'Uma assinatura anual {price} mantém TempCam privado, temporário e totalmente desbloqueado.',
    'APP TOUR': 'TOUR DO APLICATIVO',
    'Access Active': 'Acesso ativo',
    'Access Required': 'Acesso necessário',
    'Access is recorded until {date}.': 'O acesso é registrado até {date}.',
    'Access recorded until {date}': 'Acesso registrado até {date}',
    'After the trial ends, Google Play continues the subscription at {price} per year unless the user cancels in time.':
        'Após o término da avaliação, Google Play continuará a assinatura por {price} por ano, a menos que o usuário cancele a tempo.',
    'All Media': 'Todas as mídias',
    'Annual Access': 'Acesso Anual',
    'Authenticating now. If the prompt does not appear, tap below to unlock TempCam.':
        'Autenticando agora. Se o prompt não aparecer, toque abaixo para desbloquear TempCam.',
    'Auto-renewing yearly subscription. Cancel anytime in Google Play or App Store subscriptions.':
        'Assinatura anual com renovação automática. Cancele a qualquer momento nas assinaturas Google Play ou App Store.',
    'Before release': 'Antes do lançamento',
    'Billing': 'Cobrança',
    'Biometric Lock': 'Bloqueio Biométrico',
    'Biometric protection is unavailable on this device.':
        'A proteção biométrica não está disponível neste dispositivo.',
    'Biometrics are unavailable on this device. Continue without biometric lock from settings.':
        'A biometria não está disponível neste dispositivo. Continue sem bloqueio biométrico nas configurações.',
    'Biometrics, quick relock, and Panic Exit stay ready.':
        'Biometria, rebloqueio rápido e saída de pânico permanecem prontos.',
    'Browse all temp photos and videos, focus on what is expiring, and clean up quickly when you need to.':
        'Navegue por todas as fotos e vídeos temporários, concentre-se no que está expirando e limpe rapidamente quando precisar.',
    'Browse photos and videos in the private vault, filter by type, import existing media into TempCam, extend timers, or delete items when you need to.':
        'Navegue por fotos e vídeos no cofre privado, filtre por tipo, importe mídia existente para TempCam, estenda temporizadores ou exclua itens quando necessário.',
    'Buy 1 Year For {price}': 'Compre 1 ano por {price}',
    'Buy or restore yearly access to open TempCam. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'Compre ou restaure o acesso anual para abrir TempCam. Se a conta da sua loja for elegível, a plataforma poderá aplicar o teste gratuito de 15 dias durante a finalização da compra.',
    'CAMERA': 'CÂMERA',
    'Capture Defaults': 'Capturar padrões',
    'Capture a photo or video and it will appear here with its self-destruct timer.':
        'Capture uma foto ou vídeo e ele aparecerá aqui com seu temporizador de autodestruição.',
    'Capture quickly with the private camera.':
        'Capture rapidamente com a câmera privada.',
    'Choose a timer after capture or import. If you skip it, TempCam uses your default timer from Settings.':
        'Escolha um cronômetro após a captura ou importação. Se você pular, TempCam usará seu timer padrão em Configurações.',
    'Choose how long TempCam can stay in the background before it asks for biometrics again.':
        'Escolha quanto tempo TempCam pode permanecer em segundo plano antes de solicitar biometria novamente.',
    'Choose how long new captures stay available by default.':
        'Escolha por quanto tempo as novas capturas permanecem disponíveis por padrão.',
    'Choose items to delete.': 'Escolha os itens a serem excluídos.',
    'Choose when this capture evaporates from the vault.':
        'Escolha quando esta captura evapora do cofre.',
    'Close TempCam immediately and relock on return.':
        'Feche TempCam imediatamente e bloqueie novamente no retorno.',
    'Connecting To Store...': 'Conectando à loja...',
    'Default Self-Destruct Timer': 'Temporizador de autodestruição padrão',
    'Default {timer}': 'Padrão {timer}',
    'Defaults to 24 hours if skipped.': 'O padrão é 24 horas se ignorado.',
    'Directly billed and renewed by the platform store.':
        'Faturado diretamente e renovado pela loja da plataforma.',
    'Disable TEMPCAM_DISABLE_PAYMENTS before uploading to the store.':
        'Desative TEMPCAM_DISABLE_PAYMENTS antes de fazer upload para a loja.',
    'Done ({count})': 'Concluído ({count})',
    'Enable Biometric Lock first to use instant session relocking.':
        'Ative primeiro o bloqueio biométrico para usar o rebloqueio instantâneo da sessão.',
    'Encrypted Vault': 'Cofre criptografado',
    'Every item gets a self-destruct timer.':
        'Cada item recebe um temporizador de autodestruição.',
    'Every temporary moment, in one calm vault.':
        'Cada momento temporário, num cofre calmo.',
    'Expired': 'Expirado',
    'Expiring Soon': 'Expirando em breve',
    'Expiry Notifications': 'Notificações de expiração',
    'Fallback price shown until the store catalog loads.':
        'Preço alternativo mostrado até o catálogo da loja ser carregado.',
    'Fast under pressure': 'Rápido sob pressão',
    'Finish the current capture before importing media.':
        'Conclua a captura atual antes de importar a mídia.',
    'Flash auto': 'Flash automático',
    'Flash is unavailable on this camera.':
        'O flash não está disponível nesta câmera.',
    'Flash off': 'Flash desligado',
    'Flash on': 'Flash ativado',
    'Flash torch': 'Lanterna',
    'Forever': 'Para sempre',
    'Get warned before temporary media disappears.':
        'Seja avisado antes que a mídia temporária desapareça.',
    'Google Play or the App Store can start a secure 15-day free trial for eligible accounts before yearly billing begins.':
        'Google Play ou App Store podem iniciar um teste gratuito seguro de 15 dias para contas qualificadas antes do início do faturamento anual.',
    'Google Play will start your 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'Google Play iniciará seu teste gratuito de 15 dias quando você iniciar a assinatura anual. Esta avaliação está vinculada à conta da loja, portanto, limpar os dados do aplicativo não o reiniciará.',
    'Help': 'Ajuda',
    'Hide photo and video wording in reminders for a quieter lock-screen presence.':
        'Oculte o texto das fotos e vídeos nos lembretes para uma presença mais silenciosa na tela de bloqueio.',
    'If eligible, checkout starts with the store-managed 15-day free trial and then renews yearly.':
        'Se for elegível, a finalização da compra começa com o teste gratuito de 15 dias gerenciado pela loja e é renovado anualmente.',
    'If your Google Play account is eligible, the store will offer a 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'Se sua conta Google Play for elegível, a loja oferecerá um teste gratuito de 15 dias quando você iniciar a assinatura anual. Esta avaliação está vinculada à conta da loja, portanto, limpar os dados do aplicativo não o reiniciará.',
    'Keep Forever exports, manual deletions, and auto-deletions will appear here as a local trust log.':
        'As exportações, exclusões manuais e exclusões automáticas do Keep Forever aparecerão aqui como um registro de confiança local.',
    'Kept Forever': 'Mantido para sempre',
    'LOCAL PRIVATE STORAGE': 'ARMAZENAMENTO PRIVADO LOCAL',
    'LOCAL | TEMPORARY | PROTECTED': 'LOCAL | TEMPORÁRIO | PROTEGIDO',
    'Local record of exports, deletions, and auto-deletions.':
        'Registro local de exportações, exclusões e exclusões automáticas.',
    'Lock TempCam immediately whenever the app loses focus.':
        'Bloqueie TempCam imediatamente sempre que o aplicativo perder o foco.',
    'Manage TempCam Access': 'Gerenciar acesso TempCam',
    'Manage expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.':
        'Gerencie notificações de expiração, texto de notificação furtiva, temporizadores padrão, acesso à assinatura e reabra este tour a qualquer momento em Configurações.',
    'Managing access': 'Gerenciando o acesso',
    'Media no longer exists.': 'A mídia não existe mais.',
    'No temp photos yet': 'Ainda não há fotos temporárias',
    'No temp videos yet': 'Ainda não há vídeos temporários',
    'Once the subscription or trial is active, TempCam unlocks fully and can re-lock with biometrics.':
        'Assim que a assinatura ou avaliação estiver ativa, TempCam é totalmente desbloqueado e pode ser bloqueado novamente com biometria.',
    'One auto-renewing yearly subscription managed directly by Google Play or the App Store.':
        'Uma assinatura anual com renovação automática gerenciada diretamente por Google Play ou App Store.',
    'Only Plan': 'Apenas plano',
    'Open, capture, review, and protect sensitive moments with fewer steps.':
        'Abra, capture, revise e proteja momentos delicados com menos etapas.',
    'PAYMENT OFF': 'PAGAMENTO DESLIGADO',
    'Panic Exit': 'Saída de pânico',
    'Panic Exit and quick relocking help when you need privacy right away.':
        'A saída de pânico e o rebloqueio rápido ajudam quando você precisa de privacidade imediatamente.',
    'Payment Disabled For Testing': 'Pagamento desativado para teste',
    'Payment is charged by Google Play or the App Store at confirmation of purchase. Subscriptions renew automatically unless canceled before the renewal date.':
        'O pagamento é cobrado até Google Play ou App Store na confirmação da compra. As assinaturas são renovadas automaticamente, a menos que sejam canceladas antes da data de renovação.',
    'Payments Disabled Temporarily': 'Pagamentos desativados temporariamente',
    'Photo auto-deleted': 'Foto excluída automaticamente',
    'Photo deleted now': 'Foto excluída agora',
    'Photo kept forever': 'Foto guardada para sempre',
    'Photo kept forever and exported.':
        'Foto guardada para sempre e exportada.',
    'Photos and videos auto-delete unless you decide to keep them forever.':
        'Fotos e vídeos são excluídos automaticamente, a menos que você decida mantê-los para sempre.',
    'Plan': 'Plano',
    'Premium Only': 'Somente Premium',
    'Privacy Notes': 'Notas de privacidade',
    'Private Preview': 'Visualização privada',
    'Private by design': 'Privado por design',
    'Protect app entry and sensitive actions with biometrics.':
        'Proteja a entrada de aplicativos e ações confidenciais com biometria.',
    'Quick Lock Timeout': 'Tempo limite de bloqueio rápido',
    'Recording started': 'Gravação iniciada',
    'Recover your yearly access from the App Store or Google Play on reinstall.':
        'Recupere seu acesso anual de App Store ou Google Play na reinstalação.',
    'Release setup': 'Configuração de lançamento',
    'Replay App Tour': 'Repetir tour pelo aplicativo',
    'Replay Tour': 'Tour de repetição',
    'Restore Support': 'Restaurar suporte',
    'Restore request sent to the store.':
        'Solicitação de restauração enviada para a loja.',
    'Review this private photo before setting its timer.':
        'Revise esta foto privada antes de definir o cronômetro.',
    'Review this private video before setting its timer.':
        'Revise este vídeo privado antes de definir o cronômetro.',
    'SECURITY': 'SEGURANÇA',
    'SETTINGS': 'CONFIGURAÇÕES',
    'Secure Access': 'Acesso seguro',
    'Security': 'Segurança',
    'Session Privacy Mode': 'Modo de privacidade da sessão',
    'Session Privacy Mode locks instantly, so timeout is bypassed.':
        'O modo de privacidade da sessão é bloqueado instantaneamente, portanto o tempo limite é ignorado.',
    'Set TEMPCAM_PRIVACY_POLICY_URL during your release build to open your hosted policy page from the app.':
        'Defina TEMPCAM_PRIVACY_POLICY_URL durante a versão de lançamento para abrir a página de política hospedada no aplicativo.',
    'Set TEMPCAM_SUBSCRIPTION_TERMS_URL during your release build to open your hosted terms page from the app.':
        'Defina TEMPCAM_SUBSCRIPTION_TERMS_URL durante a versão de lançamento para abrir a página de termos hospedados no aplicativo.',
    'Settings controls reminders, stealth mode, and access.':
        'As configurações controlam lembretes, modo furtivo e acesso.',
    'Start': 'Começar',
    'Start 15 Days Free': 'Comece 15 dias grátis',
    'Start or restore yearly access. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'Inicie ou restaure o acesso anual. Se a conta da sua loja for elegível, a plataforma poderá aplicar o teste gratuito de 15 dias durante a finalização da compra.',
    'Start the Google Play or App Store managed 15-day free trial, or restore your yearly access to open TempCam.':
        'Inicie o teste gratuito gerenciado de Google Play ou App Store por 15 dias ou restaure seu acesso anual para abrir TempCam.',
    'Start with 15 days free.': 'Comece com 15 dias grátis.',
    'Start your secure store-managed 15-day free trial, then continue with one yearly plan.':
        'Comece seu teste gratuito de 15 dias gerenciado pela loja segura e continue com um plano anual.',
    'Stealth Notifications': 'Notificações furtivas',
    'Store Trial': 'Teste da loja',
    'Store billing is currently bypassed by a temporary app-wide test switch.':
        'Atualmente, o faturamento da loja é ignorado por uma mudança temporária de teste em todo o aplicativo.',
    'Subscription Terms': 'Termos de assinatura',
    'TIMERS': 'TEMPORIZADORES',
    'Take private photos and videos inside TempCam, keep them out of the main gallery, and let them disappear unless you keep them forever.':
        'Tire fotos e vídeos privados dentro de TempCam, mantenha-os fora da galeria principal e deixe-os desaparecer, a menos que você os guarde para sempre.',
    'Temp media stays local to your device until you explicitly keep it forever. Recent-app previews are shielded, and sensitive actions stay protected behind biometric confirmation when enabled.':
        'A mídia temporária permanece local no seu dispositivo até que você a mantenha explicitamente para sempre. As visualizações recentes de aplicativos são protegidas e as ações confidenciais permanecem protegidas pela confirmação biométrica quando ativadas.',
    'Temp photos and videos are stored locally on the device inside TempCam until they expire, are deleted, or are kept forever by the user.':
        'Fotos e vídeos temporários são armazenados localmente no dispositivo dentro de TempCam até expirarem, serem excluídos ou mantidos para sempre pelo usuário.',
    'TempCam does not upload your temporary media to a cloud service inside the app flow. Subscription billing is handled by the platform store.':
        'TempCam não carrega sua mídia temporária em um serviço de nuvem dentro do fluxo do aplicativo. O faturamento da assinatura é feito pela loja da plataforma.',
    'TempCam keeps sensitive captures temporary.':
        'TempCam mantém capturas confidenciais temporárias.',
    'TempCam offers one auto-renewing yearly subscription for access to the app.':
        'TempCam oferece uma assinatura anual com renovação automática para acesso ao aplicativo.',
    'Temporary by default': 'Temporário por padrão',
    'Temporary captures stay inside TempCam instead of appearing in the main gallery.':
        'As capturas temporárias ficam dentro de TempCam em vez de aparecerem na galeria principal.',
    'Testing': 'Teste',
    'The 15-day free trial is managed by Google Play or the App Store, so clearing app data will not restart it.':
        'A avaliação gratuita de 15 dias é gerenciada por Google Play ou App Store, portanto, a limpeza dos dados do aplicativo não o reiniciará.',
    'The vault keeps temp media private first.':
        'O cofre mantém a mídia temporária privada primeiro.',
    'This build bypasses subscriptions so you can test TempCam on your phone before store upload.':
        'Esta compilação ignora assinaturas para que você possa testar TempCam em seu telefone antes do upload para a loja.',
    'This filter only shows temp photos stored inside TempCam.':
        'Este filtro mostra apenas fotos temporárias armazenadas dentro de TempCam.',
    'This filter only shows temp videos stored inside TempCam.':
        'Este filtro mostra apenas vídeos temporários armazenados em TempCam.',
    'Trial Then Yearly': 'Teste e depois anualmente',
    'Trusted Vault History': 'Histórico confiável do Vault',
    'Unable to export this item to the main gallery.':
        'Não foi possível exportar este item para a galeria principal.',
    'Unable to import media right now.':
        'Não é possível importar mídia no momento.',
    'Unable to use video recording right now.':
        'Não é possível usar a gravação de vídeo no momento.',
    'Unlock Premium': 'Desbloquear Premium',
    'Unlock Premium to use the 7 day timer.':
        'Desbloqueie o Premium para usar o cronômetro de 7 dias.',
    'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and Panic Exit for faster privacy under pressure.':
        'Use proteção biométrica, modo de privacidade de sessão, tempo limite de bloqueio rápido, visualização recente protegida e saída de pânico para privacidade mais rápida sob pressão.',
    'Use photo or video mode, tap to focus, pinch to zoom, control flash, and review the private preview before you apply the timer.':
        'Use o modo foto ou vídeo, toque para focar, aperte para ampliar, controle o flash e revise a visualização privada antes de aplicar o cronômetro.',
    'Users can restore purchases after reinstall and can manage or cancel subscriptions from their platform subscription settings.':
        'Os usuários podem restaurar as compras após a reinstalação e gerenciar ou cancelar assinaturas nas configurações de assinatura da plataforma.',
    'VAULT': 'COFRE',
    'Video auto-deleted': 'Vídeo excluído automaticamente',
    'Video deleted now': 'Vídeo excluído agora',
    'Video kept forever': 'Vídeo guardado para sempre',
    'Video kept forever and exported.':
        'Vídeo guardado para sempre e exportado.',
    'Video saved to TempCam': 'Vídeo salvo em TempCam',
    'View Access Options': 'Ver opções de acesso',
    'View Yearly Plan': 'Ver plano anual',
    'WELCOME': 'BEM-VINDO',
    'Waiting for store confirmation...': 'Aguardando confirmação da loja...',
    'Walk through camera, timers, vault, security, and settings again any time.':
        'Percorra a câmera, os temporizadores, o cofre, a segurança e as configurações novamente a qualquer momento.',
    'What TempCam does not do': 'O que TempCam não faz',
    'What TempCam stores': 'O que TempCam armazena',
    'Why People Use TempCam': 'Por que as pessoas usam TempCam',
    'YEARLY ACCESS': 'ACESSO ANUAL',
    'Yearly Billing': 'Faturamento Anual',
    'Yearly access powers TempCam.': 'Poderes de acesso anuais TempCam.',
    'Yearly access unlocked. TempCam is ready to use.':
        'Acesso anual desbloqueado. TempCam está pronto para uso.',
    'You can skip this now and reopen it any time from Settings.':
        'Você pode pular isso agora e reabri-lo a qualquer momento em Configurações.',
    'Your access is live.': 'Seu acesso é ao vivo.',
    'Your current subscription is active through the store.':
        'Sua assinatura atual está ativa na loja.',
    'Your subscription is handled directly by the App Store or Google Play with one yearly plan.':
        'Sua assinatura é gerenciada diretamente pelo App Store ou Google Play com um plano anual.',
    'Your vault is empty': 'Seu cofre está vazio',
    'Your yearly subscription has been restored.':
        'Sua assinatura anual foi restaurada.',
    'Your yearly subscription is active.': 'Sua assinatura anual está ativa.',
    '{count} items deleted from TempCam.':
        '{count} itens excluídos de TempCam.',
    '{count} items imported into TempCam, but {failed} original items could not be removed from the main gallery.':
        '{count} itens importados para TempCam, mas {failed} itens originais não puderam ser removidos da galeria principal.',
    '{count} items moved into TempCam and removed from the main gallery.':
        '{count} itens movidos para TempCam e removidos da galeria principal.',
    '{count} items selected for deletion.':
        '{count} itens selecionados para exclusão.',
    '{count} temp items ready': '{count} itens temporários prontos',
    '{days}d {hours}h': '{days}d {hours}h',
    '{hours}h {minutes}m': '{hours}h {minutes}m',
    '{media} expired after {timer} and was removed from TempCam.':
        '{media} expirou após {timer} e foi removido de TempCam.',
    '{media} exported to the main gallery and removed from TempCam expiry.':
        '{media} exportado para a galeria principal e removido da expiração de TempCam.',
    '{media} removed manually before its timer ended.':
        '{media} removido manualmente antes do término do cronômetro.',
    '{minutes}m': '{minutes}m',
  },
  'ru': {
    'System Default': 'Системный язык',
    'Language': 'Язык',
    'Choose the app language. System Default follows your phone language.':
        'Выберите язык приложения. Системный режим использует язык телефона.',
    'Press back again to exit TempCam':
        'Нажмите назад еще раз, чтобы выйти из TempCam',
    'Protected Preview': 'Защищенный просмотр',
    '15 DAYS FREE': '15 ДНЕЙ БЕСПЛАТНО',
    'Start with a secure free trial.':
        'Начните с безопасного бесплатного пробного периода.',
    'Continue To Access': 'Продолжить',
    'PRIVATE • TEMPORARY • LOCAL': 'ПРИВАТНО • ВРЕМЕННО • ЛОКАЛЬНО',
    'Preparing secure vault experience': 'Подготовка безопасного хранилища',
    'Secure session initializing': 'Запуск безопасной сессии',
    'Vault Locked': 'Хранилище заблокировано',
    'Unlocking...': 'Разблокировка...',
    'Unlock TempCam': 'Разблокировать TempCam',
    'Switching camera...': 'Переключение камеры...',
    'PHOTO': 'ФОТО',
    'VIDEO': 'ВИДЕО',
    'Tap to view': 'Нажмите для просмотра',
    'Set Self-Destruct Timer': 'Установить таймер',
    'Apply Timer': 'Применить таймер',
    'Private Vault': 'Приватное хранилище',
    'Expiring in': 'Истекает через',
    'Created': 'Создано',
    'Private Video': 'Приватное видео',
    'Private Photo': 'Приватное фото',
    'Extend Timer': 'Продлить таймер',
    'Keep Forever': 'Сохранить навсегда',
    'Delete Now': 'Удалить сейчас',
    'Skip': 'Пропустить',
    'Back': 'Назад',
    'Get Started': 'Начать',
    'Next': 'Далее',
    'Manage Access': 'Управлять доступом',
    'Open Camera': 'Открыть камеру',
    'Open Vault': 'Открыть хранилище',
    'All': 'Все',
    'Photos': 'Фото',
    'Videos': 'Видео',
    'Cancel': 'Отмена',
    'Delete': 'Удалить',
    'Restore Purchase': 'Восстановить покупку',
    'Privacy Policy': 'Политика конфиденциальности',
    'Terms': 'Условия',
    'Capture': 'Снять',
    'Done': 'Готово',
    'Select': 'Выбрать',
    'FREE TRIAL': 'БЕСПЛАТНО',
    'ACTIVE': 'АКТИВНО',
    'REQUIRED': 'ТРЕБУЕТСЯ',
    'Camera is unavailable.': 'Камера недоступна.',
    'Video': 'Видео',
    'Photo': 'Фото',
    '1 Hour': '1 час',
    '12 Hours': '12 часов',
    '15 Seconds': '15 секунд',
    '24 Hours': '24 часа',
    '3 Days': '3 дня',
    '3 Hours': '3 часа',
    '30 Seconds': '30 секунд',
    '5 Seconds': '5 секунд',
    '7 Days': '7 дней',
    '7 day timers are available with Premium.':
        '7-дневные таймеры доступны с Premium.',
    'A {price} yearly subscription keeps TempCam private, temporary, and fully unlocked.':
        'Годовая подписка {price} делает TempCam конфиденциальным, временным и полностью разблокированным.',
    'APP TOUR': 'ПРИЛОЖЕНИЕ ТУР',
    'Access Active': 'Доступ активен',
    'Access Required': 'Требуется доступ',
    'Access is recorded until {date}.': 'Доступ фиксируется до {date}.',
    'Access recorded until {date}': 'Доступ зарегистрирован до {date}',
    'After the trial ends, Google Play continues the subscription at {price} per year unless the user cancels in time.':
        'После окончания пробного периода Google Play продолжит подписку по цене {price} в год, если пользователь не отменит ее вовремя.',
    'All Media': 'Все СМИ',
    'Annual Access': 'Годовой доступ',
    'Authenticating now. If the prompt does not appear, tap below to unlock TempCam.':
        'Аутентификация сейчас. Если подсказка не появляется, нажмите ниже, чтобы разблокировать TempCam.',
    'Auto-renewing yearly subscription. Cancel anytime in Google Play or App Store subscriptions.':
        'Автоматическое продление годовой подписки. Отмените подписку Google Play или App Store в любое время.',
    'Before release': 'До выпуска',
    'Billing': 'Биллинг',
    'Biometric Lock': 'Биометрический замок',
    'Biometric protection is unavailable on this device.':
        'Биометрическая защита на этом устройстве недоступна.',
    'Biometrics are unavailable on this device. Continue without biometric lock from settings.':
        'Биометрические данные на этом устройстве недоступны. Продолжить без биометрической блокировки в настройках.',
    'Biometrics, quick relock, and Panic Exit stay ready.':
        'Биометрия, быстрая повторная блокировка и аварийный выход остаются наготове.',
    'Browse all temp photos and videos, focus on what is expiring, and clean up quickly when you need to.':
        'Просматривайте все временные фотографии и видео, сосредоточьтесь на том, что истекает, и быстро очищайте их, когда это необходимо.',
    'Browse photos and videos in the private vault, filter by type, import existing media into TempCam, extend timers, or delete items when you need to.':
        'Просматривайте фотографии и видео в личном хранилище, фильтруйте по типу, импортируйте существующие медиафайлы в TempCam, продлевайте таймеры или удаляйте элементы, когда вам нужно.',
    'Buy 1 Year For {price}': 'Купить 1 год за {price}',
    'Buy or restore yearly access to open TempCam. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'Купите или восстановите годовой доступ, чтобы открыть TempCam. Если ваша учетная запись магазина соответствует критериям, платформа может применить 15-дневную бесплатную пробную версию во время оформления заказа.',
    'CAMERA': 'КАМЕРА',
    'Capture Defaults': 'Захват настроек по умолчанию',
    'Capture a photo or video and it will appear here with its self-destruct timer.':
        'Сделайте фото или видео, и оно появится здесь с таймером самоуничтожения.',
    'Capture quickly with the private camera.':
        'Снимайте быстро с помощью частной камеры.',
    'Choose a timer after capture or import. If you skip it, TempCam uses your default timer from Settings.':
        'Выберите таймер после захвата или импорта. Если вы пропустите его, TempCam будет использовать таймер по умолчанию из настроек.',
    'Choose how long TempCam can stay in the background before it asks for biometrics again.':
        'Выберите, как долго TempCam может оставаться в фоновом режиме, прежде чем снова запросит биометрические данные.',
    'Choose how long new captures stay available by default.':
        'Выберите, как долго новые снимки будут доступны по умолчанию.',
    'Choose items to delete.': 'Выберите элементы для удаления.',
    'Choose when this capture evaporates from the vault.':
        'Выберите, когда этот захват испарится из хранилища.',
    'Close TempCam immediately and relock on return.':
        'Немедленно закройте TempCam и заблокируйте его по возвращении.',
    'Connecting To Store...': 'Подключение к магазину...',
    'Default Self-Destruct Timer': 'Таймер самоуничтожения по умолчанию',
    'Default {timer}': 'По умолчанию {timer}',
    'Defaults to 24 hours if skipped.': 'По умолчанию 24 часа, если пропущено.',
    'Directly billed and renewed by the platform store.':
        'Счета выставляются и продлеваются напрямую магазином платформы.',
    'Disable TEMPCAM_DISABLE_PAYMENTS before uploading to the store.':
        'Отключите TEMPCAM_DISABLE_PAYMENTS перед загрузкой в ​​магазин.',
    'Done ({count})': 'Готово ({count})',
    'Enable Biometric Lock first to use instant session relocking.':
        'Сначала включите биометрическую блокировку, чтобы использовать мгновенную повторную блокировку сеанса.',
    'Encrypted Vault': 'Зашифрованное хранилище',
    'Every item gets a self-destruct timer.':
        'Каждый предмет имеет таймер самоуничтожения.',
    'Every temporary moment, in one calm vault.':
        'Каждое временное мгновение, в одном спокойном своде.',
    'Expired': 'Истекший',
    'Expiring Soon': 'Срок действия скоро истекает',
    'Expiry Notifications': 'Уведомления об истечении срока действия',
    'Fallback price shown until the store catalog loads.':
        'Резервная цена отображается до тех пор, пока не загрузится каталог магазина.',
    'Fast under pressure': 'Быстро под давлением',
    'Finish the current capture before importing media.':
        'Завершите текущий захват перед импортом мультимедиа.',
    'Flash auto': 'Вспышка авто',
    'Flash is unavailable on this camera.':
        'Вспышка недоступна на этой камере.',
    'Flash off': 'Вспышка выключена',
    'Flash on': 'Вспышка включена',
    'Flash torch': 'Вспышка фонарика',
    'Forever': 'Навсегда',
    'Get warned before temporary media disappears.':
        'Получите предупреждение, прежде чем временные носители исчезнут.',
    'Google Play or the App Store can start a secure 15-day free trial for eligible accounts before yearly billing begins.':
        'Google Play или App Store могут запустить безопасную 15-дневную бесплатную пробную версию для соответствующих учетных записей до начала ежегодного выставления счетов.',
    'Google Play will start your 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'Google Play начнет использовать 15-дневную бесплатную пробную версию, когда вы оформите годовую подписку. Эта пробная версия привязана к учетной записи магазина, поэтому очистка данных приложения не приведет к ее перезапуску.',
    'Help': 'Помощь',
    'Hide photo and video wording in reminders for a quieter lock-screen presence.':
        'Скрывайте тексты фото и видео в напоминаниях, чтобы обеспечить более тихую работу на экране блокировки.',
    'If eligible, checkout starts with the store-managed 15-day free trial and then renews yearly.':
        'Если вы имеете на это право, оформление заказа начинается с 15-дневной бесплатной пробной версии, управляемой магазином, а затем продлевается ежегодно.',
    'If your Google Play account is eligible, the store will offer a 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'Если ваша учетная запись Google Play соответствует критериям, магазин предложит 15-дневную бесплатную пробную версию, когда вы начнете оформлять годовую подписку. Эта пробная версия привязана к учетной записи магазина, поэтому очистка данных приложения не приведет к ее перезапуску.',
    'Keep Forever exports, manual deletions, and auto-deletions will appear here as a local trust log.':
        'Экспорт Keep Forever, удаление вручную и автоматическое удаление будут отображаться здесь в виде локального журнала доверия.',
    'Kept Forever': 'Хранится навсегда',
    'LOCAL PRIVATE STORAGE': 'ЛОКАЛЬНОЕ ЧАСТНОЕ ХРАНЕНИЕ',
    'LOCAL | TEMPORARY | PROTECTED': 'МЕСТНЫЙ | ВРЕМЕННЫЙ | ЗАЩИЩЕНО',
    'Local record of exports, deletions, and auto-deletions.':
        'Локальная запись экспорта, удалений и автоудалений.',
    'Lock TempCam immediately whenever the app loses focus.':
        'Блокируйте TempCam немедленно, когда приложение теряет фокус.',
    'Manage TempCam Access': 'Управление доступом к TempCam',
    'Manage expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.':
        'Управляйте уведомлениями об истечении срока действия, формулировкой скрытых уведомлений, таймерами по умолчанию, доступом к подписке и повторно открывайте этот тур в любое время из настроек.',
    'Managing access': 'Управление доступом',
    'Media no longer exists.': 'СМИ больше не существует.',
    'No temp photos yet': 'Временных фотографий пока нет',
    'No temp videos yet': 'Временных видео пока нет',
    'Once the subscription or trial is active, TempCam unlocks fully and can re-lock with biometrics.':
        'Как только подписка или пробная версия активируются, TempCam полностью разблокируется и может быть повторно заблокирован с помощью биометрических данных.',
    'One auto-renewing yearly subscription managed directly by Google Play or the App Store.':
        'Одна годовая подписка с автоматическим продлением, управляемая непосредственно Google Play или App Store.',
    'Only Plan': 'Только план',
    'Open, capture, review, and protect sensitive moments with fewer steps.':
        'Открывайте, сохраняйте, просматривайте и защищайте важные моменты, выполнив меньше действий.',
    'PAYMENT OFF': 'ВЫПЛАТА',
    'Panic Exit': 'Панический выход',
    'Panic Exit and quick relocking help when you need privacy right away.':
        'Панический выход и быстрая повторная блокировка помогают, когда вам срочно нужна конфиденциальность.',
    'Payment Disabled For Testing': 'Платеж отключен для тестирования',
    'Payment is charged by Google Play or the App Store at confirmation of purchase. Subscriptions renew automatically unless canceled before the renewal date.':
        'Оплата взимается с Google Play или App Store при подтверждении покупки. Подписки продлеваются автоматически, если они не отменены до даты продления.',
    'Payments Disabled Temporarily': 'Платежи временно отключены',
    'Photo auto-deleted': 'Фотография удалена автоматически',
    'Photo deleted now': 'Фотография удалена сейчас',
    'Photo kept forever': 'Фото останется навсегда',
    'Photo kept forever and exported.':
        'Фотография сохраняется навсегда и экспортируется.',
    'Photos and videos auto-delete unless you decide to keep them forever.':
        'Фотографии и видео удаляются автоматически, если вы не решите сохранить их навсегда.',
    'Plan': 'План',
    'Premium Only': 'Только Премиум',
    'Privacy Notes': 'Примечания о конфиденциальности',
    'Private Preview': 'Частный просмотр',
    'Private by design': 'Частный по дизайну',
    'Protect app entry and sensitive actions with biometrics.':
        'Защитите вход в приложение и конфиденциальные действия с помощью биометрии.',
    'Quick Lock Timeout': 'Тайм-аут быстрой блокировки',
    'Recording started': 'Запись началась',
    'Recover your yearly access from the App Store or Google Play on reinstall.':
        'Восстановите годовой доступ с App Store или Google Play при переустановке.',
    'Release setup': 'Настройка выпуска',
    'Replay App Tour': 'Обзор приложения Replay',
    'Replay Tour': 'Повторный тур',
    'Restore Support': 'Поддержка восстановления',
    'Restore request sent to the store.':
        'Запрос на восстановление отправлен в магазин.',
    'Review this private photo before setting its timer.':
        'Просмотрите это личное фото, прежде чем устанавливать таймер.',
    'Review this private video before setting its timer.':
        'Просмотрите это личное видео, прежде чем устанавливать таймер.',
    'SECURITY': 'БЕЗОПАСНОСТЬ',
    'SETTINGS': 'НАСТРОЙКИ',
    'Secure Access': 'Безопасный доступ',
    'Security': 'Безопасность',
    'Session Privacy Mode': 'Режим конфиденциальности сеанса',
    'Session Privacy Mode locks instantly, so timeout is bypassed.':
        'Режим конфиденциальности сеанса блокируется мгновенно, поэтому время ожидания обходит.',
    'Set TEMPCAM_PRIVACY_POLICY_URL during your release build to open your hosted policy page from the app.':
        'Установите TEMPCAM_PRIVACY_POLICY_URL во время сборки выпуска, чтобы открыть размещенную страницу политики из приложения.',
    'Set TEMPCAM_SUBSCRIPTION_TERMS_URL during your release build to open your hosted terms page from the app.':
        'Установите TEMPCAM_SUBSCRIPTION_TERMS_URL во время сборки выпуска, чтобы открыть размещенную страницу условий из приложения.',
    'Settings controls reminders, stealth mode, and access.':
        'Настройки управляют напоминаниями, скрытым режимом и доступом.',
    'Start': 'Начинать',
    'Start 15 Days Free': 'Начните 15 дней бесплатно',
    'Start or restore yearly access. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'Запустите или восстановите годовой доступ. Если ваша учетная запись магазина соответствует критериям, платформа может применить 15-дневную бесплатную пробную версию во время оформления заказа.',
    'Start the Google Play or App Store managed 15-day free trial, or restore your yearly access to open TempCam.':
        'Запустите управляемую 15-дневную бесплатную пробную версию Google Play или App Store или восстановите годовой доступ к открытию TempCam.',
    'Start with 15 days free.': 'Начните с 15 дней бесплатно.',
    'Start your secure store-managed 15-day free trial, then continue with one yearly plan.':
        'Начните пользоваться безопасной 15-дневной бесплатной пробной версией под управлением магазина, а затем перейдите к годовому плану.',
    'Stealth Notifications': 'Скрытые уведомления',
    'Store Trial': 'Пробная версия магазина',
    'Store billing is currently bypassed by a temporary app-wide test switch.':
        'Выставление счетов в магазине в настоящее время обходит временный тестовый переключатель для всего приложения.',
    'Subscription Terms': 'Условия подписки',
    'TIMERS': 'ТАЙМЕРЫ',
    'Take private photos and videos inside TempCam, keep them out of the main gallery, and let them disappear unless you keep them forever.':
        'Делайте личные фотографии и видео внутри TempCam, не допускайте их попадания в основную галерею и позволяйте им исчезнуть, если только вы не сохраните их навсегда.',
    'Temp media stays local to your device until you explicitly keep it forever. Recent-app previews are shielded, and sensitive actions stay protected behind biometric confirmation when enabled.':
        'Временные носители остаются локальными на вашем устройстве до тех пор, пока вы явно не сохраните их навсегда. Предварительный просмотр последних приложений защищен, а конфиденциальные действия остаются защищенными биометрическим подтверждением, если они включены.',
    'Temp photos and videos are stored locally on the device inside TempCam until they expire, are deleted, or are kept forever by the user.':
        'Временные фотографии и видео хранятся локально на устройстве внутри TempCam до истечения срока их действия, до тех пор, пока они не будут удалены или навсегда сохранены пользователем.',
    'TempCam does not upload your temporary media to a cloud service inside the app flow. Subscription billing is handled by the platform store.':
        'TempCam не загружает ваши временные носители в облачную службу внутри потока приложения. Оплата подписки осуществляется магазином платформы.',
    'TempCam keeps sensitive captures temporary.':
        'TempCam временно сохраняет конфиденциальные записи.',
    'TempCam offers one auto-renewing yearly subscription for access to the app.':
        'TempCam предлагает одну годовую подписку с автоматическим продлением для доступа к приложению.',
    'Temporary by default': 'Временно по умолчанию',
    'Temporary captures stay inside TempCam instead of appearing in the main gallery.':
        'Временные снимки остаются внутри TempCam, а не появляются в главной галерее.',
    'Testing': 'Тестирование',
    'The 15-day free trial is managed by Google Play or the App Store, so clearing app data will not restart it.':
        '15-дневная бесплатная пробная версия управляется Google Play или App Store, поэтому очистка данных приложения не приведет к ее перезапуску.',
    'The vault keeps temp media private first.':
        'Хранилище в первую очередь сохраняет конфиденциальность временных носителей.',
    'This build bypasses subscriptions so you can test TempCam on your phone before store upload.':
        'Эта сборка обходит подписку, поэтому вы можете протестировать TempCam на своем телефоне перед загрузкой в ​​магазин.',
    'This filter only shows temp photos stored inside TempCam.':
        'Этот фильтр показывает только временные фотографии, хранящиеся внутри TempCam.',
    'This filter only shows temp videos stored inside TempCam.':
        'Этот фильтр показывает только временные видео, хранящиеся внутри TempCam.',
    'Trial Then Yearly': 'Испытание, затем ежегодно',
    'Trusted Vault History': 'Доверенная история хранилища',
    'Unable to export this item to the main gallery.':
        'Невозможно экспортировать этот объект в главную галерею.',
    'Unable to import media right now.':
        'Сейчас невозможно импортировать медиафайлы.',
    'Unable to use video recording right now.':
        'Сейчас невозможно использовать видеозапись.',
    'Unlock Premium': 'Разблокировать Премиум',
    'Unlock Premium to use the 7 day timer.':
        'Разблокируйте Премиум, чтобы использовать таймер на 7 дней.',
    'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and Panic Exit for faster privacy under pressure.':
        'Используйте биометрическую защиту, режим конфиденциальности сеанса, быстрый тайм-аут блокировки, защищенный предварительный просмотр последних событий и аварийный выход для более быстрой конфиденциальности в сложных ситуациях.',
    'Use photo or video mode, tap to focus, pinch to zoom, control flash, and review the private preview before you apply the timer.':
        'Используйте режим фото или видео, коснитесь, чтобы сфокусироваться, сведите пальцы, чтобы увеличить масштаб, управляйте вспышкой и просмотрите приватный предварительный просмотр, прежде чем применять таймер.',
    'Users can restore purchases after reinstall and can manage or cancel subscriptions from their platform subscription settings.':
        'Пользователи могут восстанавливать покупки после переустановки, а также управлять подписками или отменять их в настройках подписки своей платформы.',
    'VAULT': 'СЕЙФ',
    'Video auto-deleted': 'Видео автоматически удалено',
    'Video deleted now': 'Видео сейчас удалено',
    'Video kept forever': 'Видео хранится вечно',
    'Video kept forever and exported.':
        'Видео сохраняется навсегда и экспортируется.',
    'Video saved to TempCam': 'Видео сохранено в TempCam.',
    'View Access Options': 'Посмотреть варианты доступа',
    'View Yearly Plan': 'Посмотреть годовой план',
    'WELCOME': 'ДОБРО ПОЖАЛОВАТЬ',
    'Waiting for store confirmation...': 'Жду подтверждения от магазина...',
    'Walk through camera, timers, vault, security, and settings again any time.':
        'В любое время снова просмотрите камеру, таймеры, хранилище, безопасность и настройки.',
    'What TempCam does not do': 'Чего TempCam не делает',
    'What TempCam stores': 'Что хранит TempCam',
    'Why People Use TempCam': 'Почему люди используют TempCam',
    'YEARLY ACCESS': 'ГОДОВОЙ ДОСТУП',
    'Yearly Billing': 'Ежегодное выставление счетов',
    'Yearly access powers TempCam.': 'Ежегодный доступ дает право TempCam.',
    'Yearly access unlocked. TempCam is ready to use.':
        'Годовой доступ разблокирован. TempCam готов к использованию.',
    'You can skip this now and reopen it any time from Settings.':
        'Вы можете пропустить это сейчас и открыть его в любое время в настройках.',
    'Your access is live.': 'Ваш доступ активен.',
    'Your current subscription is active through the store.':
        'Ваша текущая подписка активна через магазин.',
    'Your subscription is handled directly by the App Store or Google Play with one yearly plan.':
        'Ваша подписка обрабатывается напрямую App Store или Google Play с годовым планом.',
    'Your vault is empty': 'Ваше хранилище пусто',
    'Your yearly subscription has been restored.':
        'Ваша годовая подписка восстановлена.',
    'Your yearly subscription is active.': 'Ваша годовая подписка активна.',
    '{count} items deleted from TempCam.':
        'Из TempCam удалено {count} элементов.',
    '{count} items imported into TempCam, but {failed} original items could not be removed from the main gallery.':
        'Элементов {count} импортировано в TempCam, но исходные элементы {failed} не удалось удалить из основной галереи.',
    '{count} items moved into TempCam and removed from the main gallery.':
        'Элементы {count} перемещены в TempCam и удалены из основной галереи.',
    '{count} items selected for deletion.':
        '{count} элементов выбрано для удаления.',
    '{count} temp items ready': '{count} временные элементы готовы',
    '{days}d {hours}h': '{days}d {hours}h',
    '{hours}h {minutes}m': '{hours}h {minutes}m',
    '{media} expired after {timer} and was removed from TempCam.':
        'Срок действия {media} истек после {timer}, и он был удален из TempCam.',
    '{media} exported to the main gallery and removed from TempCam expiry.':
        '{media} экспортирован в главную галерею и удален по истечении срока действия TempCam.',
    '{media} removed manually before its timer ended.':
        '{media} удален вручную до истечения таймера.',
    '{minutes}m': '{minutes}м',
  },
  'ar': {
    'System Default': 'افتراضي النظام',
    'Language': 'اللغة',
    'Choose the app language. System Default follows your phone language.':
        'اختر لغة التطبيق. الوضع الافتراضي يتبع لغة الهاتف.',
    'Press back again to exit TempCam': 'اضغط رجوع مرة اخرى للخروج من TempCam',
    'Protected Preview': 'معاينة محمية',
    '15 DAYS FREE': '15 يوما مجانا',
    'Start with a secure free trial.': 'ابدأ بتجربة مجانية آمنة.',
    'Continue To Access': 'متابعة',
    'PRIVATE • TEMPORARY • LOCAL': 'خاص • مؤقت • محلي',
    'Preparing secure vault experience': 'جار تجهيز الخزنة الآمنة',
    'Secure session initializing': 'جار بدء الجلسة الآمنة',
    'Vault Locked': 'الخزنة مقفلة',
    'Unlocking...': 'جار الفتح...',
    'Unlock TempCam': 'افتح TempCam',
    'Switching camera...': 'جار تبديل الكاميرا...',
    'PHOTO': 'صورة',
    'VIDEO': 'فيديو',
    'Tap to view': 'اضغط للعرض',
    'Set Self-Destruct Timer': 'تعيين المؤقت',
    'Apply Timer': 'تطبيق المؤقت',
    'Private Vault': 'الخزنة الخاصة',
    'Expiring in': 'ينتهي خلال',
    'Created': 'تم الإنشاء',
    'Private Video': 'فيديو خاص',
    'Private Photo': 'صورة خاصة',
    'Extend Timer': 'تمديد المؤقت',
    'Keep Forever': 'الاحتفاظ دائما',
    'Delete Now': 'احذف الآن',
    'Skip': 'تخطي',
    'Back': 'رجوع',
    'Get Started': 'ابدأ',
    'Next': 'التالي',
    'Manage Access': 'إدارة الوصول',
    'Open Camera': 'افتح الكاميرا',
    'Open Vault': 'افتح الخزنة',
    'All': 'الكل',
    'Photos': 'الصور',
    'Videos': 'الفيديوهات',
    'Cancel': 'إلغاء',
    'Delete': 'حذف',
    'Restore Purchase': 'استعادة الشراء',
    'Privacy Policy': 'سياسة الخصوصية',
    'Terms': 'الشروط',
    'Capture': 'التقاط',
    'Done': 'تم',
    'Select': 'تحديد',
    'FREE TRIAL': 'تجربة مجانية',
    'ACTIVE': 'نشط',
    'REQUIRED': 'مطلوب',
    'Camera is unavailable.': 'الكاميرا غير متاحة.',
    'Video': 'فيديو',
    'Photo': 'صورة',
    '1 Hour': '1 ساعة',
    '12 Hours': '12 ساعة',
    '15 Seconds': '15 ثانية',
    '24 Hours': '24 ساعة',
    '3 Days': '3 أيام',
    '3 Hours': '3 ساعات',
    '30 Seconds': '30 ثانية',
    '5 Seconds': '5 ثواني',
    '7 Days': '7 أيام',
    '7 day timers are available with Premium.':
        'تتوفر مؤقتات لمدة 7 أيام مع Premium.',
    'A {price} yearly subscription keeps TempCam private, temporary, and fully unlocked.':
        'الاشتراك السنوي {price} يحافظ على TempCam خاصًا ومؤقتًا ومفتوحًا بالكامل.',
    'APP TOUR': 'جولة التطبيق',
    'Access Active': 'الوصول نشط',
    'Access Required': 'الوصول مطلوب',
    'Access is recorded until {date}.': 'يتم تسجيل الوصول حتى {date}.',
    'Access recorded until {date}': 'تم تسجيل الوصول حتى {date}',
    'After the trial ends, Google Play continues the subscription at {price} per year unless the user cancels in time.':
        'بعد انتهاء النسخة التجريبية، يواصل Google Play الاشتراك بمعدل {price} سنويًا ما لم يقم المستخدم بإلغاء الاشتراك في الوقت المناسب.',
    'All Media': 'جميع وسائل الإعلام',
    'Annual Access': 'الوصول السنوي',
    'Authenticating now. If the prompt does not appear, tap below to unlock TempCam.':
        'المصادقة الآن. إذا لم تظهر المطالبة، فانقر أدناه لفتح قفل TempCam.',
    'Auto-renewing yearly subscription. Cancel anytime in Google Play or App Store subscriptions.':
        'التجديد التلقائي للاشتراك السنوي. قم بالإلغاء في أي وقت في اشتراكات Google Play أو App Store.',
    'Before release': 'قبل الافراج',
    'Billing': 'الفواتير',
    'Biometric Lock': 'قفل البيومترية',
    'Biometric protection is unavailable on this device.':
        'الحماية البيومترية غير متوفرة على هذا الجهاز.',
    'Biometrics are unavailable on this device. Continue without biometric lock from settings.':
        'القياسات الحيوية غير متوفرة على هذا الجهاز. تابع بدون قفل البيومترية من الإعدادات.',
    'Biometrics, quick relock, and Panic Exit stay ready.':
        'تظل القياسات الحيوية وإعادة القفل السريع والخروج من حالة الذعر جاهزة.',
    'Browse all temp photos and videos, focus on what is expiring, and clean up quickly when you need to.':
        'تصفح جميع الصور ومقاطع الفيديو المؤقتة، وركز على ما تنتهي صلاحيته، وقم بالتنظيف بسرعة عندما تحتاج إلى ذلك.',
    'Browse photos and videos in the private vault, filter by type, import existing media into TempCam, extend timers, or delete items when you need to.':
        'تصفح الصور ومقاطع الفيديو في المخزن الخاص، أو قم بالتصفية حسب النوع، أو قم باستيراد الوسائط الموجودة إلى TempCam، أو قم بتمديد المؤقتات، أو احذف العناصر عندما تحتاج إلى ذلك.',
    'Buy 1 Year For {price}': 'اشترِ سنة واحدة مقابل {price}',
    'Buy or restore yearly access to open TempCam. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'قم بشراء أو استعادة الوصول السنوي لفتح TempCam. إذا كان حساب المتجر الخاص بك مؤهلاً، فقد تقوم المنصة بتطبيق الإصدار التجريبي المجاني لمدة 15 يومًا أثناء الخروج.',
    'CAMERA': 'آلة تصوير',
    'Capture Defaults': 'التقاط الافتراضيات',
    'Capture a photo or video and it will appear here with its self-destruct timer.':
        'التقط صورة أو مقطع فيديو وسيظهر هنا مع مؤقت التدمير الذاتي الخاص به.',
    'Capture quickly with the private camera.':
        'التقط الصور بسرعة باستخدام الكاميرا الخاصة.',
    'Choose a timer after capture or import. If you skip it, TempCam uses your default timer from Settings.':
        'اختر مؤقتًا بعد الالتقاط أو الاستيراد. إذا قمت بتخطيها، فإن TempCam يستخدم مؤقتك الافتراضي من الإعدادات.',
    'Choose how long TempCam can stay in the background before it asks for biometrics again.':
        'اختر المدة التي يمكن أن يبقى فيها TempCam في الخلفية قبل أن يطلب القياسات الحيوية مرة أخرى.',
    'Choose how long new captures stay available by default.':
        'اختر مدة بقاء اللقطات الجديدة متاحة بشكل افتراضي.',
    'Choose items to delete.': 'اختر العناصر المراد حذفها.',
    'Choose when this capture evaporates from the vault.':
        'اختر متى يتبخر هذا الالتقاط من القبو.',
    'Close TempCam immediately and relock on return.':
        'أغلق TempCam فورًا وأعد القفل عند العودة.',
    'Connecting To Store...': 'جارٍ الاتصال بالمتجر...',
    'Default Self-Destruct Timer': 'مؤقت التدمير الذاتي الافتراضي',
    'Default {timer}': 'الافتراضي {timer}',
    'Defaults to 24 hours if skipped.': 'الافتراضي هو 24 ساعة إذا تم تخطيه.',
    'Directly billed and renewed by the platform store.':
        'يتم إصدار الفاتورة مباشرة وتجديدها بواسطة متجر المنصة.',
    'Disable TEMPCAM_DISABLE_PAYMENTS before uploading to the store.':
        'قم بتعطيل TEMPCAM_DISABLE_PAYMENTS قبل التحميل إلى المتجر.',
    'Done ({count})': 'تم ({count})',
    'Enable Biometric Lock first to use instant session relocking.':
        'قم بتمكين القفل البيومتري أولاً لاستخدام إعادة قفل الجلسة الفورية.',
    'Encrypted Vault': 'قبو مشفرة',
    'Every item gets a self-destruct timer.':
        'يحصل كل عنصر على مؤقت للتدمير الذاتي.',
    'Every temporary moment, in one calm vault.':
        'كل لحظة مؤقتة، في قبو واحد هادئ.',
    'Expired': 'منتهي الصلاحية',
    'Expiring Soon': 'تنتهي قريبا',
    'Expiry Notifications': 'إخطارات انتهاء الصلاحية',
    'Fallback price shown until the store catalog loads.':
        'السعر الاحتياطي يظهر حتى يتم تحميل كتالوج المتجر.',
    'Fast under pressure': 'سريع تحت الضغط',
    'Finish the current capture before importing media.':
        'قم بإنهاء الالتقاط الحالي قبل استيراد الوسائط.',
    'Flash auto': 'فلاش تلقائي',
    'Flash is unavailable on this camera.': 'الفلاش غير متوفر في هذه الكاميرا.',
    'Flash off': 'فلاش قبالة',
    'Flash on': 'تشغيل الفلاش',
    'Flash torch': 'شعلة فلاش',
    'Forever': 'للأبد',
    'Get warned before temporary media disappears.':
        'احصل على تحذير قبل اختفاء الوسائط المؤقتة.',
    'Google Play or the App Store can start a secure 15-day free trial for eligible accounts before yearly billing begins.':
        'يمكن لـ Google Play أو App Store بدء نسخة تجريبية مجانية آمنة مدتها 15 يومًا للحسابات المؤهلة قبل بدء الفوترة السنوية.',
    'Google Play will start your 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'سيبدأ Google Play تجربتك المجانية لمدة 15 يومًا عندما تبدأ الاشتراك السنوي. ترتبط هذه النسخة التجريبية بحساب المتجر، لذا فإن مسح بيانات التطبيق لن يؤدي إلى إعادة تشغيلها.',
    'Help': 'يساعد',
    'Hide photo and video wording in reminders for a quieter lock-screen presence.':
        'قم بإخفاء صيغة الصور والفيديو في التذكيرات للحصول على حضور أكثر هدوءًا على شاشة القفل.',
    'If eligible, checkout starts with the store-managed 15-day free trial and then renews yearly.':
        'إذا كان مؤهلاً، يبدأ الخروج بالتجربة المجانية التي يديرها المتجر لمدة 15 يومًا ثم يتم تجديدها سنويًا.',
    'If your Google Play account is eligible, the store will offer a 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'إذا كان حساب Google Play الخاص بك مؤهلاً، فسيقدم المتجر نسخة تجريبية مجانية مدتها 15 يومًا عند بدء الاشتراك السنوي. ترتبط هذه النسخة التجريبية بحساب المتجر، لذا فإن مسح بيانات التطبيق لن يؤدي إلى إعادة تشغيلها.',
    'Keep Forever exports, manual deletions, and auto-deletions will appear here as a local trust log.':
        'ستظهر عمليات التصدير والحذف اليدوي والحذف التلقائي هنا كسجل ثقة محلي.',
    'Kept Forever': 'أبقى إلى الأبد',
    'LOCAL PRIVATE STORAGE': 'التخزين المحلي الخاص',
    'LOCAL | TEMPORARY | PROTECTED': 'محلي | مؤقت | محمي',
    'Local record of exports, deletions, and auto-deletions.':
        'السجل المحلي للصادرات والحذف والحذف التلقائي.',
    'Lock TempCam immediately whenever the app loses focus.':
        'قم بقفل TempCam على الفور عندما يفقد التطبيق التركيز.',
    'Manage TempCam Access': 'إدارة الوصول إلى TempCam',
    'Manage expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.':
        'إدارة إشعارات انتهاء الصلاحية، وصياغة الإشعارات الخفية، والمؤقتات الافتراضية، والوصول إلى الاشتراك، وإعادة فتح هذه الجولة في أي وقت من الإعدادات.',
    'Managing access': 'إدارة الوصول',
    'Media no longer exists.': 'وسائل الإعلام لم تعد موجودة.',
    'No temp photos yet': 'لا توجد صور مؤقتة حتى الآن',
    'No temp videos yet': 'لا توجد مقاطع فيديو مؤقتة حتى الآن',
    'Once the subscription or trial is active, TempCam unlocks fully and can re-lock with biometrics.':
        'بمجرد تنشيط الاشتراك أو النسخة التجريبية، يتم فتح TempCam بالكامل ويمكن إعادة قفله باستخدام القياسات الحيوية.',
    'One auto-renewing yearly subscription managed directly by Google Play or the App Store.':
        'اشتراك سنوي واحد يتم تجديده تلقائيًا تتم إدارته مباشرةً بواسطة Google Play أو App Store.',
    'Only Plan': 'الخطة فقط',
    'Open, capture, review, and protect sensitive moments with fewer steps.':
        'يمكنك فتح اللحظات الحساسة والتقاطها ومراجعتها وحمايتها بخطوات أقل.',
    'PAYMENT OFF': 'إيقاف الدفع',
    'Panic Exit': 'خروج الذعر',
    'Panic Exit and quick relocking help when you need privacy right away.':
        'يساعد الخروج من حالة الذعر وإعادة القفل السريع عندما تحتاج إلى الخصوصية على الفور.',
    'Payment Disabled For Testing': 'تم تعطيل الدفع للاختبار',
    'Payment is charged by Google Play or the App Store at confirmation of purchase. Subscriptions renew automatically unless canceled before the renewal date.':
        'يتم تحصيل الدفع عن طريق Google Play أو App Store عند تأكيد الشراء. يتم تجديد الاشتراكات تلقائيًا ما لم يتم إلغاؤها قبل تاريخ التجديد.',
    'Payments Disabled Temporarily': 'المدفوعات معطلة مؤقتا',
    'Photo auto-deleted': 'تم حذف الصورة تلقائيًا',
    'Photo deleted now': 'تم حذف الصورة الآن',
    'Photo kept forever': 'الصورة محفوظة إلى الأبد',
    'Photo kept forever and exported.':
        'تم الاحتفاظ بالصورة إلى الأبد وتصديرها.',
    'Photos and videos auto-delete unless you decide to keep them forever.':
        'يتم حذف الصور ومقاطع الفيديو تلقائيًا ما لم تقرر الاحتفاظ بها إلى الأبد.',
    'Plan': 'يخطط',
    'Premium Only': 'بريميوم فقط',
    'Privacy Notes': 'ملاحظات الخصوصية',
    'Private Preview': 'معاينة خاصة',
    'Private by design': 'خاص بالتصميم',
    'Protect app entry and sensitive actions with biometrics.':
        'حماية دخول التطبيق والإجراءات الحساسة باستخدام القياسات الحيوية.',
    'Quick Lock Timeout': 'مهلة القفل السريع',
    'Recording started': 'بدأ التسجيل',
    'Recover your yearly access from the App Store or Google Play on reinstall.':
        'يمكنك استعادة وصولك السنوي من App Store أو Google Play عند إعادة التثبيت.',
    'Release setup': 'الافراج عن الإعداد',
    'Replay App Tour': 'إعادة تشغيل جولة التطبيق',
    'Replay Tour': 'جولة إعادة التشغيل',
    'Restore Support': 'استعادة الدعم',
    'Restore request sent to the store.': 'تم إرسال طلب الاستعادة إلى المتجر.',
    'Review this private photo before setting its timer.':
        'قم بمراجعة هذه الصورة الخاصة قبل ضبط مؤقتها.',
    'Review this private video before setting its timer.':
        'قم بمراجعة هذا الفيديو الخاص قبل ضبط مؤقته.',
    'SECURITY': 'حماية',
    'SETTINGS': 'إعدادات',
    'Secure Access': 'الوصول الآمن',
    'Security': 'حماية',
    'Session Privacy Mode': 'وضع خصوصية الجلسة',
    'Session Privacy Mode locks instantly, so timeout is bypassed.':
        'يتم قفل وضع خصوصية الجلسة على الفور، لذلك يتم تجاوز المهلة.',
    'Set TEMPCAM_PRIVACY_POLICY_URL during your release build to open your hosted policy page from the app.':
        'قم بتعيين TEMPCAM_PRIVACY_POLICY_URL أثناء إنشاء الإصدار الخاص بك لفتح صفحة السياسة المستضافة من التطبيق.',
    'Set TEMPCAM_SUBSCRIPTION_TERMS_URL during your release build to open your hosted terms page from the app.':
        'قم بتعيين TEMPCAM_SUBSCRIPTION_TERMS_URL أثناء إنشاء الإصدار الخاص بك لفتح صفحة الشروط المستضافة من التطبيق.',
    'Settings controls reminders, stealth mode, and access.':
        'تتحكم الإعدادات في التذكيرات ووضع التخفي والوصول.',
    'Start': 'يبدأ',
    'Start 15 Days Free': 'ابدأ 15 يومًا مجانًا',
    'Start or restore yearly access. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'بدء أو استعادة الوصول السنوي. إذا كان حساب المتجر الخاص بك مؤهلاً، فقد تقوم المنصة بتطبيق الإصدار التجريبي المجاني لمدة 15 يومًا أثناء الخروج.',
    'Start the Google Play or App Store managed 15-day free trial, or restore your yearly access to open TempCam.':
        'ابدأ الإصدار التجريبي المجاني المُدار لمدة 15 يومًا من Google Play أو App Store، أو استعد وصولك السنوي لفتح TempCam.',
    'Start with 15 days free.': 'ابدأ بـ 15 يومًا مجانًا.',
    'Start your secure store-managed 15-day free trial, then continue with one yearly plan.':
        'ابدأ تجربتك المجانية الآمنة التي يديرها المتجر لمدة 15 يومًا، ثم تابع بخطة سنوية واحدة.',
    'Stealth Notifications': 'الإخطارات الخفية',
    'Store Trial': 'تجربة المتجر',
    'Store billing is currently bypassed by a temporary app-wide test switch.':
        'يتم تجاوز فواتير المتجر حاليًا عن طريق مفتاح اختبار مؤقت على مستوى التطبيق.',
    'Subscription Terms': 'شروط الاشتراك',
    'TIMERS': 'الموقتات',
    'Take private photos and videos inside TempCam, keep them out of the main gallery, and let them disappear unless you keep them forever.':
        'التقط صورًا ومقاطع فيديو خاصة داخل TempCam، واحفظها خارج المعرض الرئيسي، واتركها تختفي ما لم تحتفظ بها إلى الأبد.',
    'Temp media stays local to your device until you explicitly keep it forever. Recent-app previews are shielded, and sensitive actions stay protected behind biometric confirmation when enabled.':
        'تظل الوسائط المؤقتة محلية على جهازك حتى تحتفظ بها بشكل صريح إلى الأبد. تتم حماية معاينات التطبيقات الحديثة، وتظل الإجراءات الحساسة محمية خلف التأكيد البيومتري عند تمكينها.',
    'Temp photos and videos are stored locally on the device inside TempCam until they expire, are deleted, or are kept forever by the user.':
        'يتم تخزين الصور ومقاطع الفيديو المؤقتة محليًا على الجهاز داخل TempCam حتى تنتهي صلاحيتها، أو يتم حذفها، أو يحتفظ بها المستخدم إلى الأبد.',
    'TempCam does not upload your temporary media to a cloud service inside the app flow. Subscription billing is handled by the platform store.':
        'TempCam لا يقوم بتحميل الوسائط المؤقتة الخاصة بك إلى خدمة سحابية داخل تدفق التطبيق. تتم معالجة فواتير الاشتراك من خلال متجر النظام الأساسي.',
    'TempCam keeps sensitive captures temporary.':
        'TempCam يبقي اللقطات الحساسة مؤقتة.',
    'TempCam offers one auto-renewing yearly subscription for access to the app.':
        'يقدم TempCam اشتراكًا سنويًا واحدًا يتم تجديده تلقائيًا للوصول إلى التطبيق.',
    'Temporary by default': 'مؤقت افتراضيا',
    'Temporary captures stay inside TempCam instead of appearing in the main gallery.':
        'تبقى اللقطات المؤقتة داخل TempCam بدلاً من الظهور في المعرض الرئيسي.',
    'Testing': 'اختبار',
    'The 15-day free trial is managed by Google Play or the App Store, so clearing app data will not restart it.':
        'تتم إدارة النسخة التجريبية المجانية لمدة 15 يومًا بواسطة Google Play أو App Store، لذا لن يؤدي مسح بيانات التطبيق إلى إعادة تشغيلها.',
    'The vault keeps temp media private first.':
        'يحافظ القبو على خصوصية الوسائط المؤقتة أولاً.',
    'This build bypasses subscriptions so you can test TempCam on your phone before store upload.':
        'يتجاوز هذا الإصدار الاشتراكات حتى تتمكن من اختبار TempCam على هاتفك قبل تحميله إلى المتجر.',
    'This filter only shows temp photos stored inside TempCam.':
        'يعرض هذا الفلتر فقط الصور المؤقتة المخزنة داخل TempCam.',
    'This filter only shows temp videos stored inside TempCam.':
        'يعرض هذا الفلتر فقط مقاطع الفيديو المؤقتة المخزنة داخل TempCam.',
    'Trial Then Yearly': 'المحاكمة ثم سنويا',
    'Trusted Vault History': 'تاريخ قبو موثوق به',
    'Unable to export this item to the main gallery.':
        'غير قادر على تصدير هذا العنصر إلى المعرض الرئيسي.',
    'Unable to import media right now.': 'غير قادر على استيراد الوسائط الآن.',
    'Unable to use video recording right now.':
        'غير قادر على استخدام تسجيل الفيديو الآن.',
    'Unlock Premium': 'فتح بريميوم',
    'Unlock Premium to use the 7 day timer.':
        'قم بفتح Premium لاستخدام مؤقت 7 أيام.',
    'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and Panic Exit for faster privacy under pressure.':
        'استخدم الحماية البيومترية، ووضع خصوصية الجلسة، ومهلة القفل السريع، ومعاينة الأحداث المحمية، والخروج الذعر لخصوصية أسرع تحت الضغط.',
    'Use photo or video mode, tap to focus, pinch to zoom, control flash, and review the private preview before you apply the timer.':
        'استخدم وضع الصورة أو الفيديو، وانقر للتركيز، وضم إصبعيك للتكبير، والتحكم في الفلاش، ومراجعة المعاينة الخاصة قبل تطبيق المؤقت.',
    'Users can restore purchases after reinstall and can manage or cancel subscriptions from their platform subscription settings.':
        'يمكن للمستخدمين استعادة المشتريات بعد إعادة التثبيت ويمكنهم إدارة الاشتراكات أو إلغائها من إعدادات اشتراك النظام الأساسي الخاصة بهم.',
    'VAULT': 'قبو',
    'Video auto-deleted': 'تم حذف الفيديو تلقائيًا',
    'Video deleted now': 'تم حذف الفيديو الآن',
    'Video kept forever': 'تم الاحتفاظ بالفيديو إلى الأبد',
    'Video kept forever and exported.':
        'يتم الاحتفاظ بالفيديو إلى الأبد وتصديره.',
    'Video saved to TempCam': 'تم حفظ الفيديو في TempCam',
    'View Access Options': 'عرض خيارات الوصول',
    'View Yearly Plan': 'عرض الخطة السنوية',
    'WELCOME': 'مرحباً',
    'Waiting for store confirmation...': 'في انتظار تأكيد المتجر...',
    'Walk through camera, timers, vault, security, and settings again any time.':
        'قم بالتجول عبر الكاميرا والمؤقتات والقبو والأمان والإعدادات مرة أخرى في أي وقت.',
    'What TempCam does not do': 'ما لا يفعله TempCam',
    'What TempCam stores': 'ماذا يخزن TempCam',
    'Why People Use TempCam': 'لماذا يستخدم الناس TempCam',
    'YEARLY ACCESS': 'الوصول السنوي',
    'Yearly Billing': 'الفواتير السنوية',
    'Yearly access powers TempCam.': 'صلاحيات الوصول السنوية TempCam.',
    'Yearly access unlocked. TempCam is ready to use.':
        'الوصول السنوي مقفلة. TempCam جاهز للاستخدام.',
    'You can skip this now and reopen it any time from Settings.':
        'يمكنك تخطي هذا الآن وإعادة فتحه في أي وقت من الإعدادات.',
    'Your access is live.': 'وصولك مباشر.',
    'Your current subscription is active through the store.':
        'اشتراكك الحالي نشط من خلال المتجر.',
    'Your subscription is handled directly by the App Store or Google Play with one yearly plan.':
        'تتم معالجة اشتراكك مباشرةً بواسطة App Store أو Google Play بخطة سنوية واحدة.',
    'Your vault is empty': 'قبو الخاص بك فارغ',
    'Your yearly subscription has been restored.':
        'تمت استعادة اشتراكك السنوي.',
    'Your yearly subscription is active.': 'اشتراكك السنوي نشط.',
    '{count} items deleted from TempCam.':
        '{count} العناصر المحذوفة من TempCam.',
    '{count} items imported into TempCam, but {failed} original items could not be removed from the main gallery.':
        '{count} العناصر المستوردة إلى TempCam، ولكن لا يمكن إزالة {failed} العناصر الأصلية من المعرض الرئيسي.',
    '{count} items moved into TempCam and removed from the main gallery.':
        'تم نقل عناصر {count} إلى TempCam وإزالتها من المعرض الرئيسي.',
    '{count} items selected for deletion.': '{count} العناصر المحددة للحذف.',
    '{count} temp items ready': '{count} العناصر المؤقتة جاهزة',
    '{days}d {hours}h': '{days}د {hours}h',
    '{hours}h {minutes}m': '{hours}h {minutes}m',
    '{media} expired after {timer} and was removed from TempCam.':
        'انتهت صلاحية {media} بعد {timer} وتمت إزالتها من TempCam.',
    '{media} exported to the main gallery and removed from TempCam expiry.':
        'تم تصدير {media} إلى المعرض الرئيسي وإزالته من تاريخ انتهاء الصلاحية TempCam.',
    '{media} removed manually before its timer ended.':
        'تمت إزالة {media} يدويًا قبل انتهاء مؤقته.',
    '{minutes}m': '{minutes}م',
  },
  'ko': {
    'System Default': '시스템 기본값',
    'Language': '언어',
    'Choose the app language. System Default follows your phone language.':
        '앱 언어를 선택하세요. 시스템 기본값은 휴대폰 언어를 따릅니다.',
    'Press back again to exit TempCam': 'TempCam을 종료하려면 뒤로를 한 번 더 누르세요',
    'Protected Preview': '보호된 미리보기',
    '15 DAYS FREE': '15일 무료',
    'Start with a secure free trial.': '안전한 무료 체험으로 시작하세요.',
    'Continue To Access': '계속',
    'PRIVATE • TEMPORARY • LOCAL': '비공개 • 임시 • 로컬',
    'Preparing secure vault experience': '안전한 보관함을 준비하는 중',
    'Secure session initializing': '보안 세션 초기화 중',
    'Vault Locked': '보관함 잠김',
    'Unlocking...': '잠금 해제 중...',
    'Unlock TempCam': 'TempCam 잠금 해제',
    'Switching camera...': '카메라 전환 중...',
    'PHOTO': '사진',
    'VIDEO': '동영상',
    'Tap to view': '탭하여 보기',
    'Set Self-Destruct Timer': '자동 삭제 타이머 설정',
    'Apply Timer': '타이머 적용',
    'Private Vault': '비공개 보관함',
    'Expiring in': '남은 시간',
    'Created': '생성됨',
    'Private Video': '비공개 동영상',
    'Private Photo': '비공개 사진',
    'Extend Timer': '타이머 연장',
    'Keep Forever': '영구 보관',
    'Delete Now': '지금 삭제',
    'Skip': '건너뛰기',
    'Back': '뒤로',
    'Get Started': '시작하기',
    'Next': '다음',
    'Manage Access': '접근 관리',
    'Open Camera': '카메라 열기',
    'Open Vault': '보관함 열기',
    'All': '전체',
    'Photos': '사진',
    'Videos': '동영상',
    'Cancel': '취소',
    'Delete': '삭제',
    'Restore Purchase': '구매 복원',
    'Privacy Policy': '개인정보 처리방침',
    'Terms': '이용약관',
    'Capture': '촬영',
    'Done': '완료',
    'Select': '선택',
    'FREE TRIAL': '무료 체험',
    'ACTIVE': '활성',
    'REQUIRED': '필수',
    'Camera is unavailable.': '카메라를 사용할 수 없습니다.',
    'Video': '동영상',
    'Photo': '사진',
    '1 Hour': '1시간',
    '12 Hours': '12시간',
    '15 Seconds': '15초',
    '24 Hours': '24시간',
    '3 Days': '3일',
    '3 Hours': '3시간',
    '30 Seconds': '30초',
    '5 Seconds': '5초',
    '7 Days': '7일',
    '7 day timers are available with Premium.':
        'Premium에서는 7일 타이머를 사용할 수 있습니다.',
    'A {price} yearly subscription keeps TempCam private, temporary, and fully unlocked.':
        '{price} 연간 구독은 TempCam을(를) 비공개로, 일시적으로, 완전히 잠금 해제된 상태로 유지합니다.',
    'APP TOUR': '앱 투어',
    'Access Active': '액세스 활성',
    'Access Required': '액세스 필요',
    'Access is recorded until {date}.': '액세스는 {date}까지 기록됩니다.',
    'Access recorded until {date}': '{date}까지 액세스가 기록되었습니다.',
    'After the trial ends, Google Play continues the subscription at {price} per year unless the user cancels in time.':
        '평가판이 종료된 후에도 사용자가 기한 내에 취소하지 않는 한 Google Play에서는 연간 {price}의 요금으로 구독을 계속합니다.',
    'All Media': '모든 미디어',
    'Annual Access': '연간 액세스',
    'Authenticating now. If the prompt does not appear, tap below to unlock TempCam.':
        '지금 인증 중입니다. 메시지가 표시되지 않으면 아래를 탭하여 TempCam을 잠금 해제하세요.',
    'Auto-renewing yearly subscription. Cancel anytime in Google Play or App Store subscriptions.':
        '연간 구독이 자동 갱신됩니다. Google Play 또는 App Store 구독은 언제든지 취소할 수 있습니다.',
    'Before release': '출시 전',
    'Billing': '청구',
    'Biometric Lock': '생체 인식 잠금',
    'Biometric protection is unavailable on this device.':
        '이 장치에서는 생체 인식 보호를 사용할 수 없습니다.',
    'Biometrics are unavailable on this device. Continue without biometric lock from settings.':
        '이 기기에서는 생체 인식을 사용할 수 없습니다. 설정에서 생체인식 잠금 없이 계속하세요.',
    'Biometrics, quick relock, and Panic Exit stay ready.':
        '생체 인식, 빠른 재잠금 및 패닉 종료가 항상 준비되어 있습니다.',
    'Browse all temp photos and videos, focus on what is expiring, and clean up quickly when you need to.':
        '모든 임시 사진과 비디오를 찾아보고, 만료되는 항목에 집중하고, 필요할 때 빠르게 정리하세요.',
    'Browse photos and videos in the private vault, filter by type, import existing media into TempCam, extend timers, or delete items when you need to.':
        '개인 금고에서 사진과 비디오를 찾아보고, 유형별로 필터링하고, 기존 미디어를 TempCam로 가져오고, 타이머를 연장하거나, 필요할 때 항목을 삭제하세요.',
    'Buy 1 Year For {price}': '{price}에 1년 구매',
    'Buy or restore yearly access to open TempCam. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        'TempCam을(를) 열려면 연간 액세스 권한을 구매하거나 복원하세요. 귀하의 매장 계정이 자격을 갖춘 경우 플랫폼은 결제 시 15일 무료 평가판을 적용할 수 있습니다.',
    'CAMERA': '카메라',
    'Capture Defaults': '캡처 기본값',
    'Capture a photo or video and it will appear here with its self-destruct timer.':
        '사진이나 비디오를 캡처하면 자폭 타이머와 함께 여기에 표시됩니다.',
    'Capture quickly with the private camera.': '개인용 카메라로 빠르게 캡처하세요.',
    'Choose a timer after capture or import. If you skip it, TempCam uses your default timer from Settings.':
        '캡처 또는 가져온 후 타이머를 선택하십시오. 건너뛰면 TempCam에서 설정의 기본 타이머를 사용합니다.',
    'Choose how long TempCam can stay in the background before it asks for biometrics again.':
        'TempCam이(가) 생체 인식을 다시 요청하기 전에 백그라운드에 머무를 수 있는 시간을 선택하세요.',
    'Choose how long new captures stay available by default.':
        '기본적으로 새 캡처를 사용할 수 있는 기간을 선택합니다.',
    'Choose items to delete.': '삭제할 항목을 선택하세요.',
    'Choose when this capture evaporates from the vault.':
        '이 캡처가 저장소에서 증발되는 시기를 선택하세요.',
    'Close TempCam immediately and relock on return.':
        'TempCam을(를) 즉시 닫고 돌아올 때 다시 잠그세요.',
    'Connecting To Store...': '매장에 연결 중...',
    'Default Self-Destruct Timer': '기본 자폭 타이머',
    'Default {timer}': '기본값 {timer}',
    'Defaults to 24 hours if skipped.': '건너뛴 경우 기본값은 24시간입니다.',
    'Directly billed and renewed by the platform store.':
        '플랫폼 스토어에서 직접 청구하고 갱신합니다.',
    'Disable TEMPCAM_DISABLE_PAYMENTS before uploading to the store.':
        '스토어에 업로드하기 전에 TEMPCAM_DISABLE_PAYMENTS을(를) 비활성화하세요.',
    'Done ({count})': '완료({count})',
    'Enable Biometric Lock first to use instant session relocking.':
        '즉시 세션 재잠금을 사용하려면 먼저 생체 인식 잠금을 활성화하세요.',
    'Encrypted Vault': '암호화된 금고',
    'Every item gets a self-destruct timer.': '모든 아이템에는 자폭 타이머가 있습니다.',
    'Every temporary moment, in one calm vault.': '모든 일시적인 순간을 하나의 고요한 금고에서.',
    'Expired': '만료됨',
    'Expiring Soon': '곧 만료됨',
    'Expiry Notifications': '만료 알림',
    'Fallback price shown until the store catalog loads.':
        '매장 카탈로그가 로드될 때까지 대체 가격이 표시됩니다.',
    'Fast under pressure': '압력을 받으면 빠르게',
    'Finish the current capture before importing media.':
        '미디어를 가져오기 전에 현재 캡처를 완료하세요.',
    'Flash auto': '플래시 자동',
    'Flash is unavailable on this camera.': '이 카메라에서는 플래시를 사용할 수 없습니다.',
    'Flash off': '플래시 꺼짐',
    'Flash on': '플래시 켜짐',
    'Flash torch': '플래시 토치',
    'Forever': '영원히',
    'Get warned before temporary media disappears.':
        '임시 미디어가 사라지기 전에 경고를 받으세요.',
    'Google Play or the App Store can start a secure 15-day free trial for eligible accounts before yearly billing begins.':
        'Google Play 또는 App Store은 연간 청구가 시작되기 전에 적격 계정에 대해 안전한 15일 무료 평가판을 시작할 수 있습니다.',
    'Google Play will start your 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        'Google Play은 연간 구독을 시작하면 15일 무료 평가판을 시작합니다. 이 평가판은 스토어 계정과 연결되어 있으므로 앱 데이터를 지워도 다시 시작되지는 않습니다.',
    'Help': '돕다',
    'Hide photo and video wording in reminders for a quieter lock-screen presence.':
        '더 조용한 잠금 화면을 위해 미리 알림에서 사진 및 비디오 문구를 숨깁니다.',
    'If eligible, checkout starts with the store-managed 15-day free trial and then renews yearly.':
        '자격이 있는 경우 결제는 매장에서 관리하는 15일 무료 평가판으로 시작되며 매년 갱신됩니다.',
    'If your Google Play account is eligible, the store will offer a 15-day free trial when you begin the yearly subscription. This trial is tied to the store account, so clearing app data will not restart it.':
        '귀하의 Google Play 계정이 자격이 있는 경우 연간 구독을 시작할 때 매장에서 15일 무료 평가판을 제공합니다. 이 평가판은 스토어 계정과 연결되어 있으므로 앱 데이터를 지워도 다시 시작되지는 않습니다.',
    'Keep Forever exports, manual deletions, and auto-deletions will appear here as a local trust log.':
        'Keep Forever 내보내기, 수동 삭제, 자동 삭제는 여기에 로컬 신뢰 로그로 표시됩니다.',
    'Kept Forever': '영원히 보관',
    'LOCAL PRIVATE STORAGE': '로컬 개인 저장소',
    'LOCAL | TEMPORARY | PROTECTED': '로컬 | 임시 | 보호됨',
    'Local record of exports, deletions, and auto-deletions.':
        '내보내기, 삭제 및 자동 삭제에 대한 로컬 기록입니다.',
    'Lock TempCam immediately whenever the app loses focus.':
        '앱이 포커스를 잃을 때마다 즉시 TempCam을 잠급니다.',
    'Manage TempCam Access': 'TempCam 액세스 관리',
    'Manage expiry notifications, stealth notification wording, default timers, subscription access, and reopen this tour anytime from Settings.':
        '만료 알림, 스텔스 알림 문구, 기본 타이머, 구독 액세스를 관리하고 언제든지 설정에서 이 투어를 다시 열 수 있습니다.',
    'Managing access': '액세스 관리',
    'Media no longer exists.': '미디어가 더 이상 존재하지 않습니다.',
    'No temp photos yet': '아직 임시 사진이 없습니다.',
    'No temp videos yet': '아직 임시 동영상이 없습니다.',
    'Once the subscription or trial is active, TempCam unlocks fully and can re-lock with biometrics.':
        '구독 또는 평가판이 활성화되면 TempCam이(가) 완전히 잠금 해제되고 생체 인식으로 다시 잠길 수 있습니다.',
    'One auto-renewing yearly subscription managed directly by Google Play or the App Store.':
        'Google Play 또는 App Store에서 직접 관리하는 자동 갱신 연간 구독 1개.',
    'Only Plan': '전용 플랜',
    'Open, capture, review, and protect sensitive moments with fewer steps.':
        '더 적은 단계로 민감한 순간을 열고, 캡처하고, 검토하고, 보호하세요.',
    'PAYMENT OFF': '결제 취소',
    'Panic Exit': '패닉 엑시트',
    'Panic Exit and quick relocking help when you need privacy right away.':
        '즉시 개인 정보 보호가 필요할 때 패닉 종료 및 빠른 재잠금 지원이 제공됩니다.',
    'Payment Disabled For Testing': '테스트를 위해 결제가 비활성화되었습니다.',
    'Payment is charged by Google Play or the App Store at confirmation of purchase. Subscriptions renew automatically unless canceled before the renewal date.':
        '결제는 구매 확인 시 Google Play 또는 App Store로 청구됩니다. 갱신 날짜 이전에 취소하지 않으면 구독이 자동으로 갱신됩니다.',
    'Payments Disabled Temporarily': '일시적으로 결제가 비활성화되었습니다.',
    'Photo auto-deleted': '사진이 자동 삭제되었습니다.',
    'Photo deleted now': '사진이 지금 삭제되었습니다.',
    'Photo kept forever': '사진은 영원히 보관됩니다',
    'Photo kept forever and exported.': '사진은 영원히 보관되고 내보내졌습니다.',
    'Photos and videos auto-delete unless you decide to keep them forever.':
        '사진과 비디오는 영구적으로 보관하기로 결정하지 않는 한 자동 삭제됩니다.',
    'Plan': '계획',
    'Premium Only': '프리미엄 전용',
    'Privacy Notes': '개인 정보 보호 참고 사항',
    'Private Preview': '비공개 미리보기',
    'Private by design': '비공개 디자인',
    'Protect app entry and sensitive actions with biometrics.':
        '생체인식으로 앱 진입과 민감한 행동을 보호하세요.',
    'Quick Lock Timeout': '빠른 잠금 시간 초과',
    'Recording started': '녹음이 시작되었습니다',
    'Recover your yearly access from the App Store or Google Play on reinstall.':
        '재설치 시 App Store 또는 Google Play에서 연간 액세스 권한을 복구하세요.',
    'Release setup': '출시 설정',
    'Replay App Tour': '리플레이 앱 둘러보기',
    'Replay Tour': '리플레이 투어',
    'Restore Support': '복원 지원',
    'Restore request sent to the store.': '복원 요청이 매장으로 전송되었습니다.',
    'Review this private photo before setting its timer.':
        '타이머를 설정하기 전에 이 비공개 사진을 검토하세요.',
    'Review this private video before setting its timer.':
        '타이머를 설정하기 전에 이 비공개 동영상을 검토하세요.',
    'SECURITY': '보안',
    'SETTINGS': '설정',
    'Secure Access': '보안 액세스',
    'Security': '보안',
    'Session Privacy Mode': '세션 개인정보 보호 모드',
    'Session Privacy Mode locks instantly, so timeout is bypassed.':
        '세션 개인 정보 보호 모드는 즉시 잠기므로 시간 초과가 우회됩니다.',
    'Set TEMPCAM_PRIVACY_POLICY_URL during your release build to open your hosted policy page from the app.':
        '릴리스 빌드 중에 TEMPCAM_PRIVACY_POLICY_URL을 설정하여 앱에서 호스팅된 정책 페이지를 엽니다.',
    'Set TEMPCAM_SUBSCRIPTION_TERMS_URL during your release build to open your hosted terms page from the app.':
        '릴리스 빌드 중에 TEMPCAM_SUBSCRIPTION_TERMS_URL을 설정하여 앱에서 호스팅된 용어 페이지를 엽니다.',
    'Settings controls reminders, stealth mode, and access.':
        '설정은 알림, 스텔스 모드, 액세스를 제어합니다.',
    'Start': '시작',
    'Start 15 Days Free': '15일 무료로 시작하세요',
    'Start or restore yearly access. If your store account is eligible, the platform may apply the 15-day free trial during checkout.':
        '연간 액세스를 시작하거나 복원합니다. 귀하의 매장 계정이 자격을 갖춘 경우 플랫폼은 결제 시 15일 무료 평가판을 적용할 수 있습니다.',
    'Start the Google Play or App Store managed 15-day free trial, or restore your yearly access to open TempCam.':
        'Google Play 또는 App Store 관리형 15일 무료 평가판을 시작하거나 TempCam을 열 수 있는 연간 액세스 권한을 복원하세요.',
    'Start with 15 days free.': '15일 무료로 시작해 보세요.',
    'Start your secure store-managed 15-day free trial, then continue with one yearly plan.':
        '안전한 매장 관리 15일 무료 평가판을 시작한 다음 연간 요금제를 계속 진행하세요.',
    'Stealth Notifications': '스텔스 알림',
    'Store Trial': '매장 평가판',
    'Store billing is currently bypassed by a temporary app-wide test switch.':
        '스토어 청구는 현재 임시 앱 전체 테스트 스위치로 우회됩니다.',
    'Subscription Terms': '구독 조건',
    'TIMERS': '타이머',
    'Take private photos and videos inside TempCam, keep them out of the main gallery, and let them disappear unless you keep them forever.':
        'TempCam 내부에 비공개 사진과 동영상을 찍어 메인 갤러리에 보관하고, 영원히 보관하지 않는 한 사라지도록 하세요.',
    'Temp media stays local to your device until you explicitly keep it forever. Recent-app previews are shielded, and sensitive actions stay protected behind biometric confirmation when enabled.':
        '임시 미디어는 명시적으로 영구적으로 보관할 때까지 장치에 로컬로 유지됩니다. 최근 앱 미리보기는 보호되며, 활성화된 경우 생체 인식 확인을 통해 민감한 작업이 보호됩니다.',
    'Temp photos and videos are stored locally on the device inside TempCam until they expire, are deleted, or are kept forever by the user.':
        '임시 사진과 동영상은 만료되거나 삭제되거나 사용자가 영원히 보관할 때까지 TempCam 내부의 기기에 로컬로 저장됩니다.',
    'TempCam does not upload your temporary media to a cloud service inside the app flow. Subscription billing is handled by the platform store.':
        'TempCam은(는) 앱 흐름 내의 클라우드 서비스에 임시 미디어를 업로드하지 않습니다. 구독 청구는 플랫폼 스토어에서 처리됩니다.',
    'TempCam keeps sensitive captures temporary.':
        'TempCam은 민감한 캡처를 임시로 유지합니다.',
    'TempCam offers one auto-renewing yearly subscription for access to the app.':
        'TempCam은(는) 앱 액세스를 위한 자동 갱신 연간 구독을 제공합니다.',
    'Temporary by default': '기본적으로 임시',
    'Temporary captures stay inside TempCam instead of appearing in the main gallery.':
        '임시 캡처는 기본 갤러리에 표시되지 않고 TempCam 내부에 유지됩니다.',
    'Testing': '테스트',
    'The 15-day free trial is managed by Google Play or the App Store, so clearing app data will not restart it.':
        '15일 무료 평가판은 Google Play 또는 App Store에서 관리하므로 앱 데이터를 지워도 다시 시작되지는 않습니다.',
    'The vault keeps temp media private first.': '볼트는 먼저 임시 미디어를 비공개로 유지합니다.',
    'This build bypasses subscriptions so you can test TempCam on your phone before store upload.':
        '이 빌드는 구독을 우회하므로 스토어 업로드 전에 휴대폰에서 TempCam을(를) 테스트할 수 있습니다.',
    'This filter only shows temp photos stored inside TempCam.':
        '이 필터는 TempCam 내부에 저장된 임시 사진만 표시합니다.',
    'This filter only shows temp videos stored inside TempCam.':
        '이 필터는 TempCam에 저장된 임시 동영상만 표시합니다.',
    'Trial Then Yearly': '평가판 이후 매년',
    'Trusted Vault History': '신뢰할 수 있는 Vault 기록',
    'Unable to export this item to the main gallery.':
        '이 항목을 기본 갤러리로 내보낼 수 없습니다.',
    'Unable to import media right now.': '지금은 미디어를 가져올 수 없습니다.',
    'Unable to use video recording right now.': '지금은 동영상 녹화를 사용할 수 없습니다.',
    'Unlock Premium': '프리미엄 잠금 해제',
    'Unlock Premium to use the 7 day timer.': '7일 타이머를 사용하려면 프리미엄을 잠금 해제하세요.',
    'Use biometric protection, Session Privacy Mode, quick lock timeout, protected recents preview, and Panic Exit for faster privacy under pressure.':
        '생체 인식 보호, 세션 개인 정보 보호 모드, 빠른 잠금 시간 초과, 보호된 최근 항목 미리 보기 및 긴급 종료를 사용하여 압박 속에서도 더 빠른 개인 정보 보호를 받을 수 있습니다.',
    'Use photo or video mode, tap to focus, pinch to zoom, control flash, and review the private preview before you apply the timer.':
        '사진 또는 비디오 모드를 사용하고, 탭하여 초점을 맞추고, 핀치하여 확대/축소하고, 플래시를 제어하고, 타이머를 적용하기 전에 비공개 미리보기를 검토하세요.',
    'Users can restore purchases after reinstall and can manage or cancel subscriptions from their platform subscription settings.':
        '사용자는 재설치 후 구매를 복원할 수 있으며 플랫폼 구독 설정에서 구독을 관리하거나 취소할 수 있습니다.',
    'VAULT': '둥근 천장',
    'Video auto-deleted': '동영상 자동 삭제됨',
    'Video deleted now': '지금 삭제된 동영상',
    'Video kept forever': '영상은 영원히 보관됩니다',
    'Video kept forever and exported.': '비디오는 영원히 보관되고 내보내집니다.',
    'Video saved to TempCam': 'TempCam에 저장된 동영상',
    'View Access Options': '액세스 옵션 보기',
    'View Yearly Plan': '연간 요금제 보기',
    'WELCOME': '환영',
    'Waiting for store confirmation...': '매장 확인을 기다리는 중...',
    'Walk through camera, timers, vault, security, and settings again any time.':
        '언제든지 카메라, 타이머, 금고, 보안 및 설정을 다시 살펴보세요.',
    'What TempCam does not do': 'TempCam이 하지 않는 일',
    'What TempCam stores': 'TempCam이(가) 저장하는 것',
    'Why People Use TempCam': '사람들이 TempCam을 사용하는 이유',
    'YEARLY ACCESS': '연간 액세스',
    'Yearly Billing': '연간 청구',
    'Yearly access powers TempCam.': '연간 액세스 권한 TempCam.',
    'Yearly access unlocked. TempCam is ready to use.':
        '연간 액세스가 잠금 해제되었습니다. TempCam을(를) 사용할 준비가 되었습니다.',
    'You can skip this now and reopen it any time from Settings.':
        '지금은 건너뛰고 언제든지 설정에서 다시 열 수 있습니다.',
    'Your access is live.': '귀하의 액세스는 실시간입니다.',
    'Your current subscription is active through the store.':
        '귀하의 현재 구독은 스토어를 통해 활성화되어 있습니다.',
    'Your subscription is handled directly by the App Store or Google Play with one yearly plan.':
        '귀하의 구독은 하나의 연간 요금제로 App Store 또는 Google Play에 의해 직접 처리됩니다.',
    'Your vault is empty': '금고가 비어 있습니다',
    'Your yearly subscription has been restored.': '연간 구독이 복원되었습니다.',
    'Your yearly subscription is active.': '귀하의 연간 구독이 활성화되었습니다.',
    '{count} items deleted from TempCam.': '{count} 항목이 TempCam에서 삭제되었습니다.',
    '{count} items imported into TempCam, but {failed} original items could not be removed from the main gallery.':
        '{count} 항목을 TempCam로 가져왔지만 {failed} 원본 항목을 기본 갤러리에서 제거할 수 없습니다.',
    '{count} items moved into TempCam and removed from the main gallery.':
        '{count} 항목이 TempCam로 이동되었으며 기본 갤러리에서 삭제되었습니다.',
    '{count} items selected for deletion.': '{count} 항목이 삭제되도록 선택되었습니다.',
    '{count} temp items ready': '{count} 임시 항목 준비됨',
    '{days}d {hours}h': '{days}d {hours}h',
    '{hours}h {minutes}m': '{hours}h {minutes}m',
    '{media} expired after {timer} and was removed from TempCam.':
        '{media}은(는) {timer} 이후에 만료되었으며 TempCam에서 제거되었습니다.',
    '{media} exported to the main gallery and removed from TempCam expiry.':
        '{media}을(를) 기본 갤러리로 내보내고 TempCam 만료 시 제거했습니다.',
    '{media} removed manually before its timer ended.':
        '{media}은 타이머가 끝나기 전에 수동으로 제거되었습니다.',
    '{minutes}m': '{minutes}m',
  },
};
