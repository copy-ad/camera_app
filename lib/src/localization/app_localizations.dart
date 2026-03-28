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
    'Extend Timer': 'Extend Timer',
    'Keep Forever': 'Keep Forever',
    'Premium Only': 'Premium Only',
    'Delete Now': 'Delete Now',
    'Media no longer exists.': 'Media no longer exists.',
    'WELCOME': 'WELCOME',
    'CAMERA': 'CAMERA',
    'TIMERS': 'TIMERS',
    'VAULT': 'VAULT',
    'SECURITY': 'SECURITY',
    'SETTINGS': 'SETTINGS',
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
        'Walk through camera, timers, vault, security, and settings again any time.',
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
  },
};
