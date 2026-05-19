import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/siamois_colors.dart';
import 'siamois_title_bar.dart';

/// Animation de synchronisation (logo Siamois + anneaux).
class SiamoisSyncAnimation extends StatefulWidget {
  const SiamoisSyncAnimation({
    super.key,
    this.size = 200,
    this.hasError = false,
    this.isComplete = false,
  });

  final double size;
  final bool hasError;
  final bool isComplete;

  @override
  State<SiamoisSyncAnimation> createState() => _SiamoisSyncAnimationState();
}

class _SiamoisSyncAnimationState extends State<SiamoisSyncAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    if (widget.hasError) {
      return _StatusIcon(
        size: size,
        icon: Icons.error_outline_rounded,
        color: SiamoisColors.error,
        background: SiamoisColors.error.withValues(alpha: 0.08),
      );
    }

    if (widget.isComplete) {
      return _StatusIcon(
        size: size,
        icon: Icons.check_circle_rounded,
        color: SiamoisColors.success,
        background: SiamoisColors.success.withValues(alpha: 0.1),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_spin, _pulse]),
      builder: (context, child) {
        final pulse = 0.92 + (_pulse.value * 0.08);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      SiamoisColors.primaryContainer.withValues(alpha: 0.55),
                      SiamoisColors.surface,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: SiamoisColors.primary.withValues(alpha: 0.12),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              Transform.rotate(
                angle: _spin.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _SyncRingPainter(progress: _spin.value),
                ),
              ),
              Transform.rotate(
                angle: -_spin.value * 2 * math.pi * 0.65,
                child: CustomPaint(
                  size: Size(size * 0.82, size * 0.82),
                  painter: _SyncRingPainter(
                    progress: 1 - _spin.value,
                    secondary: true,
                  ),
                ),
              ),
              Transform.scale(
                scale: pulse,
                child: child,
              ),
            ],
          ),
        );
      },
      child: SiamoisLayersMark(size: size * 0.48),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.size,
    required this.icon,
    required this.color,
    required this.background,
  });

  final double size;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.42, color: color),
    );
  }
}

class _SyncRingPainter extends CustomPainter {
  _SyncRingPainter({required this.progress, this.secondary = false});

  final double progress;
  final bool secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - (secondary ? 6 : 4);
    final stroke = secondary ? 2.5 : 3.5;

    final track = Paint()
      ..color = SiamoisColors.primary.withValues(alpha: secondary ? 0.08 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final arc = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 1.35,
        colors: secondary
            ? [
                SiamoisColors.accent.withValues(alpha: 0.2),
                SiamoisColors.accent,
                SiamoisColors.primaryLight,
              ]
            : [
                SiamoisColors.primary.withValues(alpha: 0.15),
                SiamoisColors.primary,
                SiamoisColors.primaryLight,
              ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + progress * 2 * math.pi,
      math.pi * 1.1,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _SyncRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.secondary != secondary;
  }
}
