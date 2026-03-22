import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

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
  BillingService({InAppPurchase? inAppPurchase}) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance {
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object error, StackTrace stackTrace) {
        _eventsController.add(BillingEvent(status: BillingEventStatus.error, message: error.toString()));
      },
    );
  }

  final InAppPurchase _inAppPurchase;
  final StreamController<BillingEvent> _eventsController = StreamController<BillingEvent>.broadcast();

  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  ProductDetails? _yearlyProduct;
  bool _isStoreAvailable = false;

  Stream<BillingEvent> get events => _eventsController.stream;
  ProductDetails? get yearlyProduct => _yearlyProduct;
  bool get isStoreAvailable => _isStoreAvailable;

  Future<bool> initialize() async {
    _isStoreAvailable = await _inAppPurchase.isAvailable();
    if (_isStoreAvailable) {
      await refreshCatalog();
    }
    return _isStoreAvailable;
  }

  Future<ProductDetails?> refreshCatalog() async {
    final response = await _inAppPurchase.queryProductDetails({PremiumConstants.yearlySubscriptionProductId});
    if (response.error != null) {
      throw Exception(response.error!.message);
    }
    final matches = response.productDetails.where((product) => product.id == PremiumConstants.yearlySubscriptionProductId).toList();
    _yearlyProduct = matches.isEmpty ? null : matches.first;
    return _yearlyProduct;
  }

  Future<bool> buyYearlySubscription() async {
    final product = _yearlyProduct ?? await refreshCatalog();
    if (product == null) {
      return false;
    }
    final purchaseParam = PurchaseParam(productDetails: product);
    return _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() {
    return _inAppPurchase.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        _eventsController.add(BillingEvent(status: BillingEventStatus.pending, purchase: purchase));
      } else if (purchase.status == PurchaseStatus.error) {
        _eventsController.add(
          BillingEvent(
            status: BillingEventStatus.error,
            purchase: purchase,
            message: purchase.error?.message ?? 'The purchase could not be completed.',
          ),
        );
      } else if (purchase.status == PurchaseStatus.purchased) {
        _eventsController.add(BillingEvent(status: BillingEventStatus.purchased, purchase: purchase));
      } else if (purchase.status == PurchaseStatus.restored) {
        _eventsController.add(BillingEvent(status: BillingEventStatus.restored, purchase: purchase));
      } else if (purchase.status == PurchaseStatus.canceled) {
        _eventsController.add(BillingEvent(status: BillingEventStatus.canceled, purchase: purchase, message: 'Purchase canceled.'));
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
