import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'main_navigation_page.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../../../../core/models/onboarding_data.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkOnboardingAndNavigate() async {
    if (!mounted) return;

    final bool isOnboardingCompleted =
        await OnboardingService.isOnboardingCompleted();

    if (isOnboardingCompleted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D162B),
      body: Center(
        child: Lottie.asset(
          'assets/lottie/splash_lottie.json',
          controller: _controller,
          onLoaded: (comp) {
            _controller
              ..duration = comp.duration
              ..forward().whenComplete(_checkOnboardingAndNavigate);
          },
        ),
      ),
    );
  }
}
