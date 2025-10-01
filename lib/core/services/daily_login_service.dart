import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DailyLoginService {
  static const String _lastLoginDateKey = 'last_login_date';
  static const String _currentStreakKey = 'current_streak';
  static const String _longestStreakKey = 'longest_streak';
  static const String _totalLoginsKey = 'total_logins';
  static const String _dailyRewardClaimedKey = 'daily_reward_claimed';
  static const String _loginHistoryKey = 'login_history';

  /// Check if user can claim daily reward
  static Future<bool> canClaimDailyReward() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimDate = prefs.getString(_dailyRewardClaimedKey);

    if (lastClaimDate == null) return true;

    final lastClaim = DateTime.parse(lastClaimDate);
    final now = DateTime.now();

    // Check if it's a new day
    return !_isSameDay(lastClaim, now);
  }

  /// Record daily login and update streak
  static Future<DailyLoginResult> recordDailyLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if already logged in today
    final lastLoginDate = prefs.getString(_lastLoginDateKey);
    if (lastLoginDate != null) {
      final lastLogin = DateTime.parse(lastLoginDate);
      if (_isSameDay(lastLogin, now)) {
        return DailyLoginResult(
          isNewLogin: false,
          currentStreak: await getCurrentStreak(),
          longestStreak: await getLongestStreak(),
          reward: 0,
          message: 'Already logged in today!',
        );
      }
    }

    // Update streak
    int currentStreak = await getCurrentStreak();
    int longestStreak = await getLongestStreak();

    if (lastLoginDate != null) {
      final lastLogin = DateTime.parse(lastLoginDate);
      final daysDifference = today
          .difference(DateTime(lastLogin.year, lastLogin.month, lastLogin.day))
          .inDays;

      if (daysDifference == 1) {
        // Consecutive day - increment streak
        currentStreak++;
      } else if (daysDifference > 1) {
        // Streak broken - reset to 1
        currentStreak = 1;
      }
    } else {
      // First login
      currentStreak = 1;
    }

    // Update longest streak
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
      await prefs.setInt(_longestStreakKey, longestStreak);
    }

    // Save current streak
    await prefs.setInt(_currentStreakKey, currentStreak);
    await prefs.setString(_lastLoginDateKey, today.toIso8601String());

    // Update total logins
    final totalLogins = (prefs.getInt(_totalLoginsKey) ?? 0) + 1;
    await prefs.setInt(_totalLoginsKey, totalLogins);

    // Save to login history
    await _saveLoginHistory(today);

    // Calculate daily reward
    final dailyReward = _calculateDailyReward(currentStreak);

    return DailyLoginResult(
      isNewLogin: true,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      reward: dailyReward,
      message: _getStreakMessage(currentStreak),
    );
  }

  /// Get current streak
  static Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentStreakKey) ?? 0;
  }

  /// Get longest streak
  static Future<int> getLongestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_longestStreakKey) ?? 0;
  }

  /// Get total logins
  static Future<int> getTotalLogins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalLoginsKey) ?? 0;
  }

  /// Get login history (last 30 days)
  static Future<List<DateTime>> getLoginHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_loginHistoryKey);

    if (historyJson == null) return [];

    try {
      final List<dynamic> historyList = json.decode(historyJson);
      return historyList.map((dateStr) => DateTime.parse(dateStr)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get daily reward calendar
  static List<DailyReward> getDailyRewardCalendar() {
    return [
      DailyReward(day: 1, tokens: 1, description: 'Welcome back!'),
      DailyReward(day: 2, tokens: 1, description: 'Keep it up!'),
      DailyReward(day: 3, tokens: 1, description: 'Getting stronger!'),
      DailyReward(day: 4, tokens: 1, description: 'On fire!'),
      DailyReward(day: 5, tokens: 1, description: 'Unstoppable!'),
      DailyReward(day: 6, tokens: 1, description: 'Almost there!'),
      DailyReward(day: 7, tokens: 1, description: 'Week streak!'),
      DailyReward(day: 14, tokens: 1, description: '2-week champion!'),
      DailyReward(day: 21, tokens: 1, description: '3-week legend!'),
      DailyReward(day: 30, tokens: 1, description: 'Monthly master!'),
    ];
  }

  /// Get streak bonuses
  static List<StreakBonus> getStreakBonuses() {
    return [
      StreakBonus(days: 3, bonusTokens: 1, description: 'First streak!'),
      StreakBonus(days: 7, bonusTokens: 2, description: 'Week warrior!'),
      StreakBonus(days: 14, bonusTokens: 3, description: 'Two weeks strong!'),
      StreakBonus(days: 21, bonusTokens: 5, description: 'Three weeks!'),
      StreakBonus(days: 30, bonusTokens: 8, description: 'Monthly streak!'),
    ];
  }

  /// Calculate daily reward - always 1 token regardless of streak
  static int _calculateDailyReward(int streak) {
    return 1; // Always 1 token per day
  }

  /// Get streak message
  static String _getStreakMessage(int streak) {
    if (streak == 1) {
      return 'Welcome back! Start your streak!';
    } else if (streak == 3) {
      return '3-day streak! Keep going!';
    } else if (streak == 7) {
      return 'Week streak! Amazing!';
    } else if (streak == 14) {
      return 'Two weeks! Incredible!';
    } else if (streak == 21) {
      return 'Three weeks! Legendary!';
    } else if (streak == 30) {
      return '30 days! Master level!';
    } else if (streak > 30) {
      return '$streak days! You\'re unstoppable!';
    } else {
      return '$streak-day streak! Keep it up!';
    }
  }

  /// Save login to history
  static Future<void> _saveLoginHistory(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getLoginHistory();

    // Add new date
    history.add(date);

    // Keep only last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    history.removeWhere((d) => d.isBefore(thirtyDaysAgo));

    // Save updated history
    final historyJson = json.encode(
      history.map((d) => d.toIso8601String()).toList(),
    );
    await prefs.setString(_loginHistoryKey, historyJson);
  }

  /// Check if two dates are the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Reset all data (for testing)
  static Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLoginDateKey);
    await prefs.remove(_currentStreakKey);
    await prefs.remove(_longestStreakKey);
    await prefs.remove(_totalLoginsKey);
    await prefs.remove(_dailyRewardClaimedKey);
    await prefs.remove(_loginHistoryKey);
  }
}

class DailyLoginResult {
  final bool isNewLogin;
  final int currentStreak;
  final int longestStreak;
  final int reward;
  final String message;

  const DailyLoginResult({
    required this.isNewLogin,
    required this.currentStreak,
    required this.longestStreak,
    required this.reward,
    required this.message,
  });
}

class DailyReward {
  final int day;
  final int tokens;
  final String description;

  const DailyReward({
    required this.day,
    required this.tokens,
    required this.description,
  });
}

class StreakBonus {
  final int days;
  final int bonusTokens;
  final String description;

  const StreakBonus({
    required this.days,
    required this.bonusTokens,
    required this.description,
  });
}
