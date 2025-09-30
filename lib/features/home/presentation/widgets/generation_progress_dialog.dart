import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class GenerationProgressController {
  GenerationProgressController(this._progress, this._close);
  final ValueNotifier<double> _progress;
  final VoidCallback _close;

  void setProgress(double value) {
    if (value.isNaN) return;
    final clamped = value.clamp(0.0, 1.0);
    _progress.value = clamped;
  }

  void close() => _close();
}

GenerationProgressController showGenerationProgressDialog(
  BuildContext context,
) {
  final progress = ValueNotifier<double>(0.0);

  void closeDialog() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: const Color(0xFF1D162B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 120,
                child: Lottie.asset(
                  'assets/lottie/loading_lottie.json',
                  repeat: true,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your image is being generated...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (_, value, __) {
                  final percent = (value * 100).clamp(0, 100).toInt();
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: value == 0 ? null : value,
                          backgroundColor: const Color(0xFF2A203B),
                          color: const Color(0xFFB25AFF),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          color: Color(0xFFB9A8D0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'This may take a little while. Thanks for your patience!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8C7BA6), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    },
  );

  // Fake progress: increase 10% every 1200ms (3x slower) up to 90%
  double fake = 0.0;
  Future<void> tick() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (progress.value >= 0.9) return; // stop auto at 90%
    fake = (fake + 0.1).clamp(0.0, 0.9);
    progress.value = fake;
    tick();
  }

  // Start ticking after an extra 2 seconds to extend duration
  Future<void>.delayed(const Duration(seconds: 2), () {
    tick();
  });

  return GenerationProgressController(progress, closeDialog);
}
