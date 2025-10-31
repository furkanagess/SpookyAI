import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    'spookyai_premium', // Premium subscription product ID
  };

  static bool _isAvailable = false;
  static bool _purchasePending = false;
  static String? _queryProductError;
  // static String? _lastPurchaseProductId;
  static bool _lastPurchaseSuccess = false;
  static bool _lastPurchaseCancelled = false;
  static final Set<String> _processedTransactions = <String>{};
  static const String _processedTxStorageKey = 'processed_purchases_v1';
  static bool _allowConsumableGrantOnNextRestore = false;

  static bool get isAvailable => _isAvailable;
  static bool get purchasePending => _purchasePending;
  static bool get lastPurchaseSuccess => _lastPurchaseSuccess;
  static bool get lastPurchaseCancelled => _lastPurchaseCancelled;
  static String? get queryProductError => _queryProductError;
  static List<ProductDetails> get products => _products;

  static Future<void> initialize() async {
    debugPrint('InAppPurchaseService: Starting initialization...');

    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      debugPrint('InAppPurchaseService: Billing available: $_isAvailable');

      if (!_isAvailable) {
        debugPrint(
          'InAppPurchaseService: In-app purchase not available on this device',
        );
        return;
      }

      // Initialize platform-specific settings
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _initializeAndroid();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _initializeIOS();
      }

      // Listen to purchase updates
      _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdate,
        onError: (error) {
          debugPrint('InAppPurchaseService: Purchase stream error: $error');
        },
      );

      // Load products with retry logic
      await _loadProductsWithRetry();

      // Warm processed tx cache from disk
      try {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getStringList(_processedTxStorageKey) ?? const [];
        _processedTransactions.addAll(stored);
        debugPrint(
          'InAppPurchaseService: Loaded processed tx count: ${_processedTransactions.length}',
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('InAppPurchaseService: Initialization error: $e');
      _isAvailable = false;
    }
  }

  static Future<void> _initializeAndroid() async {
    debugPrint('InAppPurchaseService: Initializing Android billing...');
    try {
      // Additional Android-specific initialization
      // Check Google Play Services availability
      debugPrint(
        'InAppPurchaseService: Android billing initialized successfully',
      );
    } catch (e) {
      debugPrint(
        'InAppPurchaseService: Error initializing Android billing: $e',
      );
    }
  }

  static Future<void> _initializeIOS() async {
    final InAppPurchaseStoreKitPlatformAddition iosAddition = _inAppPurchase
        .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();

    await iosAddition.setDelegate(ExamplePaymentQueueDelegate());
  }

  static Future<void> _loadProductsWithRetry() async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      debugPrint(
        'InAppPurchaseService: Loading products - Attempt $attempt/$maxRetries',
      );

      final success = await _loadProducts();
      if (success) {
        debugPrint(
          'InAppPurchaseService: Products loaded successfully on attempt $attempt',
        );
        return;
      }

      if (attempt < maxRetries) {
        debugPrint(
          'InAppPurchaseService: Retrying in ${retryDelay.inSeconds} seconds...',
        );
        await Future.delayed(retryDelay);
      }
    }

    debugPrint(
      'InAppPurchaseService: Failed to load products after $maxRetries attempts',
    );
  }

  static Future<bool> _loadProducts() async {
    if (!_isAvailable) {
      debugPrint(
        'InAppPurchaseService: In-app purchase not available, skipping product loading',
      );
      return false;
    }

    try {
      debugPrint('InAppPurchaseService: Querying products: $_productIds');
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_productIds);

      if (response.error != null) {
        debugPrint(
          'InAppPurchaseService: Product query error: ${response.error}',
        );
        debugPrint('InAppPurchaseService: Error code: ${response.error?.code}');
        debugPrint(
          'InAppPurchaseService: Error message: ${response.error?.message}',
        );
        _queryProductError = response.error.toString();
        return false;
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          'InAppPurchaseService: Products not found: ${response.notFoundIDs}',
        );
        _queryProductError =
            'Products not found: ${response.notFoundIDs.join(', ')}';

        // If some products are found, still consider it a partial success
        if (response.productDetails.isNotEmpty) {
          debugPrint(
            'InAppPurchaseService: Some products found, continuing with partial success',
          );
        } else {
          return false;
        }
      }

      _products.clear();
      _products.addAll(response.productDetails);

      if (response.error == null && response.notFoundIDs.isEmpty) {
        _queryProductError = null;
      }

      debugPrint(
        'InAppPurchaseService: Successfully loaded ${_products.length} products',
      );
      for (final product in _products) {
        debugPrint(
          'InAppPurchaseService: Product: ${product.id} - ${product.title} - ${product.price}',
        );
      }

      return _products.isNotEmpty;
    } catch (e) {
      _queryProductError = e.toString();
      debugPrint('InAppPurchaseService: Error loading products: $e');
      return false;
    }
  }

  static Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      debugPrint('InAppPurchaseService: In-app purchase not available');
      return false;
    }

    if (_purchasePending) {
      debugPrint('InAppPurchaseService: Purchase already in progress');
      return false;
    }

    // Find the product
    ProductDetails? product;
    try {
      product = _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      debugPrint(
        'InAppPurchaseService: Product $productId not found in loaded products',
      );
      debugPrint(
        'InAppPurchaseService: Available products: ${_products.map((p) => p.id).join(', ')}',
      );
      return false;
    }

    debugPrint(
      'InAppPurchaseService: Initiating purchase for product: ${product.id} - ${product.title}',
    );
    debugPrint('InAppPurchaseService: Product price: ${product.price}');
    debugPrint(
      'InAppPurchaseService: Product currency: ${product.currencyCode}',
    );

    _purchasePending = true;
    _lastPurchaseSuccess = false;
    _lastPurchaseCancelled = false;

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      final bool isPremium = productId == 'spookyai_premium';
      debugPrint(
        'InAppPurchaseService: Purchase type: ${isPremium ? 'Non-consumable (Premium)' : 'Consumable (Tokens)'}',
      );

      // iOS-specific validation
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('InAppPurchaseService: iOS platform detected');
        debugPrint('InAppPurchaseService: Using iOS-optimized purchase flow');
        // iOS purchases might take longer to complete
        // The system will handle the purchase flow
      }

      final bool success = isPremium
          ? await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam)
          : await _inAppPurchase.buyConsumable(
              purchaseParam: purchaseParam,
              autoConsume: true,
            );

      if (!success) {
        _purchasePending = false;
        debugPrint(
          'InAppPurchaseService: Purchase failed to initiate - buy${isPremium ? 'NonConsumable' : 'Consumable'} returned false',
        );
        return false;
      }

      debugPrint(
        'InAppPurchaseService: Purchase initiated successfully, waiting for completion...',
      );
      // Wait for purchase completion
      return await _waitForPurchaseCompletion();
    } catch (e) {
      _purchasePending = false;
      debugPrint('InAppPurchaseService: Error initiating purchase: $e');
      debugPrint('InAppPurchaseService: Error type: ${e.runtimeType}');
      return false;
    }
  }

  static Future<bool> _waitForPurchaseCompletion() async {
    // Wait for purchase to complete (extended timeout for iOS)
    int attempts = 0;
    // Increased timeout for iOS - purchases can take longer
    const int maxAttempts = 120; // 120 seconds max wait for iOS

    debugPrint('InAppPurchaseService: Waiting for purchase completion...');

    while (_purchasePending && attempts < maxAttempts) {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Check every 500ms
      attempts++;

      if (attempts % 10 == 0) {
        // Log every 5 seconds
        debugPrint(
          'InAppPurchaseService: Still waiting for purchase completion... (${attempts * 500}ms)',
        );
      }
    }

    if (attempts >= maxAttempts) {
      debugPrint(
        'InAppPurchaseService: Purchase completion timeout after ${maxAttempts * 500}ms',
      );
      _purchasePending = false;
      // Don't immediately return false on timeout - check if we have a success status
      debugPrint(
        'InAppPurchaseService: Timeout reached, final success status: $_lastPurchaseSuccess',
      );
    }

    debugPrint(
      'InAppPurchaseService: Purchase completion result: $_lastPurchaseSuccess',
    );
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
    debugPrint(
      'Handling purchase: ${purchaseDetails.productID} - Status: ${purchaseDetails.status}',
    );
    debugPrint('Purchase pending: $_purchasePending');
    debugPrint('Purchase ID: ${purchaseDetails.purchaseID}');
    debugPrint('Transaction date: ${purchaseDetails.transactionDate}');
    debugPrint('Platform: ${defaultTargetPlatform}');

    // Build a stable transaction key to guard against duplicate processing
    final String txKey = await _buildStableTransactionKey(purchaseDetails);
    if (_processedTransactions.contains(txKey)) {
      debugPrint(
        'InAppPurchaseService: Skipping duplicate processing for transaction $txKey',
      );
      _purchasePending = false;
      return;
    }

    if (purchaseDetails.status == PurchaseStatus.purchased) {
      debugPrint(
        'Purchase successful for product: ${purchaseDetails.productID}',
      );

      try {
        // Grant tokens based on product ID (consumables only)
        final int? tokens = _productTokenMap[purchaseDetails.productID];
        if (tokens != null) {
          // Halve in-app token grant to avoid double credit (Play Store + app)
          final double halfTokens = tokens.toDouble() / 2.0;
          await TokenService.addTokens(halfTokens);
          debugPrint(
            'Added ${halfTokens.toStringAsFixed(2)} tokens (halved from $tokens) for purchase ${purchaseDetails.productID}',
          );
        } else if (purchaseDetails.productID == 'spookyai_premium') {
          // Premium subscription purchase
          debugPrint('Activating premium subscription');
          await PremiumService.activatePremiumSubscription();
        } else {
          debugPrint('Unknown product ID: ${purchaseDetails.productID}');
        }

        // Complete the purchase
        if (purchaseDetails.pendingCompletePurchase) {
          debugPrint('Completing purchase for ${purchaseDetails.productID}');
          await _inAppPurchase.completePurchase(purchaseDetails);
          debugPrint('Purchase completed successfully');
        } else {
          debugPrint('Purchase does not require completion');
        }

        // Mark purchase as successful
        _lastPurchaseSuccess = true;
        _lastPurchaseCancelled = false;
        await _markTransactionProcessed(txKey);
        debugPrint('Purchase marked as successful');
      } catch (e) {
        debugPrint('Error processing successful purchase: $e');
        _lastPurchaseSuccess = false;
      }
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      debugPrint(
        'Purchase error for ${purchaseDetails.productID}: ${purchaseDetails.error}',
      );
      debugPrint('Error code: ${purchaseDetails.error?.code}');
      debugPrint('Error message: ${purchaseDetails.error?.message}');
      debugPrint('Error details: ${purchaseDetails.error?.details}');

      // On iOS, some errors might not be actual failures
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final errorCode = purchaseDetails.error?.code;
        if (errorCode == 'user_cancelled' || errorCode == 'payment_cancelled') {
          debugPrint('iOS: User cancelled purchase - not marking as failure');
          _lastPurchaseSuccess = false;
          _lastPurchaseCancelled = true;
        } else {
          debugPrint('iOS: Actual purchase error - marking as failure');
          _lastPurchaseSuccess = false;
          _lastPurchaseCancelled = false;
        }
      } else {
        _lastPurchaseSuccess = false;
        _lastPurchaseCancelled = false;
      }
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      debugPrint('Purchase canceled for ${purchaseDetails.productID}');
      _lastPurchaseSuccess = false;
      _lastPurchaseCancelled = true;
    } else if (purchaseDetails.status == PurchaseStatus.pending) {
      debugPrint('Purchase pending for ${purchaseDetails.productID}');
      // Don't mark as failed yet, wait for final status
      return;
    } else if (purchaseDetails.status == PurchaseStatus.restored) {
      debugPrint('Purchase restored for ${purchaseDetails.productID}');
      // Handle restored purchases - treat as success
      try {
        // For restore: only grant consumables if explicitly enabled once (e.g., after Play Store promo redemption)
        final int? tokens = _productTokenMap[purchaseDetails.productID];
        if (tokens != null) {
          if (_allowConsumableGrantOnNextRestore) {
            final double halfTokens = tokens.toDouble() / 2.0;
            await TokenService.addTokens(halfTokens);
            _allowConsumableGrantOnNextRestore = false; // one-shot
            debugPrint(
              'Restored consumable via explicit grant: added ${halfTokens.toStringAsFixed(2)} tokens for ${purchaseDetails.productID}',
            );
          } else {
            debugPrint('Skipping consumable grant on restore (not enabled)');
          }
        } else if (purchaseDetails.productID == 'spookyai_premium') {
          await PremiumService.activatePremiumSubscription();
          debugPrint('Premium subscription restored');
        }
        _lastPurchaseSuccess = true;
        await _markTransactionProcessed(txKey);
      } catch (e) {
        debugPrint('Error processing restored purchase: $e');
        _lastPurchaseSuccess = false;
      }
    }

    // Always set purchase pending to false when handling is complete
    _purchasePending = false;
    debugPrint(
      'Purchase handling completed for ${purchaseDetails.productID} - Success: $_lastPurchaseSuccess',
    );
  }

  static Future<String> _buildStableTransactionKey(
    PurchaseDetails purchaseDetails,
  ) async {
    // Use platform-stable identifiers where possible
    final String product = purchaseDetails.productID;
    final String vData =
        purchaseDetails.verificationData.serverVerificationData;
    final String? pId = purchaseDetails.purchaseID;

    // Prefer verification data (contains purchase token on Android, transaction receipt on iOS)
    if (vData.isNotEmpty) {
      return 'v1::$product::${vData.hashCode}';
    }
    if (pId != null && pId.trim().isNotEmpty) {
      return 'v1::$product::${pId.trim()}';
    }
    final String fallback =
        purchaseDetails.transactionDate ?? DateTime.now().toIso8601String();
    return 'v1::$product::fallback::$fallback';
  }

  static Future<void> _markTransactionProcessed(String txKey) async {
    _processedTransactions.add(txKey);
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_processedTxStorageKey) ?? <String>[];
      if (!list.contains(txKey)) {
        list.add(txKey);
        await prefs.setStringList(_processedTxStorageKey, list);
      }
    } catch (_) {}
  }

  // Public API: enable one-time consumable token grant on next restore
  static void enableConsumableGrantOnNextRestore() {
    _allowConsumableGrantOnNextRestore = true;
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

  // Debug method to check service status
  static void debugServiceStatus() {
    debugPrint('=== InAppPurchaseService Debug Info ===');
    debugPrint('Platform: ${defaultTargetPlatform.name}');
    debugPrint('Is Available: $_isAvailable');
    debugPrint('Purchase Pending: $_purchasePending');
    debugPrint('Query Error: $_queryProductError');
    debugPrint('Products Loaded: ${_products.length}');
    debugPrint('Expected Product IDs: $_productIds');
    debugPrint('Available Products:');
    for (final product in _products) {
      debugPrint('  - ${product.id}: ${product.title} (${product.price})');
    }

    // Check for missing products
    final loadedIds = _products.map((p) => p.id).toSet();
    final missingIds = _productIds.difference(loadedIds);
    if (missingIds.isNotEmpty) {
      debugPrint('MISSING PRODUCTS: $missingIds');
    }

    debugPrint('=====================================');
  }

  // Force reload products (useful for debugging)
  static Future<bool> forceReloadProducts() async {
    debugPrint('InAppPurchaseService: Force reloading products...');
    _products.clear();
    _queryProductError = null;
    await _loadProductsWithRetry();
    return _products.isNotEmpty;
  }

  // Check if specific product is available
  static bool isProductAvailable(String productId) {
    return _products.any((product) => product.id == productId);
  }

  // Reset purchase state (useful for debugging)
  static void resetPurchaseState() {
    debugPrint('InAppPurchaseService: Resetting purchase state');
    _purchasePending = false;
    _lastPurchaseSuccess = false;
  }

  // Get current purchase state for debugging
  static Map<String, dynamic> getPurchaseState() {
    return {
      'isAvailable': _isAvailable,
      'purchasePending': _purchasePending,
      'lastPurchaseSuccess': _lastPurchaseSuccess,
      'productsLoaded': _products.length,
      'queryError': _queryProductError,
    };
  }
}

// iOS StoreKit delegate
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    debugPrint('InAppPurchaseService: shouldContinueTransaction called');
    debugPrint(
      'InAppPurchaseService: Transaction ID: ${transaction.transactionIdentifier}',
    );
    debugPrint(
      'InAppPurchaseService: Product ID: ${transaction.payment.productIdentifier}',
    );
    debugPrint(
      'InAppPurchaseService: Transaction State: ${transaction.transactionState}',
    );
    debugPrint('InAppPurchaseService: Storefront: ${storefront.countryCode}');

    // Always continue transactions to allow proper handling
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    debugPrint('InAppPurchaseService: shouldShowPriceConsent called');
    // Don't show price consent dialog - let the system handle it
    return false;
  }
}
