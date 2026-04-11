import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StressGaugePainter extends CustomPainter {
  final double value; // 0-100
  final Color color;
  final double animValue;

  StressGaugePainter({
    required this.value,
    required this.color,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 16;
    const startAngle = -pi * 0.75;
    const sweepTotal = pi * 1.5;

    // Track background
    final trackPaint = Paint()
      ..color = AppTheme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // Glow effect (outer)
    final glowPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * (animValue * value / 100),
      false,
      glowPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepTotal,
        colors: [color.withOpacity(0.6), color],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * (animValue * value / 100),
      false,
      progressPaint,
    );

    // Tip dot
    if (animValue > 0.02) {
      final angle = startAngle + sweepTotal * (animValue * value / 100);
      final dotPos = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final dotGlow = Paint()
        ..color = color.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(dotPos, 10, dotGlow);
      final dotPaint = Paint()..color = color;
      canvas.drawCircle(dotPos, 6, dotPaint);
      final dotInner = Paint()..color = Colors.white;
      canvas.drawCircle(dotPos, 2.5, dotInner);
    }
  }

  @override
  bool shouldRepaint(StressGaugePainter old) =>
      old.value != value || old.animValue != animValue || old.color != color;
}

class StressGaugeWidget extends StatefulWidget {
  final double stressIndex;

  const StressGaugeWidget({super.key, required this.stressIndex});

  @override
  State<StressGaugeWidget> createState() => _StressGaugeWidgetState();
}

class _StressGaugeWidgetState extends State<StressGaugeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(StressGaugeWidget old) {
    super.didUpdateWidget(old);
    if (old.stressIndex != widget.stressIndex) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.stressColor(widget.stressIndex);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        painter: StressGaugePainter(
          value: widget.stressIndex,
          color: color,
          animValue: _anim.value,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.stressIndex.toStringAsFixed(0),
                style: TextStyle(
                  color: color,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Stress Index',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
