import 'package:hive/hive.dart';

enum AppTimerOption {
  oneHour('1 Hour', Duration(hours: 1)),
  threeHours('3 Hours', Duration(hours: 3)),
  twelveHours('12 Hours', Duration(hours: 12)),
  twentyFourHours('24 Hours', Duration(hours: 24)),
  threeDays('3 Days', Duration(days: 3)),
  sevenDays('7 Days', Duration(days: 7));

  const AppTimerOption(this.label, this.duration);

  final String label;
  final Duration duration;

  static List<AppTimerOption> get captureOptions => const [
        AppTimerOption.oneHour,
        AppTimerOption.threeHours,
        AppTimerOption.twelveHours,
        AppTimerOption.twentyFourHours,
        AppTimerOption.threeDays,
        AppTimerOption.sevenDays,
      ];

  static List<AppTimerOption> get settingsDefaults => const [
        AppTimerOption.twentyFourHours,
        AppTimerOption.sevenDays,
      ];
}

extension AppTimerOptionX on AppTimerOption {
  bool get requiresPremium => this == AppTimerOption.sevenDays;
}

class AppSettings {
  AppSettings({
    required this.defaultTimer,
    required this.notificationsEnabled,
    required this.biometricLockEnabled,
    required this.hasPremiumAccess,
    required this.debugAccessBypassEnabled,
    this.lastUnlockTime,
    this.premiumAccessExpiresAt,
    this.premiumProductId,
    this.premiumLastValidatedAt,
  });

  final AppTimerOption defaultTimer;
  final bool notificationsEnabled;
  final bool biometricLockEnabled;
  final bool hasPremiumAccess;
  final bool debugAccessBypassEnabled;
  final DateTime? lastUnlockTime;
  final DateTime? premiumAccessExpiresAt;
  final String? premiumProductId;
  final DateTime? premiumLastValidatedAt;

  AppSettings copyWith({
    AppTimerOption? defaultTimer,
    bool? notificationsEnabled,
    bool? biometricLockEnabled,
    bool? hasPremiumAccess,
    bool? debugAccessBypassEnabled,
    DateTime? lastUnlockTime,
    bool clearLastUnlockTime = false,
    DateTime? premiumAccessExpiresAt,
    bool clearPremiumAccessExpiresAt = false,
    String? premiumProductId,
    bool clearPremiumProductId = false,
    DateTime? premiumLastValidatedAt,
    bool clearPremiumLastValidatedAt = false,
  }) {
    return AppSettings(
      defaultTimer: defaultTimer ?? this.defaultTimer,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      hasPremiumAccess: hasPremiumAccess ?? this.hasPremiumAccess,
      debugAccessBypassEnabled: debugAccessBypassEnabled ?? this.debugAccessBypassEnabled,
      lastUnlockTime: clearLastUnlockTime ? null : lastUnlockTime ?? this.lastUnlockTime,
      premiumAccessExpiresAt: clearPremiumAccessExpiresAt ? null : premiumAccessExpiresAt ?? this.premiumAccessExpiresAt,
      premiumProductId: clearPremiumProductId ? null : premiumProductId ?? this.premiumProductId,
      premiumLastValidatedAt: clearPremiumLastValidatedAt ? null : premiumLastValidatedAt ?? this.premiumLastValidatedAt,
    );
  }

  factory AppSettings.defaults() {
    return AppSettings(
      defaultTimer: AppTimerOption.twentyFourHours,
      notificationsEnabled: true,
      biometricLockEnabled: false,
      hasPremiumAccess: false,
      debugAccessBypassEnabled: false,
    );
  }
}

class AppTimerOptionAdapter extends TypeAdapter<AppTimerOption> {
  @override
  final int typeId = 0;

  @override
  AppTimerOption read(BinaryReader reader) {
    return AppTimerOption.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, AppTimerOption obj) {
    writer.writeByte(obj.index);
  }
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 1;

  @override
  AppSettings read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return AppSettings(
      defaultTimer: fields[0] as AppTimerOption? ?? AppTimerOption.twentyFourHours,
      notificationsEnabled: fields[1] as bool? ?? true,
      biometricLockEnabled: fields[2] as bool? ?? false,
      lastUnlockTime: fields[3] as DateTime?,
      hasPremiumAccess: fields[4] as bool? ?? false,
      premiumAccessExpiresAt: fields[5] as DateTime?,
      premiumProductId: fields[6] as String?,
      premiumLastValidatedAt: fields[7] as DateTime?,
      debugAccessBypassEnabled: fields[8] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.defaultTimer)
      ..writeByte(1)
      ..write(obj.notificationsEnabled)
      ..writeByte(2)
      ..write(obj.biometricLockEnabled)
      ..writeByte(3)
      ..write(obj.lastUnlockTime)
      ..writeByte(4)
      ..write(obj.hasPremiumAccess)
      ..writeByte(5)
      ..write(obj.premiumAccessExpiresAt)
      ..writeByte(6)
      ..write(obj.premiumProductId)
      ..writeByte(7)
      ..write(obj.premiumLastValidatedAt)
      ..writeByte(8)
      ..write(obj.debugAccessBypassEnabled);
  }
}
