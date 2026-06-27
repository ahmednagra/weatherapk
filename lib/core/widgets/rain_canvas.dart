import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Continuous rain-particle field. [intensity] (0..1) scales drop count,
/// speed and opacity so the background reflects current precipitation.
class RainCanvas extends StatefulWidget {
  final double intensity;
  const RainCanvas({super.key, required this.intensity});

  @override
  State<RainCanvas> createState() => _RainCanvasState();
}

class _RainCanvasState extends State<RainCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final List<_Drop> _drops = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  void _seed(Size size) {
    final target = (30 + widget.intensity * 90).round();
    while (_drops.length < target) {
      _drops.add(_Drop.random(_rnd, size));
    }
    while (_drops.length > target) {
      _drops.removeLast();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      _seed(size);
      return AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          for (final d in _drops) {
            d.y += d.speed * (0.6 + widget.intensity);
            if (d.y > size.height + 10) {
              d.reset(_rnd, size);
            }
          }
          return CustomPaint(
            size: size,
            painter: _RainPainter(_drops, widget.intensity),
          );
        },
      );
    });
  }
}

class _Drop {
  double x, y, speed, len, opacity;
  _Drop(this.x, this.y, this.speed, this.len, this.opacity);

  factory _Drop.random(Random r, Size s) {
    return _Drop(
      r.nextDouble() * s.width,
      r.nextDouble() * s.height,
      1.5 + r.nextDouble() * 3,
      6 + r.nextDouble() * 14,
      0.05 + r.nextDouble() * 0.13,
    );
  }

  void reset(Random r, Size s) {
    x = r.nextDouble() * s.width;
    y = -10;
    speed = 1.5 + r.nextDouble() * 3;
    len = 6 + r.nextDouble() * 14;
    opacity = 0.05 + r.nextDouble() * 0.13;
  }
}

class _RainPainter extends CustomPainter {
  final List<_Drop> drops;
  final double intensity;
  _RainPainter(this.drops, this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    for (final d in drops) {
      paint.color = AppColors.rainCyan
          .withOpacity((d.opacity * (0.4 + intensity)).clamp(0.0, 0.5));
      canvas.drawLine(
        Offset(d.x, d.y),
        Offset(d.x - 1, d.y + d.len),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) => true;
}
