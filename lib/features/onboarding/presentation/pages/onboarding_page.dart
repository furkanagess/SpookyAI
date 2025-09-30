import 'package:flutter/material.dart';
import '../../../../core/models/onboarding_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/onboarding_content.dart';
import '../widgets/onboarding_indicator.dart';
import '../../../home/presentation/pages/main_navigation_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardingData> _onboardingPages = [
    OnboardingData(
      title: '🎃 Welcome to SpookyAI',
      description:
          'Transform your photos into spooky Halloween masterpieces with the power of AI!',
      imageAsset: 'assets/images/ghost-face.png',
      icon: '👻',
    ),
    OnboardingData(
      title: '🎨 AI Image Generation',
      description:
          'Create spooky scenes from text descriptions or transform your existing photos with Halloween magic.',
      imageAsset: 'assets/images/pumpkin.png',
      icon: '✨',
    ),
    OnboardingData(
      title: '👻 Ghostface Trend',
      description:
          'Get the viral TikTok-style transformations that everyone is talking about!',
      imageAsset: 'assets/images/ghost_face_trend.png',
      icon: '🔥',
    ),
    OnboardingData(
      title: '💎 Token System',
      description:
          'Use tokens to generate images. Start with free tokens and purchase more as needed.',
      imageAsset: 'assets/images/spider.png',
      icon: '💎',
    ),
    OnboardingData(
      title: '🚀 Ready to Start?',
      description:
          'You\'re all set! Let\'s create some spooky masterpieces together.',
      imageAsset: 'assets/images/witch-hat.png',
      icon: '🎯',
      buttonText: 'Get Started',
      isLastPage: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService.completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1A),
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60), // Spacer for centering
                  Text(
                    'SpookyAI',
                    style: AppTheme.headingStyle.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Color(0xFF8C7BA6), fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Page Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingPages.length,
                itemBuilder: (context, index) {
                  return OnboardingContent(
                    data: _onboardingPages[index],
                    onNext: _nextPage,
                  );
                },
              ),
            ),

            // Page Indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: OnboardingIndicator(
                currentPage: _currentPage,
                totalPages: _onboardingPages.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
