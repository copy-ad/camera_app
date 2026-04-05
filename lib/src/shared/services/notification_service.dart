import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../localization/app_localizations.dart';
import '../models/photo_record.dart';

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _expiryChannel =
      AndroidNotificationChannel(
    'tempcam_expiry_reminders',
    'TempCam Expiry Reminders',
    description: 'Reminders before temporary photos or videos expire.',
    importance: Importance.high,
  );

  static const Duration _reminderLeadTime = Duration(minutes: 10);
  String? _lastSyncSignature;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const android = AndroidInitializationSettings(
      'ic_stat_tempcam',
    );
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_expiryChannel);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> syncExpiryNotifications(
    List<PhotoRecord> records, {
    required bool enabled,
    required bool stealthMode,
    required Locale? locale,
  }) async {
    final l10n = AppLocalizations.fromLocale(locale);
    final signature = _buildSignature(
      records,
      enabled: enabled,
      stealthMode: stealthMode,
      localeTag: AppLocalizations.localeTag(l10n.locale),
    );
    if (_lastSyncSignature == signature) {
      return;
    }

    _lastSyncSignature = signature;
    await _plugin.cancelAll();

    if (!enabled) {
      return;
    }

    for (final record in records) {
      if (record.isKeptForever || record.expiresAt == null) {
        continue;
      }

      final scheduledAt = _scheduleTimeFor(record.expiresAt!);
      if (scheduledAt == null) {
        continue;
      }

      await _plugin.zonedSchedule(
        _notificationIdFor(record.id),
        _titleFor(record, stealthMode: stealthMode, l10n: l10n),
        _bodyFor(stealthMode: stealthMode, l10n: l10n),
        scheduledAt,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _expiryChannel.id,
            _expiryChannel.name,
            channelDescription: _expiryChannel.description,
            icon: 'ic_stat_tempcam',
            largeIcon: const DrawableResourceAndroidBitmap('notification_logo'),
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            visibility: stealthMode
                ? NotificationVisibility.secret
                : NotificationVisibility.private,
            onlyAlertOnce: true,
            channelShowBadge: false,
            styleInformation: BigTextStyleInformation(
              _bodyFor(stealthMode: stealthMode, l10n: l10n),
            ),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelAll() async {
    _lastSyncSignature = 'disabled';
    await _plugin.cancelAll();
  }

  String _buildSignature(
    List<PhotoRecord> records, {
    required bool enabled,
    required bool stealthMode,
    required String localeTag,
  }) {
    final buffer = StringBuffer(enabled ? 'on|' : 'off|');
    buffer.write(stealthMode ? 'stealth|' : 'standard|');
    buffer.write(localeTag);
    buffer.write('|');
    for (final record in records) {
      buffer
        ..write(record.id)
        ..write(':')
        ..write(record.expiresAt?.millisecondsSinceEpoch ?? 0)
        ..write(':')
        ..write(record.isKeptForever ? '1' : '0')
        ..write('|');
    }
    return buffer.toString();
  }

  tz.TZDateTime? _scheduleTimeFor(DateTime expiresAt) {
    final now = DateTime.now();
    if (!expiresAt.isAfter(now)) {
      return null;
    }

    final scheduled = expiresAt.subtract(_reminderLeadTime);
    final effective = scheduled.isAfter(now.add(const Duration(seconds: 5)))
        ? scheduled
        : now.add(const Duration(seconds: 5));
    return tz.TZDateTime.from(effective, tz.local);
  }

  String _titleFor(
    PhotoRecord record, {
    required bool stealthMode,
    required AppLocalizations l10n,
  }) {
    if (stealthMode) {
      return l10n.tr('Secure reminder');
    }
    return l10n.tr(
      record.isVideo ? 'Video timer ending soon' : 'Photo timer ending soon',
    );
  }

  String _bodyFor({
    required bool stealthMode,
    required AppLocalizations l10n,
  }) {
    if (stealthMode) {
      return l10n.tr('Open TempCam soon to review a secure reminder.');
    }
    return l10n.tr('Open TempCam soon to keep it or let it expire safely.');
  }

  int _notificationIdFor(String id) {
    var hash = 17;
    for (final codeUnit in id.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    return hash & 0x7fffffff;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }
}
