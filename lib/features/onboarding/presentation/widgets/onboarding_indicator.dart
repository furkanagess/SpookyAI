import 'package:flutter/material.dart';

class OnboardingIndicator extends StatelessWidget {
  const OnboardingIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentPage == index
                ? const Color(0xFFFF6A00)
                : const Color(0xFF8C7BA6).withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
