import 'package:flutter/foundation.dart';
import '../services/token_service.dart';
import '../services/premium_service.dart';
import '../services/in_app_purchase_service.dart';

class Pack {
  const Pack({
    required this.name,
    required this.tokens,
    required this.productId,
    required this.price,
    required this.note,
    required this.imageAsset,
    this.whiteTint = false,
    this.isPremium = false,
    this.features = const [],
  });
  final String name;
  final int tokens;
  final String productId; // App Store Product ID
  final String price; // display only
  final String note;
  final String imageAsset;
  final bool whiteTint;
  final bool isPremium;
  final List<String> features;
}

class PurchaseProvider extends ChangeNotifier {
  // State variables
  List<Pack> _packs = [];
  bool _isPremium = false;
  int? _selectedIndex;
  bool _isLoading = false;

  // Getters
  List<Pack> get packs => List.unmodifiable(_packs);
  bool get isPremium => _isPremium;
  int? get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;

  // Initialize the provider
  Future<void> initialize() async {
    debugPrint('PurchaseProvider: Initializing...');
    await _initialize();
    await _loadPremiumStatus();
    _initializePacks();

    // Debug service status
    InAppPurchaseService.debugServiceStatus();

    // Test setup
    final setupOk = await testPurchaseSetup();
    if (!setupOk) {
      debugPrint('PurchaseProvider: WARNING - Purchase setup test failed!');
      debugPrint('PurchaseProvider: This may cause "product not found" errors');
    }
  }

  Future<void> _initialize() async {
    await InAppPurchaseService.initialize();
  }

  Future<void> _loadPremiumStatus() async {
    try {
      _isPremium = await PremiumService.isPremiumUser();
      notifyListeners();
      debugPrint(
        'PurchaseProvider: Premium status loaded - isPremium: $_isPremium',
      );
    } catch (e) {
      _isPremium = false;
      notifyListeners();
      debugPrint('PurchaseProvider: Error loading premium status: $e');
    }
  }

  void _initializePacks() {
    _packs = [
      // Premium Subscription Package (at the top)
      const Pack(
        name: 'SpookyAI Premium',
        tokens: 20,
        productId: 'spookyai_premium',
        price: '4.99',
        note: 'Monthly subscription with exclusive benefits',
        imageAsset: 'assets/images/ghost-face.png',
        whiteTint: true,
        isPremium: true,
        features: [
          '20 tokens per month',
          'Access to all prompts',
          'Daily token spin wheel',
          'Priority AI processing',
        ],
      ),
      // Token Packs - Updated with correct Play Console product IDs
      const Pack(
        name: '1 Token',
        tokens: 1,
        productId: '1_token',
        price: '0.49',
        note: 'Quick pack for a single image',
        imageAsset: 'assets/images/spider.png',
        whiteTint: true,
      ),
      const Pack(
        name: '10 Token',
        tokens: 10,
        productId: '10_token',
        price: '2.99',
        note: 'Great for small trials 🎃',
        imageAsset: 'assets/images/pumpkin.png',
      ),
      const Pack(
        name: '25 Token',
        tokens: 25,
        productId: '25_token',
        price: '5.99',
        note: 'Most popular choice 👻',
        imageAsset: 'assets/images/haunted-house.png',
      ),
      const Pack(
        name: '60 Token',
        tokens: 60,
        productId: '60_token',
        price: '11.99',
        note: 'For regular creators 🧙',
        imageAsset: 'assets/images/witch-hat.png',
      ),
      const Pack(
        name: '150 Token',
        tokens: 150,
        productId: '150_token',
        price: '24.99',
        note: 'For power users 💀',
        imageAsset: 'assets/images/ghost-face.png',
        whiteTint: true,
      ),
    ];
    notifyListeners();
  }

  // Set selected index
  void setSelectedIndex(int? index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set premium status
  void setPremiumStatus(bool isPremium) {
    _isPremium = isPremium;
    notifyListeners();
  }

  // Buy a pack, returns true if purchase completed successfully
  Future<bool> buyPack(Pack pack) async {
    if (_isLoading) {
      debugPrint('PurchaseProvider: Already loading, skipping purchase');
      return false;
    }

    debugPrint(
      'PurchaseProvider: Starting purchase for ${pack.name} (${pack.productId})',
    );
    setLoading(true);

    try {
      // Check if service is available
      if (!InAppPurchaseService.isAvailable) {
        debugPrint('PurchaseProvider: In-app purchase not available');
        return false;
      }

      // Check if products are loaded
      if (InAppPurchaseService.products.isEmpty) {
        debugPrint(
          'PurchaseProvider: No products loaded, attempting to reload...',
        );
        final reloadSuccess = await InAppPurchaseService.forceReloadProducts();
        if (!reloadSuccess) {
          debugPrint('PurchaseProvider: Failed to reload products');
          debugPrint(
            'PurchaseProvider: Query error: ${InAppPurchaseService.queryProductError}',
          );
          return false;
        }
      }

      // Check if specific product is available
      if (!InAppPurchaseService.isProductAvailable(pack.productId)) {
        debugPrint('PurchaseProvider: Product ${pack.productId} not available');
        debugPrint(
          'PurchaseProvider: Available products: ${InAppPurchaseService.products.map((p) => p.id).join(', ')}',
        );
        return false;
      }

      final bool success = await InAppPurchaseService.purchaseProduct(
        pack.productId,
      );

      if (success) {
        debugPrint('PurchaseProvider: Purchase successful for ${pack.name}');

        // Handle premium subscription differently
        if (pack.isPremium) {
          await PremiumService.activatePremiumSubscription();
          await TokenService.grantMonthlyPremiumTokens();
          await TokenService.markMonthlyTokensClaimed();
          setPremiumStatus(true);
        } else {
          // Regular token purchase - refresh token provider
          // This will be handled by the calling widget
        }

        return true;
      } else {
        debugPrint('PurchaseProvider: Purchase failed for ${pack.name}');
        debugPrint(
          'PurchaseProvider: Query error: ${InAppPurchaseService.queryProductError}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('PurchaseProvider: Error during purchase: $e');
      debugPrint('PurchaseProvider: Stack trace: ${StackTrace.current}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    setLoading(true);

    try {
      await InAppPurchaseService.restorePurchases();
      debugPrint('PurchaseProvider: Purchases restored successfully');
    } catch (e) {
      debugPrint('PurchaseProvider: Error restoring purchases: $e');
    } finally {
      setLoading(false);
    }
  }

  // Get selected pack
  Pack? get selectedPack {
    if (_selectedIndex == null || _selectedIndex! >= _packs.length) {
      return null;
    }
    return _packs[_selectedIndex!];
  }

  // Check if a pack can be selected
  bool canSelectPack(Pack pack) {
    if (pack.isPremium && _isPremium) {
      return false; // Already premium user
    }
    return true;
  }

  // Get price per token for a pack
  String getPricePerToken(Pack pack) {
    final double total = double.tryParse(pack.price) ?? 0;
    if (pack.tokens == 0) return '-';
    final double per = total / pack.tokens;
    return '${per.toStringAsFixed(2)} USD/token';
  }

  // Test method to verify purchase setup
  Future<bool> testPurchaseSetup() async {
    debugPrint('PurchaseProvider: Testing purchase setup...');

    // Check service availability
    if (!InAppPurchaseService.isAvailable) {
      debugPrint('PurchaseProvider: In-app purchase not available');
      return false;
    }

    // Check products
    if (InAppPurchaseService.products.isEmpty) {
      debugPrint('PurchaseProvider: No products loaded');
      return false;
    }

    // Check for our specific products
    final requiredProducts = [
      '1_token',
      '10_token',
      '25_token',
      '60_token',
      '150_token',
      'spookyai_premium',
    ];
    final loadedProductIds = InAppPurchaseService.products
        .map((p) => p.id)
        .toSet();

    for (final productId in requiredProducts) {
      if (!loadedProductIds.contains(productId)) {
        debugPrint('PurchaseProvider: Missing product: $productId');
        return false;
      }
    }

    debugPrint('PurchaseProvider: All required products are available');
    return true;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
