import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/services/spin_service.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/services/notification_service.dart';

class RedesignedSpinWheel extends StatefulWidget {
  final bool isPremium;
  final bool canSpin;
  final VoidCallback? onSpinComplete;

  const RedesignedSpinWheel({
    super.key,
    required this.isPremium,
    required this.canSpin,
    this.onSpinComplete,
  });

  @override
  State<RedesignedSpinWheel> createState() => _RedesignedSpinWheelState();
}

class _RedesignedSpinWheelState extends State<RedesignedSpinWheel>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _spinAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  bool _isSpinning = false;
  SpinResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _spinAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  Future<void> _performSpin() async {
    if (_isSpinning || !widget.canSpin) return;

    setState(() {
      _isSpinning = true;
    });

    // Perform the spin
    final result = await SpinService.performSpin();

    if (result.success) {
      // Calculate final angle with multiple rotations
      final finalAngle = result.angle;

      // Animate the spin
      _spinController.reset();
      _spinAnimation = Tween<double>(begin: 0, end: finalAngle).animate(
        CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
      );

      _spinController.forward().then((_) {
        setState(() {
          _isSpinning = false;
          _lastResult = result;
        });

        // Add tokens to user's balance
        TokenService.addTokens(result.reward);

        // Show enhanced success notification
        _showSpinResultDialog(result);

        // Call completion callback
        widget.onSpinComplete?.call();
      });
    } else {
      setState(() {
        _isSpinning = false;
      });

      NotificationService.error(context, message: result.message);
    }
  }

  void _showSpinResultDialog(SpinResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1D162B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF6A00).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6A00).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration Animation
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6A00), Color(0xFFFF8A00)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6A00).withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              Text(
                'Congratulations!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'You won ${result.reward} tokens!',
                style: TextStyle(
                  color: const Color(0xFFFF6A00),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Wheel Container - Extra large and centered
        SizedBox(
          width: 360,
          height: 360,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(
                            0xFFFF6A00,
                          ).withOpacity(0.4 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Spin wheel
              AnimatedBuilder(
                animation: _spinAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _spinAnimation.value * (math.pi / 180),
                    child: _buildModernSpinWheel(),
                  );
                },
              ),

              // Center spin button
              _buildModernSpinButton(),

              // Pointer with glow effect
              Positioned(top: 20, child: _buildModernPointer()),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Spin status and last result
        _buildSpinStatus(),
      ],
    );
  }

  Widget _buildModernSpinWheel() {
    final segments = SpinService.getSpinSegments();
    return Container(
      width: 340,
      height: 340,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFF6A00).withOpacity(0.5),
          width: 6,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        size: const Size(340, 340),
        painter: ModernSpinWheelPainter(segments),
      ),
    );
  }

  Widget _buildModernSpinButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: widget.canSpin && !_isSpinning ? _performSpin : null,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.canSpin && !_isSpinning
                      ? [const Color(0xFFFF6A00), const Color(0xFFFF8A00)]
                      : [const Color(0xFF8C7BA6), const Color(0xFF6A5B8B)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        (widget.canSpin && !_isSpinning
                                ? const Color(0xFFFF6A00)
                                : const Color(0xFF8C7BA6))
                            .withOpacity(0.6),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                _isSpinning
                    ? Icons.autorenew
                    : widget.canSpin
                    ? Icons.play_arrow
                    : Icons.lock,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernPointer() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6A00), Color(0xFFFF8A00)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withOpacity(0.7),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        size: const Size(40, 40),
        painter: ModernPointerPainter(),
      ),
    );
  }

  Widget _buildSpinStatus() {
    return Column(
      children: [
        // Spin availability status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.canSpin
                  ? [
                      const Color(0xFF4CAF50).withOpacity(0.2),
                      const Color(0xFF4CAF50).withOpacity(0.1),
                    ]
                  : [
                      const Color(0xFFFF5722).withOpacity(0.2),
                      const Color(0xFFFF5722).withOpacity(0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: widget.canSpin
                  ? const Color(0xFF4CAF50).withOpacity(0.4)
                  : const Color(0xFFFF5722).withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (widget.canSpin
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF5722))
                        .withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.canSpin ? Icons.check_circle : Icons.schedule,
                color: widget.canSpin
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF5722),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.canSpin ? 'Ready to spin!' : 'Come back tomorrow',
                style: TextStyle(
                  color: widget.canSpin
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF5722),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        if (_lastResult != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6A00), Color(0xFFFF8A00)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6A00).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Last spin: ${_lastResult!.reward} tokens!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class ModernSpinWheelPainter extends CustomPainter {
  final List<SpinSegment> segments;

  ModernSpinWheelPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Draw segments with gradient effects
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final startAngle = (i * 2 * math.pi) / segments.length;
      final sweepAngle = (2 * math.pi) / segments.length;

      // Create gradient for each segment
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          Color(segment.color),
          Color(segment.color).withOpacity(0.8),
          Color(segment.color),
        ],
      );

      final rect = Rect.fromCircle(center: center, radius: radius);
      paint.shader = gradient.createShader(rect);

      // Draw segment
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Draw segment border
      canvas.drawArc(rect, startAngle, sweepAngle, true, strokePaint);

      // Draw segment label with better positioning and styling
      final labelAngle = startAngle + (sweepAngle / 2);
      final labelRadius = radius * 0.75;
      final labelX = center.dx + labelRadius * math.cos(labelAngle);
      final labelY = center.dy + labelRadius * math.sin(labelAngle);

      // Draw token number only
      final tokenText = '${segment.reward}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: tokenText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black87,
                offset: Offset(2, 2),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );
    }

    // Draw center circle
    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const RadialGradient(
        colors: [Color(0xFF2A1F3D), Color(0xFF1D162B)],
      ).createShader(Rect.fromCircle(center: center, radius: 45));

    canvas.drawCircle(center, 45, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ModernPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2 - 8, size.height * 0.7);
    path.lineTo(size.width / 2 + 8, size.height * 0.7);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
