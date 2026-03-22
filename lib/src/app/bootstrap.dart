import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../shared/models/app_settings.dart';
import '../shared/models/photo_record.dart';
import '../shared/repositories/photo_repository.dart';
import '../shared/repositories/settings_repository.dart';
import '../shared/services/biometric_service.dart';
import '../shared/services/billing_service.dart';
import '../shared/services/camera_service.dart';
import '../shared/services/notification_service.dart';
import '../shared/services/photo_storage_service.dart';
import '../shared/state/app_controller.dart';
import 'tempcam_app.dart';

Future<void> bootstrap() async {
  Hive
    ..registerAdapter(AppTimerOptionAdapter())
    ..registerAdapter(AppSettingsAdapter())
    ..registerAdapter(PhotoRecordAdapter());

  final settingsBox = await Hive.openBox<AppSettings>('settings');
  final photosBox = await Hive.openBox<PhotoRecord>('photos');

  final controller = AppController(
    settingsRepository: SettingsRepository(settingsBox),
    photoRepository: PhotoRepository(photosBox, PhotoStorageService()),
    notificationService: NotificationService(),
    cameraService: CameraService(),
    biometricService: BiometricService(),
    billingService: BillingService(),
  );

  await controller.bootstrap();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppController>.value(value: controller),
      ],
      child: const TempCamApp(),
    ),
  );
}
