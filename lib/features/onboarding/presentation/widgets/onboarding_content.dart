import 'package:flutter/material.dart';
import '../../../../core/models/onboarding_data.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingContent extends StatelessWidget {
  const OnboardingContent({
    super.key,
    required this.data,
    required this.onNext,
  });

  final OnboardingData data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1D162B),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: const Color(0xFFFF6A00).withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6A00).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(data.icon, style: const TextStyle(fontSize: 48)),
            ),
          ),

          const SizedBox(height: 40),

          // Image
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                data.imageAsset,
                fit: BoxFit.cover,
                color:
                    (data.imageAsset.endsWith('spider.png') ||
                        data.imageAsset.endsWith('ghost-face.png'))
                    ? Colors.white
                    : null,
                colorBlendMode:
                    (data.imageAsset.endsWith('spider.png') ||
                        data.imageAsset.endsWith('ghost-face.png'))
                    ? BlendMode.srcIn
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            data.title,
            style: AppTheme.headingStyle.copyWith(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            style: const TextStyle(
              color: Color(0xFF8C7BA6),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A00),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onNext,
              child: Text(
                data.buttonText ?? 'Next',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
