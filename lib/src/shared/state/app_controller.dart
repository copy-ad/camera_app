import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../core/constants/premium_constants.dart';
import '../../features/camera/presentation/document_action_sheet.dart';
import '../../features/camera/presentation/timer_selection_sheet.dart';
import '../../features/paywall/presentation/premium_paywall_screen.dart';
import '../../localization/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/photo_record.dart';
import '../models/vault_history_entry.dart';
import '../repositories/photo_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/vault_history_repository.dart';
import '../services/biometric_service.dart';
import '../services/billing_service.dart';
import '../services/camera_service.dart';
import '../services/document_scan_service.dart';
import '../services/notification_service.dart';
import '../services/system_action_service.dart';

class _ImportedDeviceMedia {
  const _ImportedDeviceMedia({
    required this.tempPath,
    required this.mediaType,
    this.sourceHandle,
  });

  final String tempPath;
  final MediaType mediaType;
  final String? sourceHandle;

  Map<String, dynamic> toChannelMap() {
    return <String, dynamic>{
      'tempPath': tempPath,
      'mediaType': mediaType.name,
      'sourceHandle': sourceHandle,
    };
  }

  static _ImportedDeviceMedia? fromMap(dynamic value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final tempPath = map['tempPath']?.toString();
    if (tempPath == null || tempPath.isEmpty) {
      return null;
    }
    final mediaTypeName = map['mediaType']?.toString();
    final mediaType = MediaType.values.firstWhere(
      (item) => item.name == mediaTypeName,
      orElse: () => _fallbackMediaTypeFromPath(tempPath),
    );
    final sourceHandle = map['sourceHandle']?.toString();
    return _ImportedDeviceMedia(
      tempPath: tempPath,
      mediaType: mediaType,
      sourceHandle:
          sourceHandle == null || sourceHandle.isEmpty ? null : sourceHandle,
    );
  }

  static MediaType _fallbackMediaTypeFromPath(String path) {
    final lowerPath = path.toLowerCase();
    const videoExtensions = {
      '.mp4',
      '.mov',
      '.m4v',
      '.avi',
      '.mkv',
      '.webm',
      '.3gp',
    };
    return videoExtensions.any(lowerPath.endsWith)
        ? MediaType.video
        : MediaType.photo;
  }
}

class LiveScanResult {
  const LiveScanResult({
    this.phoneNumber,
    this.address,
  });

  final String? phoneNumber;
  final String? address;

  bool get hasData =>
      (phoneNumber != null && phoneNumber!.isNotEmpty) ||
      (address != null && address!.isNotEmpty);

  bool isSameAs(LiveScanResult other) {
    return phoneNumber == other.phoneNumber && address == other.address;
  }
}

class AppController extends ChangeNotifier with WidgetsBindingObserver {
  static const MethodChannel _mediaGalleryChannel =
      MethodChannel('tempcam/media_gallery');
  static const Duration _liveScanMinInterval = Duration(milliseconds: 900);
  static const Duration _liveScanCooldownDuration = Duration(seconds: 8);
  static const Duration _liveScanResultHoldDuration = Duration(seconds: 3);
  AppController({
    required SettingsRepository settingsRepository,
    required PhotoRepository photoRepository,
    required VaultHistoryRepository vaultHistoryRepository,
    required NotificationService notificationService,
    required CameraService cameraService,
    required DocumentScanService documentScanService,
    required SystemActionService systemActionService,
    required BiometricService biometricService,
    required BillingService billingService,
  })  : _settingsRepository = settingsRepository,
        _photoRepository = photoRepository,
        _vaultHistoryRepository = vaultHistoryRepository,
        _notificationService = notificationService,
        _cameraService = cameraService,
        _documentScanService = documentScanService,
        _systemActionService = systemActionService,
        _biometricService = biometricService,
        _billingService = billingService {
    WidgetsBinding.instance.addObserver(this);
    _billingSubscription = _billingService.events.listen(_handleBillingEvent);
  }

  final SettingsRepository _settingsRepository;
  final PhotoRepository _photoRepository;
  final VaultHistoryRepository _vaultHistoryRepository;
  final NotificationService _notificationService;
  final CameraService _cameraService;
  final DocumentScanService _documentScanService;
  final SystemActionService _systemActionService;
  final BiometricService _biometricService;
  final BillingService _billingService;
  final ImagePicker _mediaPicker = ImagePicker();

  late final StreamSubscription<BillingEvent> _billingSubscription;

  AppSettings _settings = AppSettings.defaults();
  List<PhotoRecord> _photos = [];
  List<VaultHistoryEntry> _vaultHistory = [];
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
  bool _isPreviewShieldActive = false;
  String? _billingStatusMessage;
  ProductDetails? _yearlySubscriptionProduct;
  DateTime? _pausedAt;
  int _cameraSetupToken = 0;
  String? _pendingSmartScanPhotoId;
  bool _isLiveScanStreaming = false;
  bool _isLiveScanProcessing = false;
  DateTime? _lastLiveScanProcessedAt;
  DateTime? _liveScanCooldownUntil;
  Timer? _liveScanResultHoldTimer;
  final List<LiveScanResult> _recentLiveScanResults = [];
  LiveScanResult _liveScanResult = const LiveScanResult();

  AppSettings get settings => _settings;
  List<PhotoRecord> get photos => _photos;
  List<VaultHistoryEntry> get vaultHistory => _vaultHistory;
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
  Duration get recordingDuration => _recordingStartedAt == null
      ? Duration.zero
      : DateTime.now().difference(_recordingStartedAt!);
  bool get isStoreAvailable => _isStoreAvailable;
  bool get isStoreLoading => _isStoreLoading;
  bool get isPurchasePending => _isPurchasePending;
  bool get isSwitchingCamera => _isSwitchingCamera;
  bool get isPreviewShieldActive => _isPreviewShieldActive;
  bool get isUsingDevelopmentBypass =>
      PremiumConstants.paymentsTemporarilyDisabled;
  String? get billingStatusMessage => _billingStatusMessage;
  ProductDetails? get yearlySubscriptionProduct => _yearlySubscriptionProduct;
  String? get pendingSmartScanPhotoId => _pendingSmartScanPhotoId;
  LiveScanResult get liveScanResult => _liveScanResult;
  bool get hasLiveScanResult => _liveScanResult.hasData;
  bool get hasStoreManagedTrialOffer =>
      _billingService.hasStoreManagedTrialOffer;
  Locale? get localeOverride =>
      AppLocalizations.parseLocaleTag(_settings.localeTag);
  Locale get activeLocale {
    final override = localeOverride;
    if (override != null) {
      return override;
    }
    return AppLocalizations.resolveSupportedLocale(
      WidgetsBinding.instance.platformDispatcher.locale,
    );
  }

  AppLocalizations get l10n => AppLocalizations.fromLocale(activeLocale);

  bool get hasStoreSubscriptionAccess {
    return _settings.hasPremiumAccess;
  }

  bool get shouldShowTrialStartedNotice =>
      !PremiumConstants.paymentsTemporarilyDisabled &&
      !hasStoreSubscriptionAccess &&
      !_settings.trialNoticeShown;

  bool get shouldShowAppTour => !_settings.tourCompleted;

  bool get hasPremiumAccess {
    if (PremiumConstants.paymentsTemporarilyDisabled) {
      return true;
    }
    return hasStoreSubscriptionAccess;
  }

  bool get canSaveTemporaryMedia => hasPremiumAccess;

  DateTime? get premiumAccessExpiresAt => _settings.premiumAccessExpiresAt;

  String get yearlyPriceLabel =>
      _yearlySubscriptionProduct?.price ??
      PremiumConstants.fallbackYearlyPriceLabel;

  List<PhotoRecord> photosMatching(String query) {
    if (query.trim().isEmpty) {
      return _photos;
    }
    final q = query.toLowerCase();
    return _photos.where((item) {
      return item.timerLabel.toLowerCase().contains(q) ||
          item.createdAt.toIso8601String().toLowerCase().contains(q);
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
      _refreshVaultHistory();
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
      _isLocked = hasPremiumAccess &&
          _settings.biometricLockEnabled &&
          _biometricAvailable;
      notifyListeners();
    }
  }

  Future<void> markTrialStartedNoticeSeen() async {
    if (_settings.trialNoticeShown) {
      return;
    }
    _settings = _settings.copyWith(trialNoticeShown: true);
    await _settingsRepository.save(_settings);
    notifyListeners();
  }

  Future<void> markTourCompleted() async {
    if (_settings.tourCompleted) {
      return;
    }
    _settings = _settings.copyWith(tourCompleted: true);
    await _settingsRepository.save(_settings);
    notifyListeners();
  }

  Future<void> reopenTour() async {
    if (!_settings.tourCompleted) {
      return;
    }
    _settings = _settings.copyWith(tourCompleted: false);
    await _settingsRepository.save(_settings);
    notifyListeners();
  }

  Future<void> updateLanguageTag(String? tag) async {
    final normalizedTag = tag == null || tag.isEmpty ? null : tag;
    if (_settings.localeTag == normalizedTag) {
      return;
    }
    _settings = normalizedTag == null
        ? _settings.copyWith(clearLocaleTag: true)
        : _settings.copyWith(localeTag: normalizedTag);
    await _settingsRepository.save(_settings);
    await _resyncNotificationsSilently();
    notifyListeners();
  }

  Future<void> _initializeBilling() async {
    if (PremiumConstants.paymentsTemporarilyDisabled) {
      _isStoreAvailable = false;
      _isStoreLoading = false;
      _billingStatusMessage =
          'Payments are disabled for this build via TEMPCAM_DISABLE_PAYMENTS.';
      notifyListeners();
      return;
    }

    _isStoreLoading = true;
    notifyListeners();
    try {
      _isStoreAvailable = await _billingService.initialize();
      _yearlySubscriptionProduct = _billingService.yearlyProduct;
      if (_isStoreAvailable && _yearlySubscriptionProduct == null) {
        _billingStatusMessage =
            'The yearly subscription is not available in this build yet.';
      } else if (_isStoreAvailable) {
        await _refreshStoreEntitlementStatus();
        if (!Platform.isAndroid) {
          unawaited(_syncExistingStorePurchases());
        }
      }
    } catch (_) {
      _isStoreAvailable = false;
      _billingStatusMessage =
          'The App Store / Google Play billing service is unavailable right now.';
    } finally {
      _isStoreLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBillingCatalog() async {
    if (PremiumConstants.paymentsTemporarilyDisabled) {
      _billingStatusMessage =
          'Payments are disabled for this build via TEMPCAM_DISABLE_PAYMENTS.';
      notifyListeners();
      return;
    }

    _isStoreLoading = true;
    notifyListeners();
    try {
      _yearlySubscriptionProduct = await _billingService.refreshCatalog();
      _billingStatusMessage = _yearlySubscriptionProduct == null
          ? 'No yearly subscription product was returned by the store.'
          : null;
    } catch (_) {
      _billingStatusMessage = 'Unable to refresh products from the store.';
    } finally {
      _isStoreLoading = false;
      notifyListeners();
    }
  }

  Future<String?> purchasePremiumSubscription() async {
    if (PremiumConstants.paymentsTemporarilyDisabled) {
      return 'Payments are disabled for this build via TEMPCAM_DISABLE_PAYMENTS.';
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
      return 'Payments are disabled for this build via TEMPCAM_DISABLE_PAYMENTS.';
    }

    _billingStatusMessage = null;
    if (!_isStoreAvailable) {
      return 'Billing is unavailable on this device or build.';
    }
    _isPurchasePending = true;
    notifyListeners();
    try {
      await _billingService.restorePurchases();
      await _refreshStoreEntitlementStatus();
      _isPurchasePending = false;
      notifyListeners();
      return l10n.tr('Restore request sent to the store.');
    } catch (_) {
      _isPurchasePending = false;
      notifyListeners();
      return 'Unable to restore purchases right now.';
    }
  }

  Future<void> enableDevelopmentAccessBypass() async {}

  Future<void> disableDevelopmentAccessBypass() async {}

  Future<bool> promptForPremiumAccess(BuildContext context) async {
    if (hasPremiumAccess || !context.mounted) {
      return hasPremiumAccess;
    }
    await PremiumPaywallScreen.show(context);
    return hasPremiumAccess;
  }

  Future<void> _syncExistingStorePurchases() async {
    if (!_isStoreAvailable || PremiumConstants.paymentsTemporarilyDisabled) {
      return;
    }
    try {
      await _billingService.restorePurchases();
    } catch (_) {}
  }

  Future<void> _handleBillingEvent(BillingEvent event) async {
    if (event.status == BillingEventStatus.pending) {
      _isPurchasePending = true;
      _billingStatusMessage = l10n.tr('Waiting for store confirmation...');
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

    if (event.status == BillingEventStatus.purchased ||
        event.status == BillingEventStatus.restored) {
      final purchase = event.purchase;
      if (purchase != null &&
          purchase.productID == PremiumConstants.yearlySubscriptionProductId) {
        _isPurchasePending = false;
        await _activatePremiumAccess(purchase);
        _billingStatusMessage = event.status == BillingEventStatus.restored
            ? l10n.tr('Your yearly subscription has been restored.')
            : l10n.tr('Yearly access unlocked. TempCam is ready to use.');
        notifyListeners();
      }
    }
  }

  Future<void> _activatePremiumAccess(PurchaseDetails purchase) async {
    _settings = _settings.copyWith(
      hasPremiumAccess: true,
      debugAccessBypassEnabled: false,
      trialNoticeShown: true,
      premiumProductId: purchase.productID,
      clearPremiumAccessExpiresAt: true,
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
    if (!hasPremiumAccess) {
      if (_settings.defaultTimer.requiresPremium) {
        _settings =
            _settings.copyWith(defaultTimer: AppTimerOption.twentyFourHours);
        updated = true;
      }
      if (_settings.biometricLockEnabled) {
        _settings = _settings.copyWith(
            biometricLockEnabled: false, clearLastUnlockTime: true);
        updated = true;
      }
    }

    if (updated) {
      await _settingsRepository.save(_settings);
    }
  }

  Future<void> _refreshStoreEntitlementStatus() async {
    if (!_isStoreAvailable || PremiumConstants.paymentsTemporarilyDisabled) {
      return;
    }
    if (!Platform.isAndroid) {
      return;
    }
    try {
      final purchases = await _billingService.queryActivePurchases();
      final matches = purchases
          .where(
            (purchase) =>
                purchase.productID ==
                PremiumConstants.yearlySubscriptionProductId,
          )
          .toList(growable: false);
      if (matches.isEmpty) {
        if (_settings.hasPremiumAccess ||
            _settings.premiumProductId != null ||
            _settings.premiumAccessExpiresAt != null) {
          _settings = _settings.copyWith(
            hasPremiumAccess: false,
            clearPremiumAccessExpiresAt: true,
            clearPremiumProductId: true,
          );
          _isLocked = false;
          await _settingsRepository.save(_settings);
        }
        return;
      }
      final latest = matches.reduce((current, next) {
        final currentDate = _parseStoreDate(current.transactionDate) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final nextDate = _parseStoreDate(next.transactionDate) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return nextDate.isAfter(currentDate) ? next : current;
      });
      await _activatePremiumAccess(latest);
    } catch (_) {}
  }

  ResolutionPreset get _cameraResolutionPreset {
    if (Platform.isAndroid) {
      return ResolutionPreset.high;
    }
    return ResolutionPreset.high;
  }

  ImageFormatGroup get _cameraImageFormatGroup {
    if (Platform.isAndroid) {
      return ImageFormatGroup.nv21;
    }
    if (Platform.isIOS) {
      return ImageFormatGroup.bgra8888;
    }
    return ImageFormatGroup.unknown;
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
      await _syncLiveScanState();
    } catch (_) {
      if (token != _cameraSetupToken || _cameraController != controller) {
        return;
      }
      _minZoomLevel = 1.0;
      _maxZoomLevel = 8.0;
      _currentZoomLevel = 1.0;
      notifyListeners();
      await _syncLiveScanState();
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
          imageFormatGroup: _cameraImageFormatGroup,
        );
        await _configureCameraController(_cameraController!, token: token);
      }
    } catch (_) {}
  }

  Future<void> switchCamera() async {
    if (_availableCameras.length < 2 ||
        _cameraController == null ||
        _isSwitchingCamera) {
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
      imageFormatGroup: _cameraImageFormatGroup,
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
      return l10n.tr('Camera is unavailable.');
    }
    try {
      final preferredModes = _isVideoMode
          ? <FlashMode>[FlashMode.off, FlashMode.torch]
          : <FlashMode>[FlashMode.off, FlashMode.auto, FlashMode.always];
      final currentIndex = preferredModes.indexOf(_flashMode);
      final nextIndex =
          currentIndex == -1 ? 0 : (currentIndex + 1) % preferredModes.length;
      for (var offset = 0; offset < preferredModes.length; offset++) {
        final candidate =
            preferredModes[(nextIndex + offset) % preferredModes.length];
        try {
          await controller.setFlashMode(candidate);
          _flashMode = candidate;
          notifyListeners();
          return switch (candidate) {
            FlashMode.auto => l10n.tr('Flash auto'),
            FlashMode.always => l10n.tr('Flash on'),
            FlashMode.torch => l10n.tr('Flash torch'),
            FlashMode.off => l10n.tr('Flash off'),
          };
        } catch (_) {
          continue;
        }
      }
      return l10n.tr('Flash is unavailable on this camera.');
    } catch (_) {
      return l10n.tr('Flash is unavailable on this camera.');
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
    _focusResetTimer?.cancel();
    _lastManualFocusAt = DateTime.now();
    _focusIndicatorPoint = point;
    _focusIndicatorTimer?.cancel();
    _focusIndicatorTimer = Timer(const Duration(milliseconds: 1200), () {
      _focusIndicatorPoint = null;
      notifyListeners();
    });
    notifyListeners();
    unawaited(HapticFeedback.selectionClick());
    try {
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      if (controller.value.focusPointSupported) {
        await controller.setFocusPoint(point);
      }
      if (controller.value.exposurePointSupported) {
        await controller.setExposurePoint(point);
      }
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
    final clampedZoom =
        zoomLevel.clamp(_minZoomLevel, _maxZoomLevel).toDouble();
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
    unawaited(_syncLiveScanState());
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
      return l10n.tr('Camera is unavailable.');
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
        if (!hasPremiumAccess) {
          final unlocked = await promptForPremiumAccess(context);
          if (!context.mounted) {
            await _discardTransientFile(file.path);
            return null;
          }
          if (!unlocked) {
            await _discardTransientFile(file.path);
            return null;
          }
        }
        final selected = await TimerSelectionSheet.show(
          context,
          settings.defaultTimer,
          hasPremiumAccess: hasPremiumAccess,
          previewFilePath: file.path,
          previewMediaType: MediaType.video,
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
        return l10n.tr('Video saved to TempCam');
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
      return l10n.tr('Recording started');
    } catch (_) {
      _isRecordingVideo = false;
      _recordingDurationTimer?.cancel();
      _recordingStartedAt = null;
      notifyListeners();
      return l10n.tr('Unable to use video recording right now.');
    }
  }

  Future<String?> _exportMediaToMainGallery(PhotoRecord record) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return record.filePath;
    }
    try {
      final extension = record.isVideo ? '.mp4' : '.jpg';
      final displayName =
          'tempcam_${DateTime.now().millisecondsSinceEpoch}$extension';
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
    _refreshVaultHistory();
    await _refreshThumbnail();
    await _syncNotificationsForCurrentPhotos();
    notifyListeners();
  }

  Future<void> cleanupExpired() async {
    final expired = await _photoRepository.cleanupExpired();
    _photos = _photoRepository.readAllSorted();
    for (final item in expired) {
      await _recordVaultHistory(
        eventType: VaultHistoryEventType.autoDeleted,
        title:
            l10n.tr(item.isVideo ? 'Video auto-deleted' : 'Photo auto-deleted'),
        details: l10n.tr(
          '{media} expired after {timer} and was removed from TempCam.',
          {
            'media': l10n.tr(item.isVideo ? 'Video' : 'Photo'),
            'timer': l10n.timerLabelFromString(item.timerLabel).toLowerCase(),
          },
        ),
      );
    }
  }

  Future<void> _refreshThumbnail() async {
    _latestThumbnail =
        await _photoRepository.lastThumbnailFileFromSorted(_photos);
  }

  void _refreshVaultHistory() {
    _vaultHistory = _vaultHistoryRepository.readRecent();
  }

  Future<void> _syncNotificationsForCurrentPhotos() async {
    await _notificationService.syncExpiryNotifications(
      _photos,
      enabled: _settings.notificationsEnabled,
      stealthMode: _settings.stealthNotificationsEnabled,
      locale: activeLocale,
    );
  }

  Future<void> _resyncNotificationsSilently() async {
    try {
      await _syncNotificationsForCurrentPhotos();
    } catch (_) {}
  }

  void setTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
    unawaited(_syncLiveScanState());
  }

  void openCameraQuickAction() {
    _currentTabIndex = 1;
    notifyListeners();
    unawaited(_syncLiveScanState());
  }

  void openVaultQuickAction() {
    _currentTabIndex = 0;
    notifyListeners();
    unawaited(_syncLiveScanState());
  }

  Future<void> captureWithTimerFlow(BuildContext context) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }
    XFile? file;
    try {
      _isCapturing = true;
      await _syncLiveScanState();
      notifyListeners();
      await _waitForFocusToSettleIfNeeded();
      file = await controller.takePicture();
      _isCapturing = false;
      notifyListeners();
      if (!context.mounted) {
        return;
      }
      if (!hasPremiumAccess) {
        final unlocked = await promptForPremiumAccess(context);
        if (!context.mounted) {
          await _discardTransientFile(file.path);
          return;
        }
        if (!unlocked) {
          await _discardTransientFile(file.path);
          return;
        }
      }
      final scanResult = await _documentScanService.scanPhoto(file.path);
      if (!context.mounted) {
        await _discardTransientFile(file.path);
        return;
      }
      if (scanResult.hasData) {
        final continueSaving = await _showDetectedDocumentActions(
          context,
          scanResult,
        );
        if (!context.mounted) {
          await _discardTransientFile(file.path);
          return;
        }
        if (!continueSaving) {
          await _discardTransientFile(file.path);
          return;
        }
      }
      if (!context.mounted) {
        await _discardTransientFile(file.path);
        return;
      }
      final selected = await TimerSelectionSheet.show(
        context,
        settings.defaultTimer,
        hasPremiumAccess: hasPremiumAccess,
        previewFilePath: file.path,
        previewMediaType: MediaType.photo,
      );
      if (!context.mounted) {
        return;
      }
      final appliedTimer = selected ?? settings.defaultTimer;
      final record = await _photoRepository.createFromCapture(
        sourcePath: file.path,
        timer: appliedTimer,
      );
      await refreshPhotos();
      if (scanResult.hasData) {
        await _persistDetectedDocumentResult(record, scanResult);
      }
      _currentTabIndex = 0;
      notifyListeners();
    } finally {
      if (_isCapturing) {
        _isCapturing = false;
        notifyListeners();
      }
      await _syncLiveScanState();
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

  Future<void> updateQuickLockTimeout(QuickLockTimeoutOption option) async {
    _settings = _settings.copyWith(quickLockTimeout: option);
    await _settingsRepository.save(_settings);
    notifyListeners();
  }

  Future<void> updateStealthNotifications(bool enabled) async {
    _settings = _settings.copyWith(stealthNotificationsEnabled: enabled);
    await _settingsRepository.save(_settings);
    if (_settings.notificationsEnabled) {
      await _syncNotificationsForCurrentPhotos();
    }
    notifyListeners();
  }

  Future<String?> importMediaToVault(BuildContext context) async {
    if (_isCapturing || _isRecordingVideo) {
      return l10n.tr('Finish the current capture before importing media.');
    }
    if (!await promptForPremiumAccess(context)) {
      return null;
    }
    List<_ImportedDeviceMedia> importedItems = const [];
    try {
      importedItems = await _pickImportableMedia();
      if (importedItems.isEmpty) {
        return null;
      }
      if (!context.mounted) {
        await _consumeImportedMedia(importedItems, deleteOriginals: false);
        return null;
      }
      final firstScanResult = importedItems.first.mediaType == MediaType.photo
          ? await _documentScanService.scanPhoto(importedItems.first.tempPath)
          : const DocumentScanResult(phoneNumbers: [], addresses: []);
      if (!context.mounted) {
        await _consumeImportedMedia(importedItems, deleteOriginals: false);
        return null;
      }
      if (firstScanResult.hasData) {
        final continueSaving = await _showDetectedDocumentActions(
          context,
          firstScanResult,
        );
        if (!context.mounted) {
          await _consumeImportedMedia(importedItems, deleteOriginals: false);
          return null;
        }
        if (!continueSaving) {
          await _consumeImportedMedia(importedItems, deleteOriginals: false);
          return null;
        }
      }
      if (!context.mounted) {
        await _consumeImportedMedia(importedItems, deleteOriginals: false);
        return null;
      }
      final selected = await TimerSelectionSheet.show(
        context,
        settings.defaultTimer,
        hasPremiumAccess: hasPremiumAccess,
        previewFilePath: importedItems.first.tempPath,
        previewMediaType: importedItems.first.mediaType,
      );
      if (!context.mounted) {
        await _consumeImportedMedia(importedItems, deleteOriginals: false);
        return null;
      }
      final timer = selected ?? settings.defaultTimer;
      final importedRecords = await _photoRepository.importFromDevice(
        sourcePaths:
            importedItems.map((item) => item.tempPath).toList(growable: false),
        mediaTypes:
            importedItems.map((item) => item.mediaType).toList(growable: false),
        timer: timer,
      );
      final failedOriginalDeletions =
          await _consumeImportedMedia(importedItems, deleteOriginals: true);
      await refreshPhotos();
      if (firstScanResult.hasData && importedRecords.isNotEmpty) {
        await _persistDetectedDocumentResult(
            importedRecords.first, firstScanResult);
        await _analyzePhotoRecords(
            importedRecords.skip(1).toList(growable: false));
      } else {
        await _analyzePhotoRecords(importedRecords);
      }
      _currentTabIndex = 0;
      notifyListeners();
      final count = importedItems.length;
      if (failedOriginalDeletions > 0) {
        return l10n.tr(
          '{count} items imported into TempCam, but {failed} original items could not be removed from the main gallery.',
          {
            'count': '$count',
            'failed': '$failedOriginalDeletions',
          },
        );
      }
      return l10n.tr(
        '{count} items moved into TempCam and removed from the main gallery.',
        {'count': '$count'},
      );
    } catch (_) {
      await _consumeImportedMedia(importedItems, deleteOriginals: false);
      return l10n.tr('Unable to import media right now.');
    }
  }

  Future<List<_ImportedDeviceMedia>> _pickImportableMedia() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      final pickedFiles = await _mediaPicker.pickMultipleMedia(
        requestFullMetadata: false,
      );
      return pickedFiles
          .map(
            (file) => _ImportedDeviceMedia(
              tempPath: file.path,
              mediaType: _mediaTypeFromPath(file.path),
            ),
          )
          .toList(growable: false);
    }
    final rawItems = await _mediaGalleryChannel
        .invokeMethod<List<dynamic>>('pickImportableMedia');
    if (rawItems == null || rawItems.isEmpty) {
      return const [];
    }
    return rawItems
        .map(_ImportedDeviceMedia.fromMap)
        .whereType<_ImportedDeviceMedia>()
        .toList(growable: false);
  }

  Future<int> _consumeImportedMedia(
    List<_ImportedDeviceMedia> items, {
    required bool deleteOriginals,
  }) async {
    if (items.isEmpty) {
      return 0;
    }
    if (!Platform.isAndroid && !Platform.isIOS) {
      return 0;
    }
    final response =
        await _mediaGalleryChannel.invokeMethod<Map<dynamic, dynamic>>(
      'consumeImportedMedia',
      <String, dynamic>{
        'deleteOriginals': deleteOriginals,
        'items':
            items.map((item) => item.toChannelMap()).toList(growable: false),
      },
    );
    final failed = response?['failedOriginalDeletes'];
    if (failed is int) {
      return failed;
    }
    if (failed is num) {
      return failed.toInt();
    }
    return 0;
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

  Future<void> updateSessionPrivacyMode(bool enabled) async {
    _settings = _settings.copyWith(sessionPrivacyModeEnabled: enabled);
    await _settingsRepository.save(_settings);
    notifyListeners();
  }

  Future<void> _discardTransientFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
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

  Future<void> panicExit() async {
    _pausedAt = DateTime.now();
    _currentTabIndex = 1;
    _isLocked = hasPremiumAccess &&
        _settings.biometricLockEnabled &&
        _biometricAvailable;
    notifyListeners();
    await SystemNavigator.pop();
  }

  Future<void> deletePhoto(PhotoRecord record) async {
    await _photoRepository.deleteNow(record);
    await _recordVaultHistory(
      eventType: VaultHistoryEventType.deleted,
      title:
          l10n.tr(record.isVideo ? 'Video deleted now' : 'Photo deleted now'),
      details: l10n.tr(
        '{media} removed manually before its timer ended.',
        {'media': l10n.tr(record.isVideo ? 'Video' : 'Photo')},
      ),
    );
    await refreshPhotos();
  }

  Future<void> deletePhotos(Iterable<PhotoRecord> records) async {
    final items = records.toList(growable: false);
    if (items.isEmpty) {
      return;
    }
    await _photoRepository.deleteMany(items);
    for (final record in items) {
      await _recordVaultHistory(
        eventType: VaultHistoryEventType.deleted,
        title:
            l10n.tr(record.isVideo ? 'Video deleted now' : 'Photo deleted now'),
        details: l10n.tr(
          '{media} removed manually before its timer ended.',
          {'media': l10n.tr(record.isVideo ? 'Video' : 'Photo')},
        ),
      );
    }
    await refreshPhotos();
  }

  Future<String?> keepPhotoForever(PhotoRecord record) async {
    final exportedPath = await _exportMediaToMainGallery(record);
    if (exportedPath == null) {
      return l10n.tr('Unable to export this item to the main gallery.');
    }
    await _photoRepository.keepForever(record);
    await _recordVaultHistory(
      eventType: VaultHistoryEventType.exported,
      title:
          l10n.tr(record.isVideo ? 'Video kept forever' : 'Photo kept forever'),
      details: l10n.tr(
        '{media} exported to the main gallery and removed from TempCam expiry.',
        {'media': l10n.tr(record.isVideo ? 'Video' : 'Photo')},
      ),
    );
    await refreshPhotos();
    return record.isVideo
        ? l10n.tr('Video kept forever and exported.')
        : l10n.tr('Photo kept forever and exported.');
  }

  Future<void> extendPhoto(PhotoRecord record, AppTimerOption timer) async {
    await _photoRepository.extend(record, timer);
    await refreshPhotos();
  }

  Future<String?> sharePhoto(PhotoRecord record, {Rect? origin}) async {
    final file = File(record.filePath);
    if (!await file.exists()) {
      return l10n.tr('Media no longer exists.');
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              record.filePath,
              mimeType: _mimeTypeForMedia(record),
              name: p.basename(record.filePath),
            ),
          ],
          title: l10n.tr(record.isVideo ? 'Share video' : 'Share photo'),
          sharePositionOrigin: origin,
        ),
      );
      return null;
    } catch (_) {
      return l10n.tr('Unable to share this item right now.');
    }
  }

  Future<String?> contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@bizclicq.com',
      queryParameters: {
        'subject': 'TempCam Support',
      },
    );
    final launched = await _systemActionService.openExternalUrl(uri.toString());
    if (launched) {
      return null;
    }
    return l10n.tr('Unable to open your mail app right now.');
  }

  Future<String?> shareApp({Rect? origin}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'TempCam',
          text:
              'Try TempCam for private temporary photos and videos: https://play.google.com/store/apps/details?id=com.tempcam',
          sharePositionOrigin: origin,
        ),
      );
      return null;
    } catch (_) {
      return l10n.tr('Unable to share TempCam right now.');
    }
  }

  Future<void> ensurePhotoSmartScan(String photoId) async {
    final photo = byId(photoId);
    if (photo == null || photo.isVideo || photo.hasCompletedSmartScan) {
      return;
    }
    await _analyzePhotoRecord(photo);
  }

  String? consumePendingSmartScanPhotoId() {
    final value = _pendingSmartScanPhotoId;
    _pendingSmartScanPhotoId = null;
    return value;
  }

  Future<String?> callDetectedPhoneNumber(String phoneNumber) async {
    final sanitized = phoneNumber.trim();
    if (sanitized.isEmpty) {
      return l10n.tr('Unable to open the phone dialer right now.');
    }
    final launched = await _systemActionService.openExternalUrl(
      'tel:${Uri.encodeComponent(sanitized)}',
    );
    if (launched) {
      return null;
    }
    return l10n.tr('Unable to open the phone dialer right now.');
  }

  Future<String?> callLiveScanPhoneNumber(String phoneNumber) async {
    snoozeLiveScan();
    return callDetectedPhoneNumber(phoneNumber);
  }

  Future<String?> addDetectedPhoneNumberToContacts(String phoneNumber) async {
    final sanitized = phoneNumber.trim();
    if (sanitized.isEmpty) {
      return l10n.tr('Unable to open the contacts app right now.');
    }
    final opened = await _systemActionService.openAddContact(
      phoneNumber: sanitized,
      displayName: l10n.tr('TempCam Contact'),
    );
    if (opened) {
      return null;
    }
    return l10n.tr('Unable to open the contacts app right now.');
  }

  Future<String?> addLiveScanPhoneNumberToContacts(String phoneNumber) async {
    snoozeLiveScan();
    return addDetectedPhoneNumberToContacts(phoneNumber);
  }

  Future<String?> openDetectedAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      return l10n.tr('Unable to open the map right now.');
    }
    final geoLaunched = await _systemActionService.openExternalUrl(
      'geo:0,0?q=${Uri.encodeComponent(trimmed)}',
    );
    if (geoLaunched) {
      return null;
    }
    final webLaunched = await _systemActionService.openExternalUrl(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(trimmed)}',
    );
    if (webLaunched) {
      return null;
    }
    return l10n.tr('Unable to open the map right now.');
  }

  Future<String?> openLiveScanAddress(String address) async {
    snoozeLiveScan();
    return openDetectedAddress(address);
  }

  void snoozeLiveScan() {
    _liveScanCooldownUntil = DateTime.now().add(_liveScanCooldownDuration);
    _recentLiveScanResults.clear();
    _setLiveScanResult(const LiveScanResult());
  }

  PhotoRecord? byId(String id) {
    try {
      return _photos.firstWhere((photo) => photo.id == id);
    } catch (_) {
      return _photoRepository.readById(id);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isAuthenticatingWithBiometrics) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      _isPreviewShieldActive = true;
      unawaited(_stopLiveScanStream());
      if (_settings.sessionPrivacyModeEnabled &&
          hasPremiumAccess &&
          _settings.biometricLockEnabled &&
          _biometricAvailable) {
        _isLocked = true;
        notifyListeners();
      }
    }
    if (state == AppLifecycleState.resumed) {
      _isPreviewShieldActive = false;
      if (_ignoreNextResumeLock) {
        _ignoreNextResumeLock = false;
        notifyListeners();
        return;
      }
      unawaited(_handleResume());
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_settings.localeTag == null) {
      unawaited(_resyncNotificationsSilently());
      notifyListeners();
    }
  }

  Future<void> _handleResume() async {
    await refreshPhotos();
    await _refreshStoreEntitlementStatus();
    await _normalizePremiumState();
    if (!hasPremiumAccess) {
      _isLocked = false;
      notifyListeners();
      await _syncLiveScanState();
      return;
    }
    if (!_settings.biometricLockEnabled || !_biometricAvailable) {
      notifyListeners();
      await _syncLiveScanState();
      return;
    }
    if (_settings.sessionPrivacyModeEnabled) {
      _isLocked = true;
      notifyListeners();
      await _syncLiveScanState();
      return;
    }
    final pausedAt = _pausedAt;
    if (pausedAt == null) {
      _isLocked = true;
    } else if (DateTime.now().difference(pausedAt) >=
        _settings.quickLockTimeout.duration) {
      _isLocked = true;
    }
    notifyListeners();
    await _syncLiveScanState();
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
    _liveScanResultHoldTimer?.cancel();
    _billingSubscription.cancel();
    unawaited(_billingService.dispose());
    super.dispose();
  }

  Future<void> _recordVaultHistory({
    required VaultHistoryEventType eventType,
    required String title,
    required String details,
  }) async {
    await _vaultHistoryRepository.add(
      eventType: eventType,
      title: title,
      details: details,
    );
  }

  Future<bool> _showDetectedDocumentActions(
    BuildContext context,
    DocumentScanResult result,
  ) async {
    return DocumentActionSheet.show(
      context,
      result: result,
      onCallPhone: (phoneNumber) async {
        final message = await callDetectedPhoneNumber(phoneNumber);
        if (!context.mounted || message == null) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      onAddToContacts: (phoneNumber) async {
        final message = await addDetectedPhoneNumberToContacts(phoneNumber);
        if (!context.mounted || message == null) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      onOpenAddress: (address) async {
        final message = await openDetectedAddress(address);
        if (!context.mounted || message == null) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  Future<void> _persistDetectedDocumentResult(
    PhotoRecord record,
    DocumentScanResult result,
  ) async {
    final updated = await _photoRepository.saveSmartScanResults(
      id: record.id,
      detectedPhoneNumbers: result.phoneNumbers,
      detectedAddresses: result.addresses,
    );
    if (updated == null) {
      return;
    }
    _replacePhotoInMemory(updated);
  }

  bool get _shouldEnableLiveScan {
    final controller = _cameraController;
    return controller != null &&
        controller.value.isInitialized &&
        !_isVideoMode &&
        !_isCapturing &&
        !_isRecordingVideo &&
        !_isSwitchingCamera &&
        _currentTabIndex == 1 &&
        controller.description.lensDirection == CameraLensDirection.back &&
        (Platform.isAndroid || Platform.isIOS);
  }

  Future<void> _syncLiveScanState() async {
    if (_shouldEnableLiveScan) {
      await _startLiveScanStream();
      return;
    }
    await _stopLiveScanStream();
  }

  Future<void> _startLiveScanStream() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isLiveScanStreaming ||
        controller.value.isStreamingImages) {
      return;
    }
    try {
      await controller.startImageStream(_handleLiveCameraImage);
      _isLiveScanStreaming = true;
    } catch (_) {
      _isLiveScanStreaming = false;
    }
  }

  Future<void> _stopLiveScanStream() async {
    final controller = _cameraController;
    _liveScanResultHoldTimer?.cancel();
    _isLiveScanProcessing = false;
    _recentLiveScanResults.clear();
    if (controller == null || !_isLiveScanStreaming) {
      _setLiveScanResult(const LiveScanResult());
      return;
    }
    try {
      await controller.stopImageStream();
    } catch (_) {}
    _isLiveScanStreaming = false;
    _setLiveScanResult(const LiveScanResult());
  }

  Future<void> _handleLiveCameraImage(CameraImage image) async {
    if (!_shouldEnableLiveScan || _isLiveScanProcessing) {
      return;
    }
    final cooldownUntil = _liveScanCooldownUntil;
    if (cooldownUntil != null && DateTime.now().isBefore(cooldownUntil)) {
      return;
    }
    final lastProcessedAt = _lastLiveScanProcessedAt;
    if (lastProcessedAt != null &&
        DateTime.now().difference(lastProcessedAt) < _liveScanMinInterval) {
      return;
    }

    final controller = _cameraController;
    if (controller == null) {
      return;
    }
    final inputImage = _inputImageFromCameraImage(
      image,
      controller: controller,
    );
    if (inputImage == null) {
      return;
    }

    _isLiveScanProcessing = true;
    _lastLiveScanProcessedAt = DateTime.now();
    try {
      final result = await _documentScanService.scanInputImage(inputImage);
      if (!_shouldEnableLiveScan) {
        return;
      }
      _recordLiveScanResult(
        LiveScanResult(
          phoneNumber:
              result.phoneNumbers.isEmpty ? null : result.phoneNumbers.first,
          address: result.addresses.isEmpty ? null : result.addresses.first,
        ),
      );
    } catch (_) {
    } finally {
      _isLiveScanProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image, {
    required CameraController controller,
  }) {
    final camera = controller.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      const orientations = <DeviceOrientation, int>{
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      };
      var rotationCompensation =
          orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) {
        return null;
      }
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) {
      return null;
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888) ||
        image.planes.length != 1) {
      return null;
    }

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _recordLiveScanResult(LiveScanResult next) {
    _recentLiveScanResults.add(next);
    if (_recentLiveScanResults.length > 4) {
      _recentLiveScanResults.removeAt(0);
    }
    final stable = _stableLiveScanResult();
    _setLiveScanResult(stable);
  }

  LiveScanResult _stableLiveScanResult() {
    final phoneCounts = <String, int>{};
    final addressCounts = <String, int>{};
    final phonesByKey = <String, String>{};
    final addressesByKey = <String, String>{};

    for (final result in _recentLiveScanResults) {
      final phone = result.phoneNumber;
      if (phone != null && phone.isNotEmpty) {
        final key = _normalizeLiveCandidate(phone);
        phoneCounts[key] = (phoneCounts[key] ?? 0) + 1;
        phonesByKey[key] = phone;
      }
      final address = result.address;
      if (address != null && address.isNotEmpty) {
        final key = _normalizeLiveCandidate(address);
        addressCounts[key] = (addressCounts[key] ?? 0) + 1;
        addressesByKey[key] = address;
      }
    }

    final phoneKey = _bestStableKey(phoneCounts, 2);
    final addressKey = _bestStableKey(addressCounts, 3);
    return LiveScanResult(
      phoneNumber: phoneKey == null ? null : phonesByKey[phoneKey],
      address: addressKey == null ? null : addressesByKey[addressKey],
    );
  }

  String? _bestStableKey(Map<String, int> counts, int requiredCount) {
    String? bestKey;
    var bestCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        bestKey = entry.key;
        bestCount = entry.value;
      }
    }
    if (bestCount < requiredCount) {
      return null;
    }
    return bestKey;
  }

  String _normalizeLiveCandidate(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9+]+'), ' ').trim();
  }

  String _mimeTypeForMedia(PhotoRecord record) {
    final extension = p.extension(record.filePath).toLowerCase();
    if (record.isVideo) {
      return switch (extension) {
        '.mov' => 'video/quicktime',
        '.m4v' => 'video/x-m4v',
        '.webm' => 'video/webm',
        '.3gp' => 'video/3gpp',
        _ => 'video/mp4',
      };
    }
    return switch (extension) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.heic' => 'image/heic',
      '.heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  void _setLiveScanResult(LiveScanResult next) {
    if (_liveScanResult.isSameAs(next)) {
      if (next.hasData) {
        _liveScanResultHoldTimer?.cancel();
        _liveScanResultHoldTimer = Timer(_liveScanResultHoldDuration, () {
          _setLiveScanResult(const LiveScanResult());
        });
      }
      return;
    }
    _liveScanResult = next;
    _liveScanResultHoldTimer?.cancel();
    if (next.hasData) {
      _liveScanResultHoldTimer = Timer(_liveScanResultHoldDuration, () {
        _setLiveScanResult(const LiveScanResult());
      });
    }
    notifyListeners();
  }

  Future<void> _analyzePhotoRecord(
    PhotoRecord record, {
    bool markPendingWhenDetected = false,
  }) async {
    if (record.isVideo || record.hasCompletedSmartScan) {
      return;
    }

    final result = await _documentScanService.scanPhoto(record.filePath);
    final updated = await _photoRepository.saveSmartScanResults(
      id: record.id,
      detectedPhoneNumbers: result.phoneNumbers,
      detectedAddresses: result.addresses,
    );
    if (updated == null) {
      return;
    }
    if (markPendingWhenDetected && updated.hasDetectedDetails) {
      _pendingSmartScanPhotoId = updated.id;
    }
    _replacePhotoInMemory(updated);
  }

  Future<void> _analyzePhotoRecords(
    List<PhotoRecord> records, {
    bool markPendingWhenDetected = false,
  }) async {
    for (final record in records) {
      await _analyzePhotoRecord(
        record,
        markPendingWhenDetected: markPendingWhenDetected,
      );
    }
  }

  void _replacePhotoInMemory(PhotoRecord updated) {
    final index = _photos.indexWhere((item) => item.id == updated.id);
    if (index < 0) {
      return;
    }
    _photos = List<PhotoRecord>.from(_photos)..[index] = updated;
    notifyListeners();
  }

  MediaType _mediaTypeFromPath(String path) {
    final normalized = path.toLowerCase();
    if (normalized.endsWith('.mp4') ||
        normalized.endsWith('.mov') ||
        normalized.endsWith('.m4v') ||
        normalized.endsWith('.avi') ||
        normalized.endsWith('.mkv') ||
        normalized.endsWith('.webm') ||
        normalized.endsWith('.3gp')) {
      return MediaType.video;
    }
    return MediaType.photo;
  }
}
