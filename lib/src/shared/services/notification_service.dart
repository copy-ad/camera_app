import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
  }) async {
    final signature = _buildSignature(
      records,
      enabled: enabled,
      stealthMode: stealthMode,
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
        _titleFor(record, stealthMode: stealthMode),
        _bodyFor(record, stealthMode: stealthMode),
        scheduledAt,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _expiryChannel.id,
            _expiryChannel.name,
            channelDescription: _expiryChannel.description,
            icon: 'ic_stat_tempcam',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.private,
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
  }) {
    final buffer = StringBuffer(enabled ? 'on|' : 'off|');
    buffer.write(stealthMode ? 'stealth|' : 'standard|');
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

  String _titleFor(PhotoRecord record, {required bool stealthMode}) {
    if (stealthMode) {
      return 'Reminder';
    }
    return record.isVideo ? 'Video expiring soon' : 'Photo expiring soon';
  }

  String _bodyFor(PhotoRecord record, {required bool stealthMode}) {
    if (stealthMode) {
      return 'One item needs your attention in about 10 minutes.';
    }
    final media = record.isVideo ? 'video' : 'photo';
    return 'Your TempCam $media will auto-delete in about 10 minutes.';
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
