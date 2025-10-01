import 'package:flutter/material.dart';
import '../../../../core/services/daily_login_service.dart';
import '../../../../core/theme/app_metrics.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalLogins = 0;
  List<DateTime> _loginHistory = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadStatsData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadStatsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load daily login data
      final currentStreak = await DailyLoginService.getCurrentStreak();
      final longestStreak = await DailyLoginService.getLongestStreak();
      final totalLogins = await DailyLoginService.getTotalLogins();
      final loginHistory = await DailyLoginService.getLoginHistory();

      setState(() {
        _currentStreak = currentStreak;
        _longestStreak = longestStreak;
        _totalLogins = totalLogins;
        _loginHistory = loginHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D162B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Your Stats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats grid - compact layout
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.local_fire_department,
                  title: 'Current Streak',
                  value: '$_currentStreak',
                  color: const Color(0xFFFF6A00),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.emoji_events,
                  title: 'Best Streak',
                  value: '$_longestStreak',
                  color: const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.login,
                  title: 'Total Logins',
                  value: '$_totalLogins',
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.calendar_month,
                  title: 'This Month',
                  value: '${_getThisMonthLogins()}',
                  color: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLoginSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D162B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_getActiveDays()} days',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCompactLoginCalendar(),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCompactCalendarLegend('Active', const Color(0xFF4CAF50)),
              const SizedBox(width: 12),
              _buildCompactCalendarLegend('Inactive', const Color(0xFF2A1F3D)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCalendarLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
        ),
      ],
    );
  }

  int _getActiveDays() {
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

  Widget _buildCompactStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLoginCalendar() {
    final now = DateTime.now();
    final calendarDays = <Widget>[];

    // Show last 30 days in a 6x5 grid - more compact
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final isLoggedIn = _loginHistory.any(
        (loginDate) =>
            loginDate.year == date.year &&
            loginDate.month == date.month &&
            loginDate.day == date.day,
      );

      calendarDays.add(
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isLoggedIn
                ? const Color(0xFF4CAF50)
                : const Color(0xFF2A1F3D),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isLoggedIn
                  ? const Color(0xFF4CAF50).withOpacity(0.6)
                  : Colors.white.withOpacity(0.1),
              width: 0.3,
            ),
            boxShadow: isLoggedIn
                ? [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 1,
                      offset: const Offset(0, 0.5),
                    ),
                  ]
                : null,
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 6,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      childAspectRatio: 1,
      children: calendarDays,
    );
  }

  int _getThisMonthLogins() {
    final now = DateTime.now();
    return _loginHistory
        .where((date) => date.year == now.year && date.month == now.month)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1A),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.analytics, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F0B1A),
        elevation: 0,
        toolbarHeight: AppMetrics.toolbarHeight,
        actions: const [],
      ),
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            bottom: 40,
            left: 20,
            child: Opacity(
              opacity: 0.06,
              child: Text('📊', style: TextStyle(fontSize: 80)),
            ),
          ),
          Positioned(
            top: 60,
            right: 20,
            child: Opacity(
              opacity: 0.04,
              child: Text('📈', style: TextStyle(fontSize: 60)),
            ),
          ),
          Positioned(
            top: 120,
            left: 40,
            child: Opacity(
              opacity: 0.04,
              child: Text('🎯', style: TextStyle(fontSize: 50)),
            ),
          ),

          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4CAF50),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStatsSection(),
                          const SizedBox(height: 12),
                          _buildDailyLoginSection(),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
