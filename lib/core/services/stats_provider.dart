import 'package:flutter/foundation.dart';
import '../services/daily_login_service.dart';

class StatsProvider extends ChangeNotifier {
  // State variables
  bool _isLoading = true;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalLogins = 0;
  List<DateTime> _loginHistory = [];

  // Getters
  bool get isLoading => _isLoading;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get totalLogins => _totalLogins;
  List<DateTime> get loginHistory => List.unmodifiable(_loginHistory);

  // Initialize the provider
  Future<void> initialize() async {
    await _loadStatsData();
  }

  Future<void> _loadStatsData() async {
    setLoading(true);

    try {
      // Load daily login data
      final currentStreak = await DailyLoginService.getCurrentStreak();
      final longestStreak = await DailyLoginService.getLongestStreak();
      final totalLogins = await DailyLoginService.getTotalLogins();
      final loginHistory = await DailyLoginService.getLoginHistory();

      _currentStreak = currentStreak;
      _longestStreak = longestStreak;
      _totalLogins = totalLogins;
      _loginHistory = loginHistory;
      setLoading(false);

      debugPrint(
        'StatsProvider: Data loaded - currentStreak: $currentStreak, longestStreak: $longestStreak, totalLogins: $totalLogins',
      );
    } catch (e) {
      setLoading(false);
      debugPrint('StatsProvider: Error loading stats data: $e');
    }
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set stats data
  void setStatsData({
    required int currentStreak,
    required int longestStreak,
    required int totalLogins,
    required List<DateTime> loginHistory,
  }) {
    _currentStreak = currentStreak;
    _longestStreak = longestStreak;
    _totalLogins = totalLogins;
    _loginHistory = loginHistory;
    notifyListeners();
  }

  // Reload data
  Future<void> reloadData() async {
    await _loadStatsData();
  }

  // Get this month's logins
  int getThisMonthLogins() {
    final now = DateTime.now();
    return _loginHistory
        .where((date) => date.year == now.year && date.month == now.month)
        .length;
  }

  // Get active days in the last 30 days
  int getActiveDays() {
    final now = DateTime.now();
    return _loginHistory
        .where(
          (date) =>
              date.year == now.year &&
              date.month == now.month &&
              date.isAfter(now.subtract(const Duration(days: 30))),
        )
        .length;
  }

  // Check if user logged in on a specific date
  bool isLoggedInOnDate(DateTime date) {
    return _loginHistory.any(
      (loginDate) =>
          loginDate.year == date.year &&
          loginDate.month == date.month &&
          loginDate.day == date.day,
    );
  }

  // Get login history for calendar display (last 30 days)
  List<DateTime> getLast30Days() {
    final now = DateTime.now();
    final List<DateTime> days = [];
    for (int i = 29; i >= 0; i--) {
      days.add(now.subtract(Duration(days: i)));
    }
    return days;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
