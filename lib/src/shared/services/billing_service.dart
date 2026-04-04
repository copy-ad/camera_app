import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../core/constants/premium_constants.dart';

enum BillingEventStatus {
  pending,
  purchased,
  restored,
  canceled,
  error,
}

class BillingEvent {
  const BillingEvent({
    required this.status,
    this.purchase,
    this.message,
  });

  final BillingEventStatus status;
  final PurchaseDetails? purchase;
  final String? message;
}

class BillingService {
  BillingService({InAppPurchase? inAppPurchase})
      : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance {
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object error, StackTrace stackTrace) {
        _eventsController.add(
          BillingEvent(
            status: BillingEventStatus.error,
            message: error.toString(),
          ),
        );
      },
    );
  }

  final InAppPurchase _inAppPurchase;
  final StreamController<BillingEvent> _eventsController =
      StreamController<BillingEvent>.broadcast();

  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  ProductDetails? _yearlyProduct;
  bool _isStoreAvailable = false;

  Stream<BillingEvent> get events => _eventsController.stream;
  ProductDetails? get yearlyProduct => _yearlyProduct;
  bool get isStoreAvailable => _isStoreAvailable;

  bool get hasStoreManagedTrialOffer {
    final product = _yearlyProduct;
    if (product is! GooglePlayProductDetails) {
      return false;
    }
    final subscriptionIndex = product.subscriptionIndex;
    if (subscriptionIndex == null) {
      return false;
    }
    final offers = product.productDetails.subscriptionOfferDetails;
    if (offers == null || subscriptionIndex >= offers.length) {
      return false;
    }
    final offer = offers[subscriptionIndex];
    if (offer.basePlanId != PremiumConstants.yearlyBasePlanId ||
        offer.offerId != PremiumConstants.yearlyTrialOfferId) {
      return false;
    }
    final pricingPhases = offer.pricingPhases;
    return pricingPhases.isNotEmpty &&
        pricingPhases.first.priceAmountMicros == 0;
  }

  Future<bool> initialize() async {
    _isStoreAvailable = await _inAppPurchase.isAvailable();
    if (_isStoreAvailable) {
      await refreshCatalog();
    }
    return _isStoreAvailable;
  }

  Future<ProductDetails?> refreshCatalog() async {
    final response = await _inAppPurchase.queryProductDetails({
      PremiumConstants.yearlySubscriptionProductId,
    });
    if (response.error != null) {
      throw Exception(response.error!.message);
    }
    final matches = response.productDetails
        .where(
          (product) =>
              product.id == PremiumConstants.yearlySubscriptionProductId,
        )
        .toList();
    _yearlyProduct = _selectPreferredProduct(matches);
    return _yearlyProduct;
  }

  ProductDetails? _selectPreferredProduct(List<ProductDetails> matches) {
    if (matches.isEmpty) {
      return null;
    }
    if (!Platform.isAndroid) {
      return matches.first;
    }
    for (final product in matches) {
      if (product is! GooglePlayProductDetails) {
        continue;
      }
      final subscriptionIndex = product.subscriptionIndex;
      final offers = product.productDetails.subscriptionOfferDetails;
      if (subscriptionIndex == null || offers == null) {
        continue;
      }
      final offer = offers[subscriptionIndex];
      final pricingPhases = offer.pricingPhases;
      if (offer.basePlanId == PremiumConstants.yearlyBasePlanId &&
          offer.offerId == PremiumConstants.yearlyTrialOfferId &&
          pricingPhases.isNotEmpty &&
          pricingPhases.first.priceAmountMicros == 0) {
        return product;
      }
    }
    for (final product in matches) {
      if (product is! GooglePlayProductDetails) {
        continue;
      }
      final subscriptionIndex = product.subscriptionIndex;
      final offers = product.productDetails.subscriptionOfferDetails;
      if (subscriptionIndex == null || offers == null) {
        continue;
      }
      final offer = offers[subscriptionIndex];
      if (offer.basePlanId == PremiumConstants.yearlyBasePlanId &&
          offer.offerId == null) {
        return product;
      }
    }
    return matches.first;
  }

  Future<bool> buyYearlySubscription() async {
    final product = _yearlyProduct ?? await refreshCatalog();
    if (product == null) {
      return false;
    }
    final PurchaseParam purchaseParam;
    if (Platform.isAndroid && product is GooglePlayProductDetails) {
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
        offerToken: product.offerToken,
      );
    } else {
      purchaseParam = PurchaseParam(productDetails: product);
    }
    return _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() {
    return _inAppPurchase.restorePurchases();
  }

  Future<List<PurchaseDetails>> queryActivePurchases() async {
    if (!_isStoreAvailable) {
      return const <PurchaseDetails>[];
    }
    if (!Platform.isAndroid) {
      return const <PurchaseDetails>[];
    }
    final platformAddition = _inAppPurchase
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await platformAddition.queryPastPurchases();
    if (response.error != null) {
      throw Exception(response.error!.message);
    }
    return response.pastPurchases
        .where(
          (purchase) =>
              purchase.productID ==
              PremiumConstants.yearlySubscriptionProductId,
        )
        .cast<PurchaseDetails>()
        .toList(growable: false);
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        _eventsController.add(
          BillingEvent(status: BillingEventStatus.pending, purchase: purchase),
        );
      } else if (purchase.status == PurchaseStatus.error) {
        _eventsController.add(
          BillingEvent(
            status: BillingEventStatus.error,
            purchase: purchase,
            message: purchase.error?.message ??
                'The purchase could not be completed.',
          ),
        );
      } else if (purchase.status == PurchaseStatus.purchased) {
        _eventsController.add(
          BillingEvent(
              status: BillingEventStatus.purchased, purchase: purchase),
        );
      } else if (purchase.status == PurchaseStatus.restored) {
        _eventsController.add(
          BillingEvent(status: BillingEventStatus.restored, purchase: purchase),
        );
      } else if (purchase.status == PurchaseStatus.canceled) {
        _eventsController.add(
          BillingEvent(
            status: BillingEventStatus.canceled,
            purchase: purchase,
            message: 'Purchase canceled.',
          ),
        );
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<void> dispose() async {
    await _purchaseSubscription.cancel();
    await _eventsController.close();
  }
}
