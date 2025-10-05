import 'package:flutter/material.dart';
import '../../../../core/models/onboarding_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/onboarding_content.dart';
import '../widgets/onboarding_indicator.dart';
import 'package:spooky_ai/features/home/presentation/pages/main_navigation_page_refactored.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/main_navigation_provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  static const List<OnboardingData> _onboardingPages = [
    OnboardingData(
      title: '🎃 Welcome to SpookyAI',
      imageAsset: 'assets/images/ghost-face.png',
      icon: '👻',
    ),
    OnboardingData(
      title: '🎨 AI Image Generation',
      imageAsset: 'assets/images/pumpkin.png',
      icon: '✨',
    ),
    OnboardingData(
      title: '🧠 Prompt Library',
      imageAsset: 'assets/images/haunted-house.png',
      icon: '📚',
    ),
    OnboardingData(
      title: '🧪 Halloween Prompt Selector',
      imageAsset: 'assets/images/witch-hat.png',
      icon: '🧩',
    ),
    OnboardingData(
      title: '🚀 Ready to Start?',
      imageAsset: 'assets/images/spider.png',
      icon: '🚀',
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
    final current = context.read<MainNavigationProvider>().onboardingPageIndex;
    if (current < _onboardingPages.length - 1) {
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
    if (!mounted) return;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationPageRefactored()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MainNavigationProvider>();
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
                  context.read<MainNavigationProvider>().setOnboardingPageIndex(
                    index,
                  );
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
                currentPage: provider.onboardingPageIndex,
                totalPages: _onboardingPages.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
