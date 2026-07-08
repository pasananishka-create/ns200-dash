import 'dart:math' as math;
import 'package:flutter/material.dart';

class RpmGauge extends StatefulWidget {
  final int rpm;
  final int maxRpm;

  const RpmGauge({super.key, this.rpm = 0, this.maxRpm = 12000});

  @override
  State<RpmGauge> createState() => _RpmGaugeState();
}

class _RpmGaugeState extends State<RpmGauge> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _smoothRpm;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _smoothRpm = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(RpmGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rpm != widget.rpm) {
      _smoothRpm = Tween<double>(
        begin: _smoothRpm.value,
        end: (widget.rpm / widget.maxRpm).clamp(0, 1),
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _smoothRpm,
      builder: (context, _) {
        return CustomPaint(
          painter: _RpmGaugePainter(
            progress: _smoothRpm.value,
            rpm: widget.rpm,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _RpmGaugePainter extends CustomPainter {
  final double progress;
  final int rpm;

  _RpmGaugePainter({required this.progress, required this.rpm});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.38;

    _drawBackground(canvas, center, radius);
    _drawArc(canvas, center, radius);
    _drawTicks(canvas, center, radius);
    _drawNeedle(canvas, center, radius);
    _drawCenterText(canvas, center, radius);
  }

  void _drawBackground(Canvas canvas, Offset center, double radius) {
    final bgPaint = Paint()
      ..color = const Color(0xFF0D0D0D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 1.15, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 1.15, borderPaint);
  }

  void _drawArc(Canvas canvas, Offset center, double radius) {
    const startAngle = -225 * math.pi / 180;
    const totalAngle = 270 * math.pi / 180;

    // Background arc
    final bgArc = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, totalAngle, false, bgArc);

    // Active arc with gradient
    final activeProgress = progress * totalAngle;
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + totalAngle,
      colors: const [
        Color(0xFF00E676),
        Color(0xFFFFEB3B),
        Color(0xFFFF1744),
      ],
      stops: const [0, 0.6, 0.85],
    );

    final activeArc = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    if (activeProgress > 0.01) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, activeProgress, false, activeArc);
    }
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    const totalTicks = 10;
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 2;

    for (int i = 0; i <= totalTicks; i++) {
      final angle = -225 * math.pi / 180 + (i / totalTicks) * 270 * math.pi / 180;
      final inner = radius * 0.85;
      final outer = i % 2 == 0 ? radius * 0.78 : radius * 0.82;

      final p1 = Offset(center.dx + math.cos(angle) * inner, center.dy + math.sin(angle) * inner);
      final p2 = Offset(center.dx + math.cos(angle) * outer, center.dy + math.sin(angle) * outer);

      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  void _drawNeedle(Canvas canvas, Offset center, double radius) {
    final angle = -225 * math.pi / 180 + progress * 270 * math.pi / 180;
    final needleLen = radius * 0.72;

    final needlePoint = Offset(
      center.dx + math.cos(angle) * needleLen,
      center.dy + math.sin(angle) * needleLen,
    );

    final needlePaint = Paint()
      ..color = const Color(0xFFFF1744)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawLine(center, needlePoint, needlePaint);

    // Center cap
    final capPaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(center, 6, capPaint);
    canvas.drawCircle(center, 3, Paint()..color = Colors.black);
  }

  void _drawCenterText(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: rpm > 0 ? '${(rpm / 100).round() / 10.0}x100' : '0',
        style: const TextStyle(
          fontFamily: 'Digital',
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 + 30));

    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'RPM',
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 11,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(canvas, Offset(center.dx - labelPainter.width / 2, center.dy - labelPainter.height / 2 + 52));
  }

  @override
  bool shouldRepaint(_RpmGaugePainter old) => old.progress != progress || old.rpm != rpm;
}
