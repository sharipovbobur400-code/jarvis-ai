import 'dart:math' as math;
import 'package:flutter/material.dart';

class AICoreVisualizer extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final double soundLevel;
  final double size;

  const AICoreVisualizer({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    this.soundLevel = 0.0,
    this.size = 220.0,
  });

  @override
  State<AICoreVisualizer> createState() => _AICoreVisualizerState();
}

class _AICoreVisualizerState extends State<AICoreVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic scale based on voice/activity
    final activityMultiplier = widget.isListening
        ? 1.15 + (widget.soundLevel.clamp(0.0, 10.0) / 30.0)
        : widget.isSpeaking
            ? 1.08 + (math.sin(DateTime.now().millisecondsSinceEpoch / 150) * 0.05)
            : 1.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Center(
          child: Transform.scale(
            scale: activityMultiplier,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _ArcReactorPainter(
                  rotation: _controller.value * 2 * math.pi,
                  isListening: widget.isListening,
                  isSpeaking: widget.isSpeaking,
                  glowIntensity: widget.isListening ? 1.0 : (widget.isSpeaking ? 0.8 : 0.4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArcReactorPainter extends CustomPainter {
  final double rotation;
  final bool isListening;
  final bool isSpeaking;
  final double glowIntensity;

  _ArcReactorPainter({
    required this.rotation,
    required this.isListening,
    required this.isSpeaking,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final primaryColor = isListening
        ? const Color(0xFF00E5FF)
        : isSpeaking
            ? const Color(0xFFFFB300)
            : const Color(0xFF00B0FF);

    // 1. Outer Glow Circle
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(0.15 * glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 25 * glowIntensity);
    canvas.drawCircle(center, radius * 0.9, glowPaint);

    // 2. Outer Rotating Dashed Ring
    final outerRingPaint = Paint()
      ..color = primaryColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dashCount = 12;
    final sweepAngle = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = rotation + (i * sweepAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.85),
        startAngle,
        sweepAngle * 0.6,
        false,
        outerRingPaint,
      );
    }

    // 3. Middle Counter-Rotating Ring with Segments
    final middleRingPaint = Paint()
      ..color = primaryColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (int i = 0; i < 6; i++) {
      final startAngle = -rotation * 1.5 + (i * (math.pi / 3));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.65),
        startAngle,
        math.pi / 5,
        false,
        middleRingPaint,
      );
    }

    // 4. Inner Glowing Reactor Core
    final innerCorePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          primaryColor,
          primaryColor.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.45));

    canvas.drawCircle(center, radius * 0.45, innerCorePaint);

    // 5. Center Target Dot
    final centerDot = Paint()..color = Colors.white;
    canvas.drawCircle(center, 4, centerDot);
  }

  @override
  bool shouldRepaint(covariant _ArcReactorPainter oldDelegate) => true;
}
