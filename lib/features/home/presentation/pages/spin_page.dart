import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/spin_provider.dart';
import '../widgets/redesigned_spin_wheel.dart';

class SpinPage extends StatefulWidget {
  const SpinPage({super.key});

  @override
  State<SpinPage> createState() => _SpinPageState();
}

class _SpinPageState extends State<SpinPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpinProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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

  Future<void> _onSpinComplete(SpinProvider provider) async {
    // Reload data after spin
    await provider.reloadData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpinProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F0B1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F0B1A),
            elevation: 0,
            title: const Text(
              'Daily Spin Wheel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          body: provider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Spin Wheel
                          _buildSpinWheelSection(provider),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSpinWheelSection(SpinProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D162B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // How it works info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D162B).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF6A00).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFFF6A00),
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How it works',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.spinStatusText,
                      style: const TextStyle(
                        color: Color(0xFF8C7BA6),
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Spin Wheel
              Center(
                child: RedesignedSpinWheel(
                  isPremium: provider.isPremium,
                  canSpin: provider.canSpin,
                  onSpinComplete: () => _onSpinComplete(provider),
                ),
              ),
            ],
          ),

          // Premium Lock Overlay for Non-Premium Users
          if (!provider.isPremium)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D162B).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF6A00).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Lock Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6A00).withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF6A00).withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Color(0xFFFF6A00),
                            size: 32,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title
                        const Text(
                          'Premium Required',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Description
                        const Text(
                          'Upgrade to Premium to unlock\nthe daily spin wheel',
                          style: TextStyle(
                            color: Color(0xFF8C7BA6),
                            fontSize: 14,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Upgrade Button
                        ElevatedButton.icon(
                          onPressed: _showPremiumUpgradeDialog,
                          icon: const Icon(Icons.star, size: 16),
                          label: const Text(
                            'Upgrade to Premium',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6A00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 4,
                            shadowColor: const Color(
                              0xFFFF6A00,
                            ).withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPremiumUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D162B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6A00), Color(0xFFFF8A00)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Upgrade to Premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6A00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6A00).withOpacity(0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Benefits:',
                    style: TextStyle(
                      color: Color(0xFFFF6A00),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Access to daily spin wheel',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '• Higher chance of winning big rewards',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '• Exclusive premium-only features',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8C7BA6),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Here you would typically navigate to premium purchase page
              NotificationService.info(
                context,
                message: 'Premium upgrade feature coming soon!',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}
