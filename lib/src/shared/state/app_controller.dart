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
  bool _isRecordingVideo = false;
  bool _isVideoMode = false;
  bool _isFlashEnabled = false;
  bool _isStoreAvailable = false;
  bool _isStoreLoading = false;
  bool _isPurchasePending = false;
  bool _isAuthenticatingWithBiometrics = false;
  bool _ignoreNextResumeLock = false;
  String? _billingStatusMessage;
  ProductDetails? _yearlySubscriptionProduct;
  DateTime? _pausedAt;

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
  bool get isRecordingVideo => _isRecordingVideo;
  bool get isVideoMode => _isVideoMode;
  bool get isFlashEnabled => _isFlashEnabled;
  bool get isStoreAvailable => _isStoreAvailable;
  bool get isStoreLoading => _isStoreLoading;
  bool get isPurchasePending => _isPurchasePending;
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
    await _normalizePremiumState();
    await _notificationService.initialize();
    _biometricAvailable = await _biometricService.isAvailable();
    await _initializeBilling();
    await cleanupExpired();
    await _initializeCamera();
    await _refreshThumbnail();
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    _didFinishBootstrap = true;
    _isLocked = hasPremiumAccess && _settings.biometricLockEnabled && _biometricAvailable;
    notifyListeners();
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
      return ResolutionPreset.low;
    }
    return ResolutionPreset.medium;
  }

  ImageFormatGroup get _cameraImageFormatGroup {
    if (Platform.isAndroid) {
      return ImageFormatGroup.yuv420;
    }
    return ImageFormatGroup.bgra8888;
  }

  CameraDescription _selectInitialCamera(List<CameraDescription> cameras) {
    return cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
  }

  Future<void> _configureCameraController(CameraController controller) async {
    await controller.initialize();
    await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    _isFlashEnabled = controller.value.flashMode != FlashMode.off;
    _isRecordingVideo = false;
  }

  Future<void> _initializeCamera() async {
    try {
      _availableCameras = await _cameraService.available();
      if (_availableCameras.isNotEmpty) {
        final initialCamera = _selectInitialCamera(_availableCameras);
        _cameraController = CameraController(
          initialCamera,
          _cameraResolutionPreset,
          enableAudio: false,
          imageFormatGroup: _cameraImageFormatGroup,
        );
        await _configureCameraController(_cameraController!);
      }
    } catch (_) {}
  }

  Future<void> switchCamera() async {
    if (_availableCameras.length < 2 || _cameraController == null) {
      return;
    }
    final current = _cameraController!.description;
    final next = _availableCameras.firstWhere(
      (camera) => camera.lensDirection != current.lensDirection,
      orElse: () => _availableCameras.last,
    );
    await _cameraController?.dispose();
    _cameraController = CameraController(
      next,
      _cameraResolutionPreset,
      enableAudio: false,
      imageFormatGroup: _cameraImageFormatGroup,
    );
    await _configureCameraController(_cameraController!);
    notifyListeners();
  }

  Future<String?> toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return 'Camera is unavailable.';
    }
    try {
      final nextMode = _isFlashEnabled ? FlashMode.off : FlashMode.torch;
      await controller.setFlashMode(nextMode);
      _isFlashEnabled = nextMode != FlashMode.off;
      notifyListeners();
      return null;
    } catch (_) {
      return 'Flash is unavailable on this camera.';
    }
  }

  void toggleCaptureMode() {
    if (_isRecordingVideo) {
      return;
    }
    _isVideoMode = !_isVideoMode;
    notifyListeners();
  }

  Future<String?> handlePrimaryCapture(BuildContext context) async {
    if (_isVideoMode) {
      return toggleVideoRecording();
    }
    await captureWithTimerFlow(context);
    return null;
  }

  Future<String?> toggleVideoRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return 'Camera is unavailable.';
    }
    try {
      if (_isRecordingVideo) {
        final file = await controller.stopVideoRecording();
        _isRecordingVideo = false;
        notifyListeners();
        final name = file.path.split(Platform.pathSeparator).last;
        return 'Video saved: $name';
      }
      await controller.prepareForVideoRecording();
      await controller.startVideoRecording();
      _isRecordingVideo = true;
      notifyListeners();
      return 'Recording started';
    } catch (_) {
      _isRecordingVideo = false;
      notifyListeners();
      return 'Unable to use video recording right now.';
    }
  }

  Future<void> refreshPhotos() async {
    await cleanupExpired();
    _photos = _photoRepository.readAllSorted();
    await _refreshThumbnail();
    notifyListeners();
  }

  Future<void> cleanupExpired() async {
    await _photoRepository.cleanupExpired();
    _photos = _photoRepository.readAllSorted();
  }

  Future<void> _refreshThumbnail() async {
    _latestThumbnail = await _photoRepository.lastThumbnailFile();
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
    try {
      _isCapturing = true;
      notifyListeners();
      final file = await controller.takePicture();
      if (!context.mounted) {
        return;
      }
      final selected = await TimerSelectionSheet.show(
        context,
        settings.defaultTimer,
        hasPremiumAccess: hasPremiumAccess,
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
      _isCapturing = false;
      notifyListeners();
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

  Future<void> keepPhotoForever(PhotoRecord record) async {
    await _photoRepository.keepForever(record);
    await refreshPhotos();
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
    _cameraController?.dispose();
    _billingSubscription.cancel();
    unawaited(_billingService.dispose());
    super.dispose();
  }
}
