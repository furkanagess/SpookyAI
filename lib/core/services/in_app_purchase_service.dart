import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'token_service.dart';
import 'premium_service.dart';

class InAppPurchaseService {
  InAppPurchaseService._();

  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static final List<ProductDetails> _products = [];
  // static final List<PurchaseDetails> _purchases = [];

  // App Store Product IDs matching your configuration
  static const Map<String, int> _productTokenMap = {
    '1_token': 1,
    '10_token': 10,
    '25_token': 25,
    '60_token': 60,
    '150_token': 150,
  };

  static const Set<String> _productIds = {
    '1_token',
    '10_token',
    '25_token',
    '60_token',
    '150_token',
  };

  static bool _isAvailable = false;
  static bool _purchasePending = false;
  static String? _queryProductError;
  // static String? _lastPurchaseProductId;
  static bool _lastPurchaseSuccess = false;

  static bool get isAvailable => _isAvailable;
  static bool get purchasePending => _purchasePending;
  static String? get queryProductError => _queryProductError;
  static List<ProductDetails> get products => _products;

  static Future<void> initialize() async {
    _isAvailable = await _inAppPurchase.isAvailable();

    if (!_isAvailable) {
      debugPrint('In-app purchase not available');
      return;
    }

    // Initialize platform-specific settings
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _initializeAndroid();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _initializeIOS();
    }

    // Listen to purchase updates
    _inAppPurchase.purchaseStream.listen(_handlePurchaseUpdate);

    // Load products
    await _loadProducts();
  }

  static Future<void> _initializeAndroid() async {
    // Android initialization is handled automatically by the plugin
    // No additional setup required for current version
  }

  static Future<void> _initializeIOS() async {
    final InAppPurchaseStoreKitPlatformAddition iosAddition = _inAppPurchase
        .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();

    await iosAddition.setDelegate(ExamplePaymentQueueDelegate());
  }

  static Future<void> _loadProducts() async {
    if (!_isAvailable) return;

    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      _products.clear();
      _products.addAll(response.productDetails);
      _queryProductError = null;

      debugPrint('Loaded ${_products.length} products');
    } catch (e) {
      _queryProductError = e.toString();
      debugPrint('Error loading products: $e');
    }
  }

  static Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable || _purchasePending) return false;

    final ProductDetails? product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found'),
    );

    if (product == null) {
      debugPrint('Product $productId not found');
      return false;
    }

    _purchasePending = true;
    _lastPurchaseSuccess = false;

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      final bool isPremium = productId == 'spookyai_premium';
      final bool success = isPremium
          ? await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam)
          : await _inAppPurchase.buyConsumable(
              purchaseParam: purchaseParam,
              autoConsume: true,
            );

      if (!success) {
        _purchasePending = false;
        debugPrint('Purchase failed to initiate');
        return false;
      }

      // Wait for purchase completion
      return await _waitForPurchaseCompletion();
    } catch (e) {
      _purchasePending = false;
      debugPrint('Error initiating purchase: $e');
      return false;
    }
  }

  static Future<bool> _waitForPurchaseCompletion() async {
    // Wait for purchase to complete (max 30 seconds)
    int attempts = 0;
    const int maxAttempts = 30; // 30 seconds max wait

    while (_purchasePending && attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 1));
      attempts++;
    }

    return _lastPurchaseSuccess;
  }

  static Future<void> _handlePurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
  }

  static Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      // Grant tokens based on product ID
      final int? tokens = _productTokenMap[purchaseDetails.productID];
      if (tokens != null) {
        await TokenService.addTokens(tokens);
        debugPrint(
          'Added $tokens tokens for purchase ${purchaseDetails.productID}',
        );
      } else if (purchaseDetails.productID == 'spookyai_premium') {
        // Premium subscription purchase
        await PremiumService.activatePremiumSubscription();
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }

      // Mark purchase as successful
      _lastPurchaseSuccess = true;
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      debugPrint('Purchase error: ${purchaseDetails.error}');
      _lastPurchaseSuccess = false;
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      debugPrint('Purchase canceled');
      _lastPurchaseSuccess = false;
    }

    _purchasePending = false;
  }

  static Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('Purchases restored');
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    }
  }

  static ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  static int? getTokensForProduct(String productId) {
    return _productTokenMap[productId];
  }
}

// iOS StoreKit delegate
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
