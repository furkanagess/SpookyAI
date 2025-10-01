import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

Future<void> showPurchaseSuccessDialog(
  BuildContext context, {
  required int tokensAdded,
  bool isPremiumSubscription = false,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: const Color(0xFF1D162B),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: Lottie.asset('assets/lottie/purchase_success.json'),
            ),
            const SizedBox(height: 8),
            Text(
              isPremiumSubscription
                  ? 'Welcome to SpookyAI Premium!'
                  : 'Congrats! Purchase Successful',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                isPremiumSubscription
                    ? 'You now have access to all premium features including $tokensAdded monthly tokens, daily spin wheel, and exclusive themes!'
                    : '$tokensAdded tokens have been added to your account. You can start generating new images now.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB9A8D0),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB25AFF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    isPremiumSubscription ? 'Start Creating!' : 'Awesome!',
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
