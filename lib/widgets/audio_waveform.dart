import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/config/theme.dart';

class AudioWaveform extends StatefulWidget {
  final bool isActive;
  final double barHeight;

  const AudioWaveform({
    super.key,
    required this.isActive,
    this.barHeight = 40.0,
  });

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(24, (index) => Container(
          width: 3,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: JarvisTheme.textMuted.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        )),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(24, (index) {
            final phase = (index / 24.0) * 2 * math.pi;
            final dynamicHeight = math.sin(_controller.value * 2 * math.pi + phase).abs() * widget.barHeight + 6;

            return Container(
              width: 3,
              height: dynamicHeight,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    JarvisTheme.primaryCyan,
                    JarvisTheme.primaryCyan.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: JarvisTheme.primaryCyan.withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
