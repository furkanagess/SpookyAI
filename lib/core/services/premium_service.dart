import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_service.dart';

class PremiumService {
  PremiumService._();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _premiumStatusKey = 'premium_user_status';
  static const String _premiumStartDateKey = 'premium_start_date';
  static const String _premiumEndDateKey = 'premium_end_date';

  // Stream controller for premium status changes
  static final StreamController<bool> _premiumStatusController =
      StreamController<bool>.broadcast();

  // Stream getter for listening to premium status changes
  static Stream<bool> get premiumStatusStream =>
      _premiumStatusController.stream;

  /// Check if user has active premium subscription
  static Future<bool> isPremiumUser() async {
    try {
      final premiumStatus = await _secureStorage.read(key: _premiumStatusKey);
      if (premiumStatus != 'true') return false;

      // Check if premium subscription is still active
      final endDateStr = await _secureStorage.read(key: _premiumEndDateKey);
      if (endDateStr == null) return false;

      final endDate = DateTime.parse(endDateStr);
      final now = DateTime.now();

      // If subscription expired, remove premium status
      if (now.isAfter(endDate)) {
        await removePremiumStatus();
        return false;
      }

      // Ensure monthly premium tokens are granted once every 30 days
      await _ensureMonthlyTokens();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Set premium status for user
  static Future<void> setPremiumStatus({
    required bool isPremium,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (isPremium) {
      await _secureStorage.write(key: _premiumStatusKey, value: 'true');

      final start = startDate ?? DateTime.now();
      final end =
          endDate ??
          DateTime.now().add(const Duration(days: 30)); // 30 days default

      await _secureStorage.write(
        key: _premiumStartDateKey,
        value: start.toIso8601String(),
      );
      await _secureStorage.write(
        key: _premiumEndDateKey,
        value: end.toIso8601String(),
      );
    } else {
      await removePremiumStatus();
    }

    // Notify listeners about the status change
    _premiumStatusController.add(isPremium);
  }

  /// Remove premium status
  static Future<void> removePremiumStatus() async {
    await _secureStorage.delete(key: _premiumStatusKey);
    await _secureStorage.delete(key: _premiumStartDateKey);
    await _secureStorage.delete(key: _premiumEndDateKey);

    // Notify listeners about the status change
    _premiumStatusController.add(false);
  }

  /// Get premium subscription info
  static Future<PremiumInfo?> getPremiumInfo() async {
    try {
      final isPremium = await isPremiumUser();
      if (!isPremium) return null;

      final startDateStr = await _secureStorage.read(key: _premiumStartDateKey);
      final endDateStr = await _secureStorage.read(key: _premiumEndDateKey);

      if (startDateStr == null || endDateStr == null) return null;

      return PremiumInfo(
        startDate: DateTime.parse(startDateStr),
        endDate: DateTime.parse(endDateStr),
        isActive: DateTime.now().isBefore(DateTime.parse(endDateStr)),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get days remaining in premium subscription
  static Future<int> getDaysRemaining() async {
    final info = await getPremiumInfo();
    if (info == null) return 0;

    final now = DateTime.now();
    final difference = info.endDate.difference(now);

    return difference.inDays > 0 ? difference.inDays : 0;
  }

  /// Check if premium features should be available
  static Future<bool> canAccessPremiumFeatures() async {
    return await isPremiumUser();
  }

  /// Get premium benefits description
  static List<String> getPremiumBenefits() {
    return [
      '20 tokens per month',
      'Access to all prompts',
      'Daily token spin wheel',
      'Higher token rewards',
      'Exclusive premium themes',
      'Priority AI processing',
      'Ad-free experience',
      'Advanced customization options',
    ];
  }

  /// Get premium package details
  static PremiumPackage getMonthlyPackage() {
    return PremiumPackage(
      id: 'spookyai_premium',
      name: 'SpookyAI Premium',
      price: 4.99,
      currency: 'USD',
      duration: Duration(days: 30),
      features: [
        '20 tokens per month',
        'Access to all prompts',
        'Daily token spin wheel',
        'Higher token rewards',
        'Exclusive premium themes',
        'Priority AI processing',
        'Ad-free experience',
        'Advanced customization options',
      ],
    );
  }

  /// Demo method to activate premium for testing
  static Future<void> activatePremiumDemo({
    Duration duration = const Duration(days: 30),
  }) async {
    final now = DateTime.now();
    await setPremiumStatus(
      isPremium: true,
      startDate: now,
      endDate: now.add(duration),
    );
  }

  /// Demo method to deactivate premium for testing
  static Future<void> deactivatePremiumDemo() async {
    await removePremiumStatus();
  }

  /// Activate premium subscription with monthly tokens
  static Future<void> activatePremiumSubscription() async {
    await setPremiumStatus(
      isPremium: true,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );

    // Grant monthly tokens on activation
    await _grantMonthlyTokens();
  }

  /// Testing: Simulate a monthly renewal token grant (does not change dates)
  static Future<void> simulateMonthlyRenewalGrantForTesting() async {
    await _grantMonthlyTokens();
  }

  /// Testing: Expire premium immediately by setting endDate in the past
  static Future<void> expirePremiumNowForTesting() async {
    final now = DateTime.now();
    await setPremiumStatus(
      isPremium: true,
      startDate: now.subtract(const Duration(days: 40)),
      endDate: now.subtract(const Duration(days: 1)),
    );
  }

  /// Testing: Refresh notification without state change
  static Future<void> notifyListenersForTesting() async {
    final active = await isPremiumUser();
    _premiumStatusController.add(active);
  }

  /// Dispose the stream controller
  static void dispose() {
    _premiumStatusController.close();
  }

  /// Grant monthly premium tokens
  static Future<void> _grantMonthlyTokens() async {
    try {
      await TokenService.grantMonthlyPremiumTokens();
      await TokenService.markMonthlyTokensClaimed();
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> _ensureMonthlyTokens() async {
    try {
      final canClaim = await TokenService.canClaimMonthlyTokens();
      if (canClaim) {
        await _grantMonthlyTokens();
      }
    } catch (e) {
      // no-op
    }
  }
}

class PremiumPackage {
  final String id;
  final String name;
  final double price;
  final String currency;
  final Duration duration;
  final List<String> features;

  const PremiumPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.duration,
    required this.features,
  });

  String get formattedPrice {
    return '\$${price.toStringAsFixed(2)} $currency';
  }

  String get formattedDuration {
    if (duration.inDays >= 30) {
      final months = (duration.inDays / 30).round();
      return months == 1 ? '1 month' : '$months months';
    } else if (duration.inDays >= 7) {
      final weeks = (duration.inDays / 7).round();
      return weeks == 1 ? '1 week' : '$weeks weeks';
    } else {
      return '${duration.inDays} days';
    }
  }
}

class PremiumInfo {
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  const PremiumInfo({
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final difference = endDate.difference(now);
    return difference.inDays > 0 ? difference.inDays : 0;
  }

  double get progressPercentage {
    final totalDays = endDate.difference(startDate).inDays;
    final remainingDays = daysRemaining;
    return totalDays > 0 ? (totalDays - remainingDays) / totalDays : 0.0;
  }
}
