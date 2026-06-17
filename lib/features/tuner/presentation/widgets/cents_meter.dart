import 'dart:math';
import 'package:flutter/material.dart';

class CentsMeter extends StatefulWidget {
  final double cents;

  const CentsMeter({super.key, required this.cents});

  @override
  State<CentsMeter> createState() => _CentsMeterState();
}

class _CentsMeterState extends State<CentsMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = Tween<double>(
      begin: widget.cents.clamp(-50.0, 50.0),
      end: widget.cents.clamp(-50.0, 50.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(CentsMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cents != widget.cents) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.cents.clamp(-50.0, 50.0),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: 340,
          height: 140,
          child: CustomPaint(painter: _MeterPainter(cents: _animation.value)),
        );
      },
    );
  }
}

class _MeterPainter extends CustomPainter {
  final double cents;

  const _MeterPainter({required this.cents});

  // Converts a cents value (-50..+50) to an angle on the arc.
  // Arc spans from pi (left) to 2*pi (right), i.e. a 180° semi-circle.
  double _centsToAngle(double value) {
    return pi + ((value + 50) / 100) * pi;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Arc pivot sits slightly below bottom edge so only the top half is visible
    final center = Offset(size.width / 2, size.height + 10);
    final outerRadius = size.width * 0.48;

    _drawBackground(canvas, center, outerRadius);
    _drawZoneArcs(canvas, center, outerRadius);
    _drawTicks(canvas, center, outerRadius);
    _drawNeedle(canvas, center, outerRadius);
    _drawCenterHub(canvas, center);
    _drawCentsBox(canvas, size);
  }

  // ─── Background arc (dark filled semi-circle) ───────────────────────────
  void _drawBackground(Canvas canvas, Offset center, double outerRadius) {
    final bgPaint = Paint()
      ..color = const Color(0xFF1A2535)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx - outerRadius - 16, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius + 16),
        pi,
        pi,
        false,
      )
      ..lineTo(center.dx + outerRadius + 16, center.dy)
      ..close();
    canvas.drawPath(path, bgPaint);

    // Subtle inner shadow ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius + 2),
      pi,
      pi,
      false,
      Paint()
        ..color = Colors.black38
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke,
    );
  }

  // ─── Colored zone arcs ───────────────────────────────────────────────────
  void _drawZoneArcs(Canvas canvas, Offset center, double outerRadius) {
    const arcRadius = 0.82; // fraction of outerRadius
    final r = outerRadius * arcRadius;
    final rect = Rect.fromCircle(center: center, radius: r);

    // Red left zone: -50 to -10
    canvas.drawArc(
      rect,
      _centsToAngle(-50),
      (_centsToAngle(-10) - _centsToAngle(-50)),
      false,
      Paint()
        ..color = Colors.orangeAccent
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );

    // Green center zone: -10 to +10
    canvas.drawArc(
      rect,
      _centsToAngle(-10),
      (_centsToAngle(10) - _centsToAngle(-10)),
      false,
      Paint()
        ..color = const Color(0xFF3DCC7A)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );

    // Red right zone: +10 to +50
    canvas.drawArc(
      rect,
      _centsToAngle(10),
      (_centsToAngle(50) - _centsToAngle(10)),
      false,
      Paint()
        ..color = Colors.orangeAccent
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );
  }

  // ─── Tick marks ─────────────────────────────────────────────────────────
  void _drawTicks(Canvas canvas, Offset center, double outerRadius) {
    // Draw ticks every 2 cents (-50 to +50), with major ticks every 10 cents
    for (int i = -50; i <= 50; i += 2) {
      final angle = _centsToAngle(i.toDouble());
      final isMajor = i % 10 == 0;
      final isMid = i % 5 == 0 && !isMajor;
      final isInGreenZone = i >= -10 && i <= 10;

      final tickLength = isMajor ? 14.0 : (isMid ? 9.0 : 6.0);
      final tickWidth = isMajor ? 2.0 : 1.0;

      Color tickColor;
      if (isInGreenZone) {
        tickColor = isMajor
            ? const Color(0xFF3DCC7A)
            : const Color(0xFF3DCC7A).withValues(alpha: 0.6);
      } else {
        tickColor = isMajor
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.35);
      }

      final innerR = outerRadius - tickLength;
      final outerR = outerRadius;

      final p1 = Offset(
        center.dx + innerR * cos(angle),
        center.dy + innerR * sin(angle),
      );
      final p2 = Offset(
        center.dx + outerR * cos(angle),
        center.dy + outerR * sin(angle),
      );

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = tickColor
          ..strokeWidth = tickWidth
          ..strokeCap = StrokeCap.round,
      );

      // Labels for major ticks
      if (isMajor) {
        final labelR = outerRadius - 24;
        final labelPos = Offset(
          center.dx + labelR * cos(angle),
          center.dy + labelR * sin(angle),
        );

        final label = i > 0 ? '+$i' : '$i';
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: isInGreenZone
                  ? const Color(0xFF3DCC7A)
                  : Colors.white.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(
          canvas,
          Offset(labelPos.dx - tp.width / 2, labelPos.dy - tp.height / 2),
        );
      }
    }
  }

  // ─── Needle ──────────────────────────────────────────────────────────────
  void _drawNeedle(Canvas canvas, Offset center, double outerRadius) {
    final angle = _centsToAngle(cents);
    final inTune = cents.abs() <= 10;

    final needleColor = inTune
        ? const Color(0xFF3DCC7A)
        : const Color(0xFFE05A4E);
    final glowColor = needleColor.withValues(alpha: 0.25);

    final tipR = outerRadius - 8.0;
    final tip = Offset(
      center.dx + tipR * cos(angle),
      center.dy + tipR * sin(angle),
    );

    // Glow behind needle
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = glowColor
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // Main needle
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = needleColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  // ─── Center hub ──────────────────────────────────────────────────────────
  void _drawCenterHub(Canvas canvas, Offset center) {
    final inTune = cents.abs() <= 10;
    final hubColor = inTune ? const Color(0xFF3DCC7A) : const Color(0xFFE05A4E);

    // Outer dark ring
    canvas.drawCircle(center, 10, Paint()..color = const Color(0xFF0E1820));
    // Colored fill
    canvas.drawCircle(center, 7, Paint()..color = hubColor);
    // White center dot
    canvas.drawCircle(center, 2.5, Paint()..color = Colors.white);
  }

  // ─── Cents value display box ─────────────────────────────────────────────
  void _drawCentsBox(Canvas canvas, Size size) {
    final inTune = cents.abs() <= 10;
    final valueColor = inTune ? const Color(0xFF3DCC7A) : Colors.orangeAccent;

    final label = '${cents >= 0 ? '+' : ''}${cents.toStringAsFixed(1)}¢';

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: valueColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const boxPadH = 10.0;
    const boxPadV = 6.0;
    final boxW = tp.width + boxPadH * 2;
    final boxH = tp.height + boxPadV * 2;
    final boxX = size.width - boxW - 60;
    final boxY = size.height - boxH - 10;

    // Box background
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxX, boxY, boxW, boxH),
      const Radius.circular(6),
    );

    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF0E1820));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = valueColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    tp.paint(canvas, Offset(boxX + boxPadH, boxY + boxPadV));
  }

  @override
  bool shouldRepaint(covariant _MeterPainter oldDelegate) {
    return oldDelegate.cents != cents;
  }
}
