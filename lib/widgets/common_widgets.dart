import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A horizontal bar that grows from 0 to [fraction] width.
class AnimatedBar extends StatelessWidget {
  final double fraction; // 0..1
  final Color color;
  final double height;
  final int delayMs;
  const AnimatedBar({
    super.key,
    required this.fraction,
    required this.color,
    this.height = 6,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: Colors.white.withOpacity(0.06),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
            duration: Duration(milliseconds: 800 + delayMs),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A gently pulsing status dot. color: green=live, amber=alt, red=gap.
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulsingDot({super.key, required this.color, this.size = 8});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.35).animate(_c),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Standard dark card container with optional title row.
class SectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget child;
  final EdgeInsets padding;
  const SectionCard({
    super.key,
    this.title,
    this.icon,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: AppColors.rainCyan),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    title!.toUpperCase(),
                    style: AppTheme.label(size: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

/// Small stat tile: big mono value + small label.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.color = AppColors.rainCyan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(value, style: AppTheme.mono(size: 16, weight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              textAlign: TextAlign.center, style: AppTheme.label(size: 9)),
        ],
      ),
    );
  }
}
