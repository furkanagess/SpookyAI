import 'package:shared_preferences/shared_preferences.dart';

class OnboardingData {
  const OnboardingData({
    required this.title,
    required this.imageAsset,
    required this.icon,
    this.description,
    this.buttonText,
    this.isLastPage = false,
  });

  final String title;
  final String? description;
  final String imageAsset;
  final String icon;
  final String? buttonText;
  final bool isLastPage;
}

class OnboardingService {
  OnboardingService._();

  static const String _onboardingKey = 'onboarding_completed_v1';

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }
}
