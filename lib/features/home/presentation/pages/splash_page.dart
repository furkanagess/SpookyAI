import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'main_navigation_page.dart';

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

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationPage()),
    );
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
              ..forward().whenComplete(_goHome);
          },
        ),
      ),
    );
  }
}
