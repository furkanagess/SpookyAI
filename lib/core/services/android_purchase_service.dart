import 'package:flutter/foundation.dart';
import 'purchase_provider.dart';
import '../utils/platform_utils.dart';

/// Android-specific purchase service
/// Handles Android packages based on Google Play Console configuration
class AndroidPurchaseService {
  AndroidPurchaseService._();

  /// Get Android-specific packages based on Google Play Console
  static List<Pack> getAndroidPacks() {
    return [
      // Premium Subscription Package (at the top)
      // Note: Real price will be fetched from Google Play Console via pack.realPrice
      const Pack(
        name: 'SpookyAI Premium',
        tokens: 20,
        productId: 'spookyai_premium',
        price: '4.99', // Fallback price - real price comes from Google Play
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
      // Android Token Packs - Based on Google Play Console screenshot
      const Pack(
        name: '1 Token',
        tokens: 1,
        productId: '1_token',
        price: '20.00',
        note: 'Quick pack for a single image',
        imageAsset: 'assets/images/spider.png',
        whiteTint: true,
      ),
      const Pack(
        name: '10 Token',
        tokens: 10,
        productId: '10_token',
        price: '125.00',
        note: 'Great for small trials 🎃',
        imageAsset: 'assets/images/pumpkin.png',
      ),
      const Pack(
        name: '25 Token',
        tokens: 25,
        productId: '25_token',
        price: '250.00',
        note: 'Most popular choice 👻',
        imageAsset: 'assets/images/haunted-house.png',
      ),
      const Pack(
        name: '60 Token',
        tokens: 60,
        productId: '60_token',
        price: '500.00',
        note: 'For regular creators 🧙',
        imageAsset: 'assets/images/witch-hat.png',
      ),
      const Pack(
        name: '150 Token',
        tokens: 150,
        productId: '150_token',
        price: '1.000.00',
        note: 'For power users 💀',
        imageAsset: 'assets/images/ghost-face.png',
        whiteTint: true,
      ),
    ];
  }

  /// Get Android-specific product IDs
  static Set<String> getAndroidProductIds() {
    return {
      '1_token',
      '10_token',
      '25_token',
      '60_token',
      '150_token',
      'spookyai_premium',
    };
  }

  /// Get price per token for Android (using TRY)
  static String getPricePerToken(Pack pack) {
    final double total = double.tryParse(pack.price) ?? 0;
    if (pack.tokens == 0 || total == 0) return '-';
    final double per = total / pack.tokens;
    return '${per.toStringAsFixed(2)} TRY/token';
  }

  /// Check if running on Android
  static bool get isAndroid => PlatformUtils.isAndroid;

  /// Debug info for Android packages
  static void debugAndroidPacks() {
    if (!isAndroid) return;

    debugPrint('=== Android Purchase Service Debug ===');
    debugPrint('Platform: Android');
    final packs = getAndroidPacks();
    debugPrint('Android Packages (${packs.length}):');
    for (final pack in packs) {
      debugPrint(
        '  • ${pack.name}: TRY ${pack.price} (${pack.tokens} tokens) - ${getPricePerToken(pack)}',
      );
    }
    debugPrint('Product IDs: ${getAndroidProductIds()}');
    debugPrint('=====================================');
  }
}
