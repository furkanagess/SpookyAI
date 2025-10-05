import 'package:flutter/foundation.dart';
import 'purchase_provider.dart';
import '../utils/platform_utils.dart';

/// iOS-specific purchase service
/// Handles iOS packages based on App Store Connect configuration
class IOSPurchaseService {
  IOSPurchaseService._();

  /// Get iOS-specific packages based on App Store Connect
  static List<Pack> getIOSPacks() {
    return [
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
      // iOS Token Packs - Using App Store Connect packages (In Review)
      const Pack(
        name: '1 Token',
        tokens: 1,
        productId: '1_token',
        price: '0.99',
        note: 'Perfect for trying out SpookyAI',
        imageAsset: 'assets/images/spider.png',
        whiteTint: true,
      ),
      const Pack(
        name: '10 Token',
        tokens: 10,
        productId: '10_token',
        price: '4.99',
        note: 'Great for exploring different styles 🎃',
        imageAsset: 'assets/images/pumpkin.png',
      ),
      const Pack(
        name: '25 Token',
        tokens: 25,
        productId: '25_token',
        price: '9.99',
        note: 'Most popular among creators 👻',
        imageAsset: 'assets/images/haunted-house.png',
      ),
      const Pack(
        name: '60 Token',
        tokens: 60,
        productId: '60_token',
        price: '19.99',
        note: 'For serious digital artists 🧙',
        imageAsset: 'assets/images/witch-hat.png',
      ),
      const Pack(
        name: '150 Token',
        tokens: 150,
        productId: '150_token',
        price: '39.99',
        note: 'For professional content creators 💀',
        imageAsset: 'assets/images/ghost-face.png',
        whiteTint: true,
      ),
    ];
  }

  /// Get iOS-specific product IDs
  static Set<String> getIOSProductIds() {
    return {
      '1_token',
      '10_token',
      '25_token',
      '60_token',
      '150_token',
      'spookyai_premium',
    };
  }

  /// Get price per token for iOS (using real App Store prices)
  static String getPricePerToken(Pack pack) {
    // Use real price from App Store, fallback to display price
    final String realPrice = pack.realPrice;
    final String priceToUse = (realPrice.isNotEmpty && realPrice != pack.price)
        ? realPrice
        : pack.price;

    final double total = double.tryParse(priceToUse) ?? 0;
    if (pack.tokens == 0 || total == 0) return '-';
    final double per = total / pack.tokens;
    return '${per.toStringAsFixed(2)} USD/token';
  }

  /// Check if running on iOS
  static bool get isIOS => PlatformUtils.isIOS;

  /// Debug info for iOS packages
  static void debugIOSPacks() {
    if (!isIOS) return;

    debugPrint('=== iOS Purchase Service Debug ===');
    debugPrint('Platform: iOS');
    final packs = getIOSPacks();
    debugPrint('iOS Packages (${packs.length}):');
    for (final pack in packs) {
      debugPrint(
        '  • ${pack.name}: ${pack.realPrice} (${pack.tokens} tokens) - ${getPricePerToken(pack)}',
      );
    }
    debugPrint('Product IDs: ${getIOSProductIds()}');
    debugPrint('==================================');
  }
}
