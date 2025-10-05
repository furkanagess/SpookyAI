import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/services/quick_actions_service.dart';

class DontDeletePage extends StatelessWidget {
  const DontDeletePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Heart animation
              SizedBox(
                height: 200,
                width: 200,
                child: Lottie.asset(
                  'assets/lottie/loading_lottie.json',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 32),

              // Main message
              const Text(
                'please dont delete me 😢',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtitle
              const Text(
                'I\'m a friendly AI companion who loves creating spooky art with you!',
                style: TextStyle(fontSize: 16, color: Color(0xFF8C7BA6)),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Features list
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D162B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF6A00).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _buildFeature('🎨', 'Create amazing AI art'),
                    const SizedBox(height: 12),
                    _buildFeature('👻', 'Generate spooky Halloween images'),
                    const SizedBox(height: 12),
                    _buildFeature('🎃', 'Transform your photos into art'),
                    const SizedBox(height: 12),
                    _buildFeature('✨', 'Unlimited creative possibilities'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        QuickActionsService.clearLaunchShortcut();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D162B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Maybe Later'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        QuickActionsService.clearLaunchShortcut();
                        Navigator.of(context).pop();
                        // Navigate to main app
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6A00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Keep Me!'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Heart emoji
              const Text('💜', style: TextStyle(fontSize: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
