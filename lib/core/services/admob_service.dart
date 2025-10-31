import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AdMobService {
  // iOS Ad Unit ID
  static const String _iosRewardedAdUnitId =
      'ca-app-pub-3499593115543692/2142919979';

  // Android Ad Unit ID (from screenshot)
  static const String _androidRewardedAdUnitId =
      'ca-app-pub-3499593115543692/4638233133';

  // Test IDs for development
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String _dailyAdCountKey = 'daily_ad_count';
  static const String _lastAdDateKey = 'last_ad_date';
  static const int _maxDailyAds = 5;
  static const double _tokenReward = 0.5;

  static RewardedAd? _rewardedAd;
  static bool _isAdLoaded = false;
  static bool _isAdLoading = false;

  /// Get the appropriate ad unit ID based on platform
  static String _getRewardedAdUnitId() {
    if (kDebugMode) {
      return _testRewardedAdUnitId;
    }

    if (Platform.isIOS) {
      return _iosRewardedAdUnitId;
    } else if (Platform.isAndroid) {
      return _androidRewardedAdUnitId;
    }

    // Fallback to Android for other platforms
    return _androidRewardedAdUnitId;
  }

  /// Initialize AdMob
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();

    if (kDebugMode) {
      // Enable test device for development
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: ['TEST_DEVICE_ID']),
      );
    }
  }

  /// Load a rewarded ad
  static Future<void> loadRewardedAd() async {
    if (_isAdLoading || _isAdLoaded) return;

    _isAdLoading = true;

    final adUnitId = _getRewardedAdUnitId();

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          _isAdLoading = false;
          debugPrint('🎯 AdMob: Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _isAdLoaded = false;
          _isAdLoading = false;
          debugPrint('🎯 AdMob: Failed to load rewarded ad: $error');
        },
      ),
    );
  }

  /// Check if user can watch ads today
  static Future<bool> canWatchAdToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    final lastAdDate = prefs.getString(_lastAdDateKey);
    final dailyAdCount = prefs.getInt(_dailyAdCountKey) ?? 0;

    // Reset counter if it's a new day (24 hours have passed)
    if (lastAdDate != today) {
      await prefs.setString(_lastAdDateKey, today);
      await prefs.setInt(_dailyAdCountKey, 0);
      await prefs.setString('last_reset_time', now.toIso8601String());
      return true;
    }

    return dailyAdCount < _maxDailyAds;
  }

  /// Get remaining ads for today
  static Future<int> getRemainingAdsToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    final lastAdDate = prefs.getString(_lastAdDateKey);
    final dailyAdCount = prefs.getInt(_dailyAdCountKey) ?? 0;

    // Reset counter if it's a new day (24 hours have passed)
    if (lastAdDate != today) {
      await prefs.setString(_lastAdDateKey, today);
      await prefs.setInt(_dailyAdCountKey, 0);
      await prefs.setString('last_reset_time', now.toIso8601String());
      return _maxDailyAds;
    }

    return _maxDailyAds - dailyAdCount;
  }

  /// Check if ad is available and ready to show
  static Future<bool> isAdAvailable() async {
    // Check if user can watch ads today
    final canWatch = await canWatchAdToday();
    if (!canWatch) {
      return false;
    }

    // Check if ad is loaded
    return _isAdLoaded && _rewardedAd != null;
  }

  /// Get time until next ad reset
  static Future<Duration?> getTimeUntilReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString('last_reset_time');

    if (lastResetStr == null) {
      return null;
    }

    final lastReset = DateTime.parse(lastResetStr);
    final nextReset = lastReset.add(const Duration(hours: 24));
    final now = DateTime.now();

    if (now.isAfter(nextReset)) {
      return Duration.zero;
    }

    return nextReset.difference(now);
  }

  /// Show rewarded ad
  static Future<bool> showRewardedAd({
    required Function(double) onRewardEarned,
    required Function(String) onAdFailed,
  }) async {
    // Check if user can watch ads today
    final canWatch = await canWatchAdToday();
    if (!canWatch) {
      final remainingAds = await getRemainingAdsToday();
      if (remainingAds <= 0) {
        final timeUntilReset = await getTimeUntilReset();
        if (timeUntilReset != null && timeUntilReset > Duration.zero) {
          final hours = timeUntilReset.inHours;
          final minutes = timeUntilReset.inMinutes % 60;
          onAdFailed(
            'Daily ad limit reached. Try again in ${hours}h ${minutes}m.',
          );
        } else {
          onAdFailed('Daily ad limit reached. Try again tomorrow.');
        }
      } else {
        onAdFailed('Daily ad limit reached (5 ads per day).');
      }
      return false;
    }

    // Check if ad is loaded
    if (!_isAdLoaded || _rewardedAd == null) {
      onAdFailed('Ad is not ready. Please try again later.');
      return false;
    }

    bool adWatched = false;

    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('🎯 AdMob: Rewarded ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('🎯 AdMob: Rewarded ad dismissed');
        _rewardedAd?.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;

        // Load next ad
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('🎯 AdMob: Rewarded ad failed to show: $error');
        _rewardedAd?.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        onAdFailed('Failed to show ad: $error');
      },
    );

    _rewardedAd?.show(
      onUserEarnedReward: (ad, reward) async {
        debugPrint(
          '🎯 AdMob: User earned reward: ${reward.amount} ${reward.type}',
        );
        adWatched = true;

        // Update daily ad count
        await _incrementDailyAdCount();

        // Give token reward
        onRewardEarned(_tokenReward);
      },
    );

    return adWatched;
  }

  /// Increment daily ad count
  static Future<void> _incrementDailyAdCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_dailyAdCountKey) ?? 0;
    await prefs.setInt(_dailyAdCountKey, currentCount + 1);
  }

  /// Get daily ad statistics
  static Future<Map<String, dynamic>> getDailyAdStats() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    final lastAdDate = prefs.getString(_lastAdDateKey);
    final dailyAdCount = prefs.getInt(_dailyAdCountKey) ?? 0;
    final remainingAds = _maxDailyAds - dailyAdCount;
    final timeUntilReset = await getTimeUntilReset();
    final isAdReady = await isAdAvailable();

    return {
      'today': today,
      'lastAdDate': lastAdDate,
      'adsWatchedToday': dailyAdCount,
      'remainingAds': remainingAds,
      'maxDailyAds': _maxDailyAds,
      'tokenReward': _tokenReward,
      'isAdReady': isAdReady,
      'timeUntilReset': timeUntilReset?.inMinutes,
      'canWatchAd': remainingAds > 0 && isAdReady,
    };
  }

  /// Preload ads for better user experience
  static Future<void> preloadAds() async {
    await loadRewardedAd();
  }

  /// Dispose resources
  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
    _isAdLoading = false;
  }
}
