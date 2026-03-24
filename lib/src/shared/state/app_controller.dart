import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/constants/premium_constants.dart';
import '../../features/camera/presentation/timer_selection_sheet.dart';
import '../models/app_settings.dart';
import '../models/photo_record.dart';
import '../repositories/photo_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/biometric_service.dart';
import '../services/billing_service.dart';
import '../services/camera_service.dart';
import '../services/notification_service.dart';

class AppController extends ChangeNotifier with WidgetsBindingObserver {
  static const MethodChannel _mediaGalleryChannel = MethodChannel('tempcam/media_gallery');
  AppController({
    required SettingsRepository settingsRepository,
    required PhotoRepository photoRepository,
    required NotificationService notificationService,
    required CameraService cameraService,
    required BiometricService biometricService,
    required BillingService billingService,
  })  : _settingsRepository = settingsRepository,
        _photoRepository = photoRepository,
        _notificationService = notificationService,
        _cameraService = cameraService,
        _biometricService = biometricService,
        _billingService = billingService {
    WidgetsBinding.instance.addObserver(this);
    _billingSubscription = _billingService.events.listen(_handleBillingEvent);
  }

  final SettingsRepository _settingsRepository;
  final PhotoRepository _photoRepository;
  final NotificationService _notificationService;
  final CameraService _cameraService;
  final BiometricService _biometricService;
  final BillingService _billingService;

  late final StreamSubscription<BillingEvent> _billingSubscription;

  AppSettings _settings = AppSettings.defaults();
  List<PhotoRecord> _photos = [];
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = const [];
  File? _latestThumbnail;
  int _currentTabIndex = 1;
  bool _didFinishBootstrap = false;
  bool _isLocked = false;
  bool _isUnlocking = false;
  bool _biometricAvailable = false;
  bool _isCapturing = false;
  Offset? _focusIndicatorPoint;
  Timer? _focusIndicatorTimer;
  Timer? _focusResetTimer;
  DateTime? _lastManualFocusAt;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _currentZoomLevel = 1.0;
  bool _isRecordingVideo = false;
  bool _isVideoMode = false;
  FlashMode _flashMode = FlashMode.auto;
  DateTime? _recordingStartedAt;
  Timer? _recordingDurationTimer;
  bool _isStoreAvailable = false;
  bool _isStoreLoading = false;
  bool _isPurchasePending = false;
  bool _isAuthenticatingWithBiometrics = false;
  bool _ignoreNextResumeLock = false;
  bool _isSwitchingCamera = false;
  String? _billingStatusMessage;
  ProductDetails? _yearlySubscriptionProduct;
  DateTime? _pausedAt;
  int _cameraSetupToken = 0;

  AppSettings get settings => _settings;
  List<PhotoRecord> get photos => _photos;
  CameraController? get cameraController => _cameraController;
  File? get latestThumbnail => _latestThumbnail;
  int get currentTabIndex => _currentTabIndex;
  bool get didFinishBootstrap => _didFinishBootstrap;
  bool get isLocked => _isLocked;
  bool get isUnlocking => _isUnlocking;
  bool get biometricAvailable => _biometricAvailable;
  bool get isCapturing => _isCapturing;
  Offset? get focusIndicatorPoint => _focusIndicatorPoint;
  double get minZoomLevel => _minZoomLevel;
  double get maxZoomLevel => _maxZoomLevel;
  double get currentZoomLevel => _currentZoomLevel;
  bool get isRecordingVideo => _isRecordingVideo;
  bool get isVideoMode => _isVideoMode;
  FlashMode get flashMode => _flashMode;
  bool get isFlashEnabled => _flashMode != FlashMode.off;
  Duration get recordingDuration => _recordingStartedAt == null ? Duration.zero : DateTime.now().difference(_recordingStartedAt!);
  bool get isStoreAvailable => _isStoreAvailable;
  bool get isStoreLoading => _isStoreLoading;
  bool get isPurchasePending => _isPurchasePending;
  bool get isSwitchingCamera => _isSwitchingCamera;
  bool get isUsingDevelopmentBypass => PremiumConstants.paymentsTemporarilyDisabled;
  String? get billingStatusMessage => _billingStatusMessage;
  ProductDetails? get yearlySubscriptionProduct => _yearlySubscriptionProduct;

  bool get hasPremiumAccess {
    if (PremiumConstants.paymentsTemporarilyDisabled) {
      return true;
    }
    if (!_settings.hasPremiumAccess) {
      return false;
    }
    final expiry = _settings.premiumAccessExpiresAt;
    return expiry == null || expiry.isAfter(DateTime.now());
  }

  DateTime? get premiumAccessExpiresAt => _settings.premiumAccessExpiresAt;

  String get yearlyPriceLabel => _yearlySubscriptionProduct?.price ?? PremiumConstants.fallbackYearlyPriceLabel;

  List<PhotoRecord> photosMatching(String query) {
    if (query.trim().isEmpty) {
      return _photos;
    }
    final q = query.toLowerCase();
    return _photos.where((item) {
      return item.timerLabel.toLowerCase().contains(q) || item.createdAt.toIso8601String().toLowerCase().contains(q);
    }).toList();
  }

  Future<void> bootstrap() async {
    _settings = _settingsRepository.read();
    try {
      await _normalizePremiumState();
      try {
        await _notificationService
            .initialize()
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
      try {
        _biometricAvailable = await _biometricService
            .isAvailable()
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        _biometricAvailable = false;
      }
      try {
        await _initializeBilling().timeout(const Duration(seconds: 4));
      } catch (_) {}
      await cleanupExpired();
      try {
        await _initializeCamera().timeout(const Duration(seconds: 5));
      } catch (_) {}
      await _refreshThumbnail();
      try {
        await _syncNotificationsForCurrentPhotos()
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 700));
    } finally {
      _didFinishBootstrap = true;
      _isLocked =
          hasPremiumAccess && _settings.biometricLockEnabled && _biometricAvailable;
      notifyListeners();
    }
  }

  Future<void> _initializeBilling() async {
    if (PremiumConstants.paymentsTemporarilyDisabled) {
      _isStoreAvailable = false;
      _isStoreLoading = false;
      _billingStatusMessage = 'Payments are temporarily disabled for local testing builds.';
      notifyListeners();
      return;
    }

    _isStoreLoading = true;
    notifyListeners();
    try {
      _isStoreAvailable = await _billingService.initialize();
      _yearlySubscriptionProduct = _billingService.yearlyProduct;
      if (_isStoreAvailable && _yearlySubscriptionProduct == null) {
        _billingStatusMessage = 'The yearly subscription is not available in this build yet.';
      }
    } catch (_) {
      _isStoreAvailable = false;
      _billingStatusMessage = 'The App Store / Google Play billing service is unavailable right now.';
    } finally {
      _isStoreLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBillingCatalog() async {
    if (PremiumConstants.paymentsTemporarilyDisabled) {
      _billingStatusMessage = 'Payments are temporarily disabled for local testing builds.';
      notifyListeners();
      return;
    }

    _isStoreLoading = true;
    notifyListeners();
    try {
      _yearlySubscriptionProduct = await _billingService.refreshCatalog();
      _billingStatusMessage = _yearlySubscriptionProduct == null ? 'No yearly subscription product was returned by the store.' : null;
    } catch (_) {
      _billingStatusMessage = 'Unable to refresh products from the store.';
    } finally {
      _isStoreLoading = false;
      notifyListeners();
    }
  }

  Future<String?> purchasePremiumSubscription() async {
    if (PremiumConstants.paymentsTemporarilyDisabled) {
      return 'Payments are temporarily disabled for local testing builds.';
    }

    _billingStatusMessage = null;
    if (!_isStoreAvailable) {
      return 'Billing is unavailable on this device or build.';
    }
    _isPurchasePending = true;
    notifyListeners();
    try {
      final launched = await _billingService.buyYearlySubscription();
      if (!launched) {
        _isPurchasePending = false;
        notifyListeners();
        return 'The yearly subscription product was not found in the store.';
      }
      return null;
    } catch (_) {
      _isPurchasePending = false;
      notifyListeners();
      return 'Unable to start the store purchase flow.';
    }
  }

  Future<String?> restorePremiumPurchases() async {
    if (PremiumConstants.paymentsTemporarilyDisabled) {
      return 'Payments are temporarily disabled for local testing builds.';
    }

    _billingStatusMessage = null;
    if (!_isStoreAvailable) {
      return 'Billing is unavailable on this device or build.';
    }
    _isPurchasePending = true;
    notifyListeners();
    try {
      await _billingService.restorePurchases();
      return 'Restore request sent to the store.';
    } catch (_) {
      _isPurchasePending = false;
      notifyListeners();
      return 'Unable to restore purchases right now.';
    }
  }

  Future<void> enableDevelopmentAccessBypass() async {}

  Future<void> disableDevelopmentAccessBypass() async {}

  Future<void> _handleBillingEvent(BillingEvent event) async {
    if (event.status == BillingEventStatus.pending) {
      _isPurchasePending = true;
      _billingStatusMessage = 'Waiting for store confirmation...';
      notifyListeners();
      return;
    }

    if (event.status == BillingEventStatus.error) {
      _isPurchasePending = false;
      _billingStatusMessage = event.message ?? 'The purchase failed.';
      notifyListeners();
      return;
    }

    if (event.status == BillingEventStatus.canceled) {
      _isPurchasePending = false;
      _billingStatusMessage = event.message ?? 'Purchase canceled.';
      notifyListeners();
      return;
    }

    if (event.status == BillingEventStatus.purchased || event.status == BillingEventStatus.restored) {
      final purchase = event.purchase;
      if (purchase != null && purchase.productID == PremiumConstants.yearlySubscriptionProductId) {
        _isPurchasePending = false;
        await _activatePremiumAccess(purchase);
        _billingStatusMessage = event.status == BillingEventStatus.restored ? 'Your yearly subscription has been restored.' : 'Yearly access unlocked. TempCam is ready to use.';
        notifyListeners();
      }
    }
  }

  Future<void> _activatePremiumAccess(PurchaseDetails purchase) async {
    final transactionDate = _parseStoreDate(purchase.transactionDate);
    final derivedExpiry = (transactionDate ?? DateTime.now()).add(PremiumConstants.subscriptionAccessWindow);
    final savedExpiry = _settings.premiumAccessExpiresAt;
    final expiry = savedExpiry != null && savedExpiry.isAfter(derivedExpiry) ? savedExpiry : derivedExpiry;
    _settings = _settings.copyWith(
      hasPremiumAccess: true,
      debugAccessBypassEnabled: false,
      premiumProductId: purchase.productID,
      premiumAccessExpiresAt: expiry,
      premiumLastValidatedAt: DateTime.now(),
    );
    await _settingsRepository.save(_settings);
  }

  DateTime? _parseStoreDate(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }
    final milliseconds = int.tryParse(rawValue);
    if (milliseconds == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  Future<void> _normalizePremiumState() async {
    if (PremiumConstants.paymentsTemporarilyDisabled) {
      return;
    }

    var updated = false;
    final expiry = _settings.premiumAccessExpiresAt;
    if (_settings.hasPremiumAccess && expiry != null && !expiry.isAfter(DateTime.now())) {
      _settings = _settings.copyWith(
        hasPremiumAccess: false,
        clearPremiumAccessExpiresAt: true,
        clearPremiumProductId: true,
      );
      _isLocked = false;
      updated = true;
    }

    if (!hasPremiumAccess) {
      if (_settings.defaultTimer.requiresPremium) {
        _settings = _settings.copyWith(defaultTimer: AppTimerOption.twentyFourHours);
        updated = true;
      }
      if (_settings.biometricLockEnabled) {
        _settings = _settings.copyWith(biometricLockEnabled: false, clearLastUnlockTime: true);
        updated = true;
      }
    }

    if (updated) {
      await _settingsRepository.save(_settings);
    }
  }

  ResolutionPreset get _cameraResolutionPreset {
    if (Platform.isAndroid) {
      return ResolutionPreset.high;
    }
    return ResolutionPreset.high;
  }

  CameraDescription _selectInitialCamera(List<CameraDescription> cameras) {
    return cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
  }

  Future<void> _configureCameraController(
    CameraController controller, {
    required int token,
  }) async {
    await controller.initialize();
    if (token != _cameraSetupToken || _cameraController != controller) {
      await controller.dispose();
      return;
    }

    _minZoomLevel = 1.0;
    _maxZoomLevel = 8.0;
    _currentZoomLevel = 1.0;
    _focusIndicatorPoint = null;
    _focusResetTimer?.cancel();
    _lastManualFocusAt = null;
    _flashMode = FlashMode.off;
    _isRecordingVideo = false;
    _recordingStartedAt = null;
    _isSwitchingCamera = false;
    notifyListeners();

    unawaited(_finalizeCameraControllerSetup(controller, token));
  }

  Future<void> _finalizeCameraControllerSetup(
    CameraController controller,
    int token,
  ) async {
    try {
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      if (controller.value.focusPointSupported) {
        await controller.setFocusPoint(const Offset(0.5, 0.5));
      }
      if (controller.value.exposurePointSupported) {
        await controller.setExposurePoint(const Offset(0.5, 0.5));
      }
      final minZoomLevel = await controller.getMinZoomLevel();
      var maxZoomLevel = await controller.getMaxZoomLevel();
      if (maxZoomLevel > 8.0) {
        maxZoomLevel = 8.0;
      }
      await controller.setZoomLevel(1.0);
      await controller.setFlashMode(_flashMode);
      if (token != _cameraSetupToken || _cameraController != controller) {
        return;
      }
      _minZoomLevel = minZoomLevel;
      _maxZoomLevel = maxZoomLevel;
      _currentZoomLevel = 1.0;
      notifyListeners();
    } catch (_) {
      if (token != _cameraSetupToken || _cameraController != controller) {
        return;
      }
      _minZoomLevel = 1.0;
      _maxZoomLevel = 8.0;
      _currentZoomLevel = 1.0;
      notifyListeners();
    }
  }

  Future<void> _disposeControllerSafely(CameraController controller) async {
    try {
      await controller.dispose();
    } catch (_) {}
  }

  Future<void> _initializeCamera() async {
    try {
      _availableCameras = await _cameraService.available();
      if (_availableCameras.isNotEmpty) {
        final initialCamera = _selectInitialCamera(_availableCameras);
        final token = ++_cameraSetupToken;
        _cameraController = CameraController(
          initialCamera,
          _cameraResolutionPreset,
          enableAudio: true,
        );
        await _configureCameraController(_cameraController!, token: token);
      }
    } catch (_) {}
  }

  Future<void> switchCamera() async {
    if (_availableCameras.length < 2 || _cameraController == null || _isSwitchingCamera) {
      return;
    }
    _isSwitchingCamera = true;
    notifyListeners();
    final previousController = _cameraController!;
    final current = previousController.description;
    final next = _availableCameras.firstWhere(
      (camera) => camera.lensDirection != current.lensDirection,
      orElse: () => _availableCameras.last,
    );
    final nextController = CameraController(
      next,
      _cameraResolutionPreset,
      enableAudio: true,
    );
    final token = ++_cameraSetupToken;
    try {
      _cameraController = null;
      notifyListeners();
      await _disposeControllerSafely(previousController);
      if (token != _cameraSetupToken) {
        return;
      }
      _cameraController = nextController;
      await _configureCameraController(nextController, token: token);
    } catch (_) {
      _cameraController = null;
      _isSwitchingCamera = false;
      notifyListeners();
      await _disposeControllerSafely(nextController);
      return;
    }
  }

  Future<String?> toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return 'Camera is unavailable.';
    }
    try {
      final preferredModes = _isVideoMode
          ? <FlashMode>[FlashMode.off, FlashMode.torch]
          : <FlashMode>[FlashMode.off, FlashMode.auto, FlashMode.always];
      final currentIndex = preferredModes.indexOf(_flashMode);
      final nextIndex = currentIndex == -1 ? 0 : (currentIndex + 1) % preferredModes.length;
      for (var offset = 0; offset < preferredModes.length; offset++) {
        final candidate = preferredModes[(nextIndex + offset) % preferredModes.length];
        try {
          await controller.setFlashMode(candidate);
          _flashMode = candidate;
          notifyListeners();
          return switch (candidate) {
            FlashMode.auto => 'Flash auto',
            FlashMode.always => 'Flash on',
            FlashMode.torch => 'Flash torch',
            FlashMode.off => 'Flash off',
          };
        } catch (_) {
          continue;
        }
      }
      return 'Flash is unavailable on this camera.';
    } catch (_) {
      return 'Flash is unavailable on this camera.';
    }
  }

  Future<void> focusAtPoint(Offset normalizedPoint) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    final point = Offset(
      normalizedPoint.dx.clamp(0.0, 1.0),
      normalizedPoint.dy.clamp(0.0, 1.0),
    );
    try {
      _focusResetTimer?.cancel();
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      if (controller.value.focusPointSupported) {
        await controller.setFocusPoint(point);
      }
      if (controller.value.exposurePointSupported) {
        await controller.setExposurePoint(point);
      }
      _lastManualFocusAt = DateTime.now();
      _focusIndicatorPoint = point;
      _focusIndicatorTimer?.cancel();
      _focusIndicatorTimer = Timer(const Duration(milliseconds: 1200), () {
        _focusIndicatorPoint = null;
        notifyListeners();
      });
      HapticFeedback.selectionClick();
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (_cameraController != controller || !controller.value.isInitialized) {
        return;
      }
      try {
        await controller.setFocusMode(FocusMode.locked);
      } catch (_) {}
      try {
        await controller.setExposureMode(ExposureMode.locked);
      } catch (_) {}
      _focusResetTimer = Timer(const Duration(seconds: 3), () {
        unawaited(_resetFocusToAuto(controller));
      });
    } catch (_) {}
  }

  Future<void> _resetFocusToAuto(CameraController controller) async {
    if (_cameraController != controller || !controller.value.isInitialized) {
      return;
    }
    try {
      await controller.setFocusMode(FocusMode.auto);
    } catch (_) {}
    try {
      await controller.setExposureMode(ExposureMode.auto);
    } catch (_) {}
    try {
      if (controller.value.focusPointSupported) {
        await controller.setFocusPoint(null);
      }
    } catch (_) {}
    try {
      if (controller.value.exposurePointSupported) {
        await controller.setExposurePoint(null);
      }
    } catch (_) {}
  }

  Future<void> _waitForFocusToSettleIfNeeded() async {
    final lastManualFocusAt = _lastManualFocusAt;
    if (lastManualFocusAt == null) {
      return;
    }
    final elapsed = DateTime.now().difference(lastManualFocusAt);
    if (elapsed >= const Duration(milliseconds: 320)) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 320) - elapsed);
  }

  Future<void> setZoomLevel(double zoomLevel) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    final clampedZoom = zoomLevel.clamp(_minZoomLevel, _maxZoomLevel).toDouble();
    try {
      await controller.setZoomLevel(clampedZoom);
      _currentZoomLevel = clampedZoom;
      notifyListeners();
    } catch (_) {}
  }

  void toggleCaptureMode() {
    if (_isRecordingVideo) {
      return;
    }
    _isVideoMode = !_isVideoMode;
    notifyListeners();
    unawaited(_syncFlashModeForCurrentCaptureMode());
  }

  Future<void> _syncFlashModeForCurrentCaptureMode() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    FlashMode targetMode = _flashMode;
    if (_isVideoMode) {
      if (_flashMode == FlashMode.always || _flashMode == FlashMode.torch) {
        targetMode = FlashMode.torch;
      } else {
        targetMode = FlashMode.off;
      }
    } else {
      if (_flashMode == FlashMode.torch || _flashMode == FlashMode.always) {
        targetMode = FlashMode.always;
      }
    }

    try {
      await controller.setFlashMode(targetMode);
      _flashMode = targetMode;
      notifyListeners();
    } catch (_) {}
  }

  Future<String?> handlePrimaryCapture(BuildContext context) async {
    if (_isVideoMode) {
      return toggleVideoRecording(context);
    }
    await captureWithTimerFlow(context);
    return null;
  }

  Future<String?> toggleVideoRecording(BuildContext context) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return 'Camera is unavailable.';
    }
    try {
      if (_isRecordingVideo) {
        final file = await controller.stopVideoRecording();
        _isRecordingVideo = false;
        _recordingDurationTimer?.cancel();
        _recordingStartedAt = null;
        if (_flashMode == FlashMode.torch) {
          try {
            await controller.setFlashMode(FlashMode.off);
          } catch (_) {}
          _flashMode = FlashMode.off;
        }
        notifyListeners();
        if (!context.mounted) {
          return null;
        }
        final selected = await TimerSelectionSheet.show(
          context,
          settings.defaultTimer,
          hasPremiumAccess: hasPremiumAccess,
        );
        if (!context.mounted) {
          return null;
        }
        final appliedTimer = selected ?? settings.defaultTimer;
        await _photoRepository.createVideoFromCapture(
          sourcePath: file.path,
          timer: appliedTimer,
        );
        await refreshPhotos();
        _currentTabIndex = 0;
        notifyListeners();
        return 'Video saved to TempCam';
      }
      await controller.prepareForVideoRecording();
      await controller.startVideoRecording();
      _isRecordingVideo = true;
      _recordingStartedAt = DateTime.now();
      _recordingDurationTimer?.cancel();
      _recordingDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        notifyListeners();
      });
      notifyListeners();
      return 'Recording started';
    } catch (_) {
      _isRecordingVideo = false;
      _recordingDurationTimer?.cancel();
      _recordingStartedAt = null;
      notifyListeners();
      return 'Unable to use video recording right now.';
    }
  }

  Future<String?> _exportMediaToMainGallery(PhotoRecord record) async {
    if (!Platform.isAndroid) {
      return record.filePath;
    }
    try {
      final extension = record.isVideo ? '.mp4' : '.jpg';
      final displayName = 'tempcam_${DateTime.now().millisecondsSinceEpoch}$extension';
      return await _mediaGalleryChannel.invokeMethod<String>(
        record.isVideo ? 'saveVideoToGallery' : 'saveImageToGallery',
        <String, dynamic>{
          'sourcePath': record.filePath,
          'displayName': displayName,
        },
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshPhotos() async {
    await cleanupExpired();
    _photos = _photoRepository.readAllSorted();
    await _refreshThumbnail();
    await _syncNotificationsForCurrentPhotos();
    notifyListeners();
  }

  Future<void> cleanupExpired() async {
    await _photoRepository.cleanupExpired();
    _photos = _photoRepository.readAllSorted();
  }

  Future<void> _refreshThumbnail() async {
    _latestThumbnail = await _photoRepository.lastThumbnailFileFromSorted(_photos);
  }

  Future<void> _syncNotificationsForCurrentPhotos() async {
    await _notificationService.syncExpiryNotifications(
      _photos,
      enabled: _settings.notificationsEnabled,
    );
  }

  void setTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  Future<void> captureWithTimerFlow(BuildContext context) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }
    XFile? file;
    try {
      _isCapturing = true;
      notifyListeners();
      await _waitForFocusToSettleIfNeeded();
      file = await controller.takePicture();
      _isCapturing = false;
      notifyListeners();
      if (!context.mounted) {
        return;
      }
      final selected = await TimerSelectionSheet.show(
        context,
        settings.defaultTimer,
        hasPremiumAccess: hasPremiumAccess,
        previewFilePath: file.path,
      );
      if (!context.mounted) {
        return;
      }
      final appliedTimer = selected ?? settings.defaultTimer;
      await _photoRepository.createFromCapture(sourcePath: file.path, timer: appliedTimer);
      await refreshPhotos();
      _currentTabIndex = 0;
      notifyListeners();
    } finally {
      if (_isCapturing) {
        _isCapturing = false;
        notifyListeners();
      }
    }
  }

  Future<void> updateDefaultTimer(AppTimerOption option) async {
    _settings = _settings.copyWith(defaultTimer: option);
    await _settingsRepository.save(_settings);
    notifyListeners();
  }

  Future<void> updateNotifications(bool enabled) async {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    await _settingsRepository.save(_settings);
    if (enabled) {
      await _syncNotificationsForCurrentPhotos();
    } else {
      await _notificationService.cancelAll();
    }
    notifyListeners();
  }

  Future<void> updateBiometricLock(bool enabled) async {
    if (enabled && _biometricAvailable) {
      _isAuthenticatingWithBiometrics = true;
      notifyListeners();
      try {
        final authenticated = await _biometricService.authenticate();
        if (!authenticated) {
          return;
        }
      } finally {
        _isAuthenticatingWithBiometrics = false;
        _ignoreNextResumeLock = true;
      }
    }
    _settings = _settings.copyWith(
      biometricLockEnabled: enabled,
      lastUnlockTime: enabled ? DateTime.now() : null,
      clearLastUnlockTime: !enabled,
    );
    await _settingsRepository.save(_settings);
    _isLocked = false;
    notifyListeners();
  }

  Future<bool> unlockApp() async {
    if (!_settings.biometricLockEnabled || !_biometricAvailable) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    _isUnlocking = true;
    _isAuthenticatingWithBiometrics = true;
    notifyListeners();
    try {
      final success = await _biometricService.authenticate();
      if (success) {
        _isLocked = false;
        _pausedAt = null;
        _settings = _settings.copyWith(lastUnlockTime: DateTime.now());
        await _settingsRepository.save(_settings);
      }
      return success;
    } finally {
      _isUnlocking = false;
      _isAuthenticatingWithBiometrics = false;
      _ignoreNextResumeLock = true;
      notifyListeners();
    }
  }

  Future<bool> unlockForSensitiveAccess() async {
    if (!_settings.biometricLockEnabled || !_biometricAvailable) {
      return true;
    }
    return unlockApp();
  }

  Future<void> deletePhoto(PhotoRecord record) async {
    await _photoRepository.deleteNow(record);
    await refreshPhotos();
  }

  Future<String?> keepPhotoForever(PhotoRecord record) async {
    final exportedPath = await _exportMediaToMainGallery(record);
    if (exportedPath == null) {
      return 'Unable to export this item to the main gallery.';
    }
    await _photoRepository.keepForever(record);
    await refreshPhotos();
    return record.isVideo ? 'Video kept forever and exported.' : 'Photo kept forever and exported.';
  }

  Future<void> extendPhoto(PhotoRecord record, AppTimerOption timer) async {
    await _photoRepository.extend(record, timer);
    await refreshPhotos();
  }

  PhotoRecord? byId(String id) {
    try {
      return _photos.firstWhere((photo) => photo.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isAuthenticatingWithBiometrics) {
      return;
    }
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (_ignoreNextResumeLock) {
        _ignoreNextResumeLock = false;
        return;
      }
      unawaited(_handleResume());
    }
  }

  Future<void> _handleResume() async {
    await refreshPhotos();
    await _normalizePremiumState();
    if (!hasPremiumAccess) {
      _isLocked = false;
      notifyListeners();
      return;
    }
    if (!_settings.biometricLockEnabled || !_biometricAvailable) {
      notifyListeners();
      return;
    }
    final pausedAt = _pausedAt;
    if (pausedAt == null) {
      _isLocked = true;
    } else if (DateTime.now().difference(pausedAt) >= const Duration(seconds: 12)) {
      _isLocked = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusIndicatorTimer?.cancel();
    _focusResetTimer?.cancel();
    _recordingDurationTimer?.cancel();
    final controller = _cameraController;
    if (controller != null) {
      unawaited(_disposeControllerSafely(controller));
    }
    _billingSubscription.cancel();
    unawaited(_billingService.dispose());
    super.dispose();
  }
}
