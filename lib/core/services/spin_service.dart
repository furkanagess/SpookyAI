import 'package:shared_preferences/shared_preferences.dart';
import 'premium_service.dart';

class SpinService {
  SpinService._();

  static const String _dailySpinKey = 'daily_spin_date';
  static const String _spinCountKey = 'daily_spin_count';
  static const String _premiumSpinCountKey = 'premium_daily_spin_count';
  static const String _lastSpinRewardKey = 'last_spin_reward';

  // Spin wheel segments with rewards (1-8 tokens with weighted probabilities)
  static const List<SpinSegment> _spinSegments = [
    SpinSegment(reward: 1, weight: 35, color: 0xFF4CAF50, label: '1 Token'),
    SpinSegment(reward: 2, weight: 30, color: 0xFF2196F3, label: '2 Tokens'),
    SpinSegment(reward: 3, weight: 20, color: 0xFF9C27B0, label: '3 Tokens'),
    SpinSegment(reward: 4, weight: 8, color: 0xFFFF9800, label: '4 Tokens'),
    SpinSegment(reward: 5, weight: 4, color: 0xFFE91E63, label: '5 Tokens'),
    SpinSegment(reward: 6, weight: 2, color: 0xFFFF5722, label: '6 Tokens'),
    SpinSegment(reward: 7, weight: 1, color: 0xFF795548, label: '7 Tokens'),
    SpinSegment(reward: 8, weight: 1, color: 0xFF607D8B, label: '8 Tokens'),
  ];

  /// Check if user can spin today
  static Future<bool> canSpinToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSpinDate = prefs.getString(_dailySpinKey);

    if (lastSpinDate == null) return true;

    final lastDate = DateTime.parse(lastSpinDate);
    final today = DateTime.now();

    // Check if it's a new day
    return !_isSameDay(lastDate, today);
  }

  /// Check if premium user can spin (1 spin per day)
  static Future<bool> canPremiumSpinToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSpinDate = prefs.getString(_dailySpinKey);
    final spinCount = prefs.getInt(_premiumSpinCountKey) ?? 0;

    if (lastSpinDate == null) return true;

    final lastDate = DateTime.parse(lastSpinDate);
    final today = DateTime.now();

    // Reset count if it's a new day
    if (!_isSameDay(lastDate, today)) {
      await prefs.setInt(_premiumSpinCountKey, 0);
      return true;
    }

    // Premium users get 1 spin per day (same as regular users)
    return spinCount < 1;
  }

  /// Get remaining spins for today
  static Future<int> getRemainingSpins() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSpinDate = prefs.getString(_dailySpinKey);
    final spinCount = prefs.getInt(_spinCountKey) ?? 0;
    final premiumSpinCount = prefs.getInt(_premiumSpinCountKey) ?? 0;

    if (lastSpinDate == null) return 1;

    final lastDate = DateTime.parse(lastSpinDate);
    final today = DateTime.now();

    // Reset counts if it's a new day
    if (!_isSameDay(lastDate, today)) {
      return 1; // All users get 1 spin per day
    }

    // Check if user is premium
    final isPremium = await _isPremiumUser();
    if (isPremium) {
      return 1 - premiumSpinCount; // Premium users get 1 spin per day
    }

    return 1 - spinCount; // Regular users get 1 spin per day
  }

  /// Perform a spin and get reward
  static Future<SpinResult> performSpin() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = await _isPremiumUser();
    final today = DateTime.now();

    // Check if user can spin
    final canSpin = isPremium
        ? await canPremiumSpinToday()
        : await canSpinToday();
    if (!canSpin) {
      return SpinResult(
        success: false,
        reward: 0,
        message: 'No spins remaining today!',
      );
    }

    // Generate random spin result
    final segment = _getRandomSegment();
    final angle = _calculateSpinAngle(segment);

    // Update spin count
    if (isPremium) {
      final currentCount = prefs.getInt(_premiumSpinCountKey) ?? 0;
      await prefs.setInt(_premiumSpinCountKey, currentCount + 1);
    } else {
      await prefs.setInt(_spinCountKey, 1);
    }

    // Update last spin date
    await prefs.setString(_dailySpinKey, today.toIso8601String());

    // Save last reward
    await prefs.setInt(_lastSpinRewardKey, segment.reward);

    return SpinResult(
      success: true,
      reward: segment.reward,
      angle: angle,
      segment: segment,
      message: 'Congratulations! You won ${segment.reward} tokens!',
    );
  }

  /// Get last spin reward
  static Future<int> getLastSpinReward() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastSpinRewardKey) ?? 0;
  }

  /// Get spin segments for UI
  static List<SpinSegment> getSpinSegments() {
    return _spinSegments;
  }

  /// Check if user is premium
  static Future<bool> _isPremiumUser() async {
    return await PremiumService.isPremiumUser();
  }

  /// Generate random spin segment based on weights
  static SpinSegment _getRandomSegment() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    int cumulativeWeight = 0;

    for (final segment in _spinSegments) {
      cumulativeWeight += segment.weight;
      if (random < cumulativeWeight) {
        return segment;
      }
    }

    // Fallback to first segment
    return _spinSegments.first;
  }

  /// Calculate spin angle for animation
  static double _calculateSpinAngle(SpinSegment segment) {
    final segmentIndex = _spinSegments.indexOf(segment);
    final segmentAngle = 360.0 / _spinSegments.length;
    final baseAngle = segmentIndex * segmentAngle;

    // Add some randomness to the angle
    final randomOffset = (DateTime.now().millisecondsSinceEpoch % 100) / 100.0;
    final finalAngle = baseAngle + (segmentAngle * randomOffset);

    // Add multiple rotations for better animation effect
    return finalAngle + (360.0 * 5); // 5 full rotations
  }

  /// Check if two dates are the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Reset daily spins (for testing purposes)
  static Future<void> resetDailySpins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dailySpinKey);
    await prefs.remove(_spinCountKey);
    await prefs.remove(_premiumSpinCountKey);
  }
}

class SpinSegment {
  final int reward;
  final int weight; // Higher weight = more likely to be selected
  final int color;
  final String label;

  const SpinSegment({
    required this.reward,
    required this.weight,
    required this.color,
    required this.label,
  });
}

class SpinResult {
  final bool success;
  final int reward;
  final double angle;
  final SpinSegment? segment;
  final String message;

  const SpinResult({
    required this.success,
    required this.reward,
    this.angle = 0.0,
    this.segment,
    required this.message,
  });
}
