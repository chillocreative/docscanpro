import 'dart:async';

import 'package:doc_scan_ar/core/constants/app_constants.dart';
import 'package:doc_scan_ar/core/services/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _log = Logger('IapService');
const _entitlementKey = 'docscan.entitlement.removeAds';

/// Tri-state for the "Remove Ads" entitlement.
enum AdEntitlement {
  /// We haven't checked yet (cold boot before the IAP stream resolves).
  unknown,

  /// Active, not-yet-expired subscription. Hide ads everywhere.
  active,

  /// No active subscription. Show ads (subject to free limits).
  inactive,
}

@immutable
class IapState {
  const IapState({
    required this.entitlement,
    required this.products,
    required this.isPurchasePending,
  });

  factory IapState.initial() => const IapState(
        entitlement: AdEntitlement.unknown,
        products: [],
        isPurchasePending: false,
      );

  final AdEntitlement entitlement;
  final List<ProductDetails> products;
  final bool isPurchasePending;

  IapState copyWith({
    AdEntitlement? entitlement,
    List<ProductDetails>? products,
    bool? isPurchasePending,
  }) =>
      IapState(
        entitlement: entitlement ?? this.entitlement,
        products: products ?? this.products,
        isPurchasePending: isPurchasePending ?? this.isPurchasePending,
      );
}

/// Subscribes to the IAP purchase stream, fetches the `remove_ads_monthly`
/// product, and persists the resulting entitlement so we can re-verify on
/// every app start.
class IapController extends Notifier<IapState> {
  StreamSubscription<List<PurchaseDetails>>? _sub;
  SharedPreferences? _prefs;

  @override
  IapState build() {
    Future.microtask(_init);
    ref.onDispose(() => _sub?.cancel());
    return IapState.initial();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    // Honor cached entitlement immediately so the UI hides ads before the
    // store responds.
    state = state.copyWith(
      entitlement: (_prefs!.getBool(_entitlementKey) ?? false)
          ? AdEntitlement.active
          : AdEntitlement.inactive,
    );

    final iap = InAppPurchase.instance;
    final available = await iap.isAvailable();
    if (!available) {
      _log.w('Play Billing unavailable on this device — staying $state');
      return;
    }
    _sub = iap.purchaseStream.listen(
      _onUpdates,
      onError: (Object e, StackTrace st) =>
          _log.e('IAP stream error', e, st),
    );
    await _refreshProducts();
    // Restore so `purchaseStream` re-emits any prior subscription.
    await iap.restorePurchases();
  }

  Future<void> _refreshProducts() async {
    final response = await InAppPurchase.instance.queryProductDetails(
      {AppConstants.premiumLifetimeSku},
    );
    if (response.error != null) {
      _log.w('queryProductDetails: ${response.error}');
    }
    state = state.copyWith(products: response.productDetails);
  }

  Future<void> buyPremium() async {
    final product = state.products.firstWhereOrNull(
      (p) => p.id == AppConstants.premiumLifetimeSku,
    );
    if (product == null) {
      _log.w('Cannot buy: product not loaded yet');
      return;
    }
    state = state.copyWith(isPurchasePending: true);
    final param = PurchaseParam(productDetails: product);
    await InAppPurchase.instance
        .buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    await InAppPurchase.instance.restorePurchases();
  }

  Future<void> _onUpdates(List<PurchaseDetails> purchases) async {
    var nextEntitlement = state.entitlement;
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          nextEntitlement = state.entitlement;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == AppConstants.premiumLifetimeSku) {
            nextEntitlement = AdEntitlement.active;
          }
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          _log.i('Purchase ${purchase.status}: ${purchase.error}');
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
      }
    }
    if (nextEntitlement == AdEntitlement.unknown) {
      nextEntitlement = AdEntitlement.inactive;
    }
    await _prefs?.setBool(
      _entitlementKey,
      nextEntitlement == AdEntitlement.active,
    );
    state = state.copyWith(
      entitlement: nextEntitlement,
      isPurchasePending: false,
    );
  }
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final v in this) {
      if (test(v)) return v;
    }
    return null;
  }
}

final iapControllerProvider =
    NotifierProvider<IapController, IapState>(IapController.new);

/// Convenience flag for ad widgets — true if ads are disabled globally
/// via the `AppConstants.kAdsEnabled` feature flag, or the user's
/// "Remove Ads" entitlement is active.
final adsHiddenProvider = Provider<bool>((ref) {
  if (!AppConstants.kAdsEnabled) return true;
  final s = ref.watch(iapControllerProvider);
  return s.entitlement == AdEntitlement.active;
});
