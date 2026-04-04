import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../shared/models/app_settings.dart';
import '../shared/models/photo_record.dart';
import '../shared/models/vault_history_entry.dart';
import '../shared/repositories/photo_repository.dart';
import '../shared/repositories/settings_repository.dart';
import '../shared/repositories/vault_history_repository.dart';
import '../shared/services/biometric_service.dart';
import '../shared/services/billing_service.dart';
import '../shared/services/camera_service.dart';
import '../shared/services/document_scan_service.dart';
import '../shared/services/notification_service.dart';
import '../shared/services/photo_storage_service.dart';
import '../shared/services/system_action_service.dart';
import '../shared/state/app_controller.dart';
import 'tempcam_app.dart';

Future<void> bootstrap() async {
  Hive
    ..registerAdapter(AppTimerOptionAdapter())
    ..registerAdapter(QuickLockTimeoutOptionAdapter())
    ..registerAdapter(AppSettingsAdapter())
    ..registerAdapter(PhotoRecordAdapter())
    ..registerAdapter(VaultHistoryEventTypeAdapter())
    ..registerAdapter(VaultHistoryEntryAdapter());

  final settingsBox = await Hive.openBox<AppSettings>('settings');
  final photosBox = await Hive.openBox<PhotoRecord>('photos');
  final historyBox = await Hive.openBox<VaultHistoryEntry>('vault_history');

  final controller = AppController(
    settingsRepository: SettingsRepository(settingsBox),
    photoRepository: PhotoRepository(photosBox, PhotoStorageService()),
    vaultHistoryRepository: VaultHistoryRepository(historyBox),
    notificationService: NotificationService(),
    cameraService: CameraService(),
    documentScanService: DocumentScanService(),
    systemActionService: SystemActionService(),
    biometricService: BiometricService(),
    billingService: BillingService(),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppController>.value(value: controller),
      ],
      child: const TempCamApp(),
    ),
  );

  unawaited(controller.bootstrap());
}
