import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Animated ring that fills from 0 to [value]/[max] on build.
class CapeRing extends StatelessWidget {
  final double value;
  final double max;
  final double size;
  const CapeRing({
    super.key,
    required this.value,
    this.max = 4000,
    this.size = 80,
  });

  Color get _color {
    if (value >= 2500) return AppColors.dangerCoral;
    if (value >= 1000) return AppColors.stormAmber;
    return AppColors.growthGreen;
  }

  @override
  Widget build(BuildContext context) {
    final frac = (value / max).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: frac),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(v, _color),
            child: Center(
              child: Text(
                value.toStringAsFixed(0),
                style: AppTypography.mono(
                    size: size * 0.18,
                    weight: FontWeight.w600,
                    color: _color),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double frac;
  final Color color;
  _RingPainter(this.frac, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = Colors.white.withOpacity(0.08);
    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * frac,
      false,
      prog,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.frac != frac || old.color != color;
}
