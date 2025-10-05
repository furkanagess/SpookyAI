import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/stats_provider.dart';
import '../../../../core/theme/app_metrics.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().initialize();
    });
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

  Widget _buildStatsSection(StatsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D162B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Your Stats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stats grid - compact layout
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.local_fire_department,
                  title: 'Current Streak',
                  value: '${provider.currentStreak}',
                  color: const Color(0xFFFF6A00),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.emoji_events,
                  title: 'Best Streak',
                  value: '${provider.longestStreak}',
                  color: const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.login,
                  title: 'Total Logins',
                  value: '${provider.totalLogins}',
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.calendar_month,
                  title: 'This Month',
                  value: '${provider.getThisMonthLogins()}',
                  color: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLoginSection(StatsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D162B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${provider.getActiveDays()} days',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCompactLoginCalendar(provider),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildCompactCalendarLegend('Active', const Color(0xFF4CAF50)),
              const SizedBox(width: 8),
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

  Widget _buildCompactStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 9,
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

  Widget _buildCompactLoginCalendar(StatsProvider provider) {
    final now = DateTime.now();
    final calendarDays = <Widget>[];

    // Show last 30 days in a 6x5 grid - more compact
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final isLoggedIn = provider.isLoggedInOnDate(date);

      calendarDays.add(
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(
            color: isLoggedIn
                ? const Color(0xFF4CAF50)
                : const Color(0xFF2A1F3D),
            borderRadius: BorderRadius.circular(1),
            border: Border.all(
              color: isLoggedIn
                  ? const Color(0xFF4CAF50).withOpacity(0.6)
                  : Colors.white.withOpacity(0.1),
              width: 0.2,
            ),
            boxShadow: isLoggedIn
                ? [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 0.5,
                      offset: const Offset(0, 0.3),
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
      mainAxisSpacing: 1,
      crossAxisSpacing: 1,
      childAspectRatio: 1,
      children: calendarDays,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, provider, child) {
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
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 18,
                  ),
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
                  child: provider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4CAF50),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _buildStatsSection(provider),
                              const SizedBox(height: 8),
                              _buildDailyLoginSection(provider),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
