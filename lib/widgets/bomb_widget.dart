import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The game's little paper-cut character, drawn at every size without assets.
class BombWidget extends StatefulWidget {
  const BombWidget({
    super.key,
    required this.progress,
    this.size = 180,
    this.animate = true,
    this.exploded = false,
    this.sparkColor = const Color(0xFFEF5B35),
  });

  final double progress;
  final double size;
  final bool animate;
  final bool exploded;
  final Color sparkColor;

  @override
  State<BombWidget> createState() => _BombWidgetState();
}

class _BombWidgetState extends State<BombWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _disableAnimations = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.disableAnimationsOf(context);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant BombWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final duration = Duration(milliseconds: widget.progress < 0.3 ? 280 : 1300);
    final durationChanged = _controller.duration != duration;
    _controller.duration = duration;
    if (widget.animate && !widget.exploded && !_disableAnimations) {
      if (!_controller.isAnimating || durationChanged) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.exploded ? 'القنبلة انفجرت' : 'القنبلة',
      image: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            painter: _BombPainter(
              progress: widget.progress.clamp(0.0, 1.0).toDouble(),
              sway: Curves.easeInOut.transform(_controller.value) * 2 - 1,
              exploded: widget.exploded,
              sparkColor: widget.sparkColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _BombPainter extends CustomPainter {
  const _BombPainter({
    required this.progress,
    required this.sway,
    required this.exploded,
    required this.sparkColor,
  });

  static const _ink = Color(0xFF252720);
  static const _paper = Color(0xFFF6F1E7);
  final double progress;
  final double sway;
  final bool exploded;
  final Color sparkColor;

  Paint _fill(Color color) => Paint()..color = color;

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);
    if (exploded) {
      _drawBurst(canvas);
      _drawBrokenBody(canvas);
    } else {
      // Movement stays inside the drawing's generous canvas margins.
      canvas.translate(98, 123);
      canvas.rotate(sway * (progress < 0.3 ? 0.035 : 0.014));
      canvas.translate(-98, -123);
      _drawFuse(canvas);
      _drawBody(canvas);
    }
    canvas.restore();
  }

  Path get _body => Path()
    ..moveTo(100, 58)
    ..cubicTo(139, 56, 164, 83, 166, 121)
    ..cubicTo(169, 157, 143, 183, 104, 182)
    ..cubicTo(62, 183, 33, 158, 33, 124)
    ..cubicTo(31, 87, 60, 61, 100, 58)
    ..close();

  void _drawFuse(Canvas canvas) {
    // An off-centre cap and a little crooked fuse give the silhouette its wink.
    canvas.save();
    canvas.translate(111, 61);
    canvas.rotate(0.28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-15, -13, 30, 22),
        const Radius.circular(5),
      ),
      _fill(_ink),
    );
    canvas.drawLine(
      const Offset(-9, -6),
      const Offset(8, -6),
      _stroke(_paper, 2),
    );
    canvas.restore();

    final fuse = Path()
      ..moveTo(114, 47)
      ..cubicTo(116, 27, 129, 21, 139, 29)
      ..cubicTo(147, 36, 153, 32, 157, 22);
    canvas.drawPath(fuse, _stroke(_ink, 4));
    final spark = Offset(159, 19 + sway * 0.6);
    _drawSpark(canvas, spark, progress < 0.3 ? 14 : 11);
  }

  void _drawSpark(Canvas canvas, Offset center, double radius) {
    final paint = _stroke(sparkColor, 3.3);
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - 0.3;
      final vector = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + vector * (radius * 0.47),
        center + vector * radius,
        paint,
      );
    }
    canvas.drawCircle(center, 2.7, _fill(sparkColor));
  }

  void _drawBody(Canvas canvas) {
    canvas.drawPath(_body, _fill(_ink));
    final urgent = progress < 0.3;

    // Cream eyes, cut slightly differently: the character is intentionally
    // asymmetric without adding texture or tiny decoration.
    canvas.save();
    canvas.translate(79, 111);
    canvas.rotate(-0.1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: 21,
          height: urgent ? 30 : 27,
        ),
        const Radius.circular(11),
      ),
      _fill(_paper),
    );
    canvas.restore();
    canvas.save();
    canvas.translate(113, 108);
    canvas.rotate(0.1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: 22,
          height: urgent ? 32 : 29,
        ),
        const Radius.circular(11),
      ),
      _fill(_paper),
    );
    canvas.restore();

    final glance = urgent ? -1.0 : 2.0;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(80 + glance, 115), width: 7, height: 10),
      _fill(_ink),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(114 + glance, 112), width: 7, height: 10),
      _fill(_ink),
    );

    final mouth = Path();
    if (urgent) {
      mouth
        ..moveTo(89, 145)
        ..quadraticBezierTo(98, 135, 108, 144);
      canvas.drawPath(mouth, _stroke(_paper, 3.5));
      final brow = Path()
        ..moveTo(68, 86)
        ..lineTo(82, 83)
        ..moveTo(108, 80)
        ..lineTo(122, 82);
      canvas.drawPath(brow, _stroke(_paper, 3));
      final drop = Path()
        ..moveTo(147, 84)
        ..quadraticBezierTo(133, 101, 147, 103)
        ..quadraticBezierTo(158, 101, 147, 84);
      canvas.drawPath(drop, _fill(sparkColor));
    } else {
      mouth
        ..moveTo(87, 139)
        ..quadraticBezierTo(97, 150, 109, 137);
      canvas.drawPath(mouth, _stroke(_paper, 3.5));
      canvas.drawLine(
        const Offset(125, 127),
        const Offset(131, 125),
        _stroke(sparkColor, 4),
      );
    }

    // A pair of short, mismatched feet anchors the paper silhouette.
    canvas.drawLine(
      const Offset(75, 174),
      const Offset(67, 188),
      _stroke(_ink, 8),
    );
    canvas.drawLine(
      const Offset(124, 175),
      const Offset(133, 186),
      _stroke(_ink, 8),
    );
  }

  void _drawBurst(Canvas canvas) {
    const center = Offset(102, 106);
    const radii = <double>[87, 49, 92, 51, 86, 52, 83, 49, 91, 50, 84, 48];
    final burst = Path();
    for (var i = 0; i < radii.length; i++) {
      final angle = -math.pi / 2 + (i * math.pi * 2 / radii.length);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * radii[i];
      if (i == 0) {
        burst.moveTo(point.dx, point.dy);
      } else {
        burst.lineTo(point.dx, point.dy);
      }
    }
    burst.close();
    canvas.drawPath(burst, _fill(sparkColor));

    canvas.drawLine(
      const Offset(21, 41),
      const Offset(30, 52),
      _stroke(_ink, 4),
    );
    canvas.drawLine(
      const Offset(177, 49),
      const Offset(185, 41),
      _stroke(_ink, 4),
    );
    canvas.drawCircle(const Offset(178, 153), 3, _fill(_ink));
    canvas.drawCircle(const Offset(24, 158), 3, _fill(_ink));
  }

  void _drawBrokenBody(Canvas canvas) {
    final left = Path()
      ..moveTo(0, 0)
      ..lineTo(101, 0)
      ..lineTo(101, 75)
      ..lineTo(88, 103)
      ..lineTo(105, 122)
      ..lineTo(91, 145)
      ..lineTo(100, 164)
      ..lineTo(91, 200)
      ..lineTo(0, 200)
      ..close();
    final right = Path()
      ..moveTo(101, 0)
      ..lineTo(200, 0)
      ..lineTo(200, 200)
      ..lineTo(91, 200)
      ..lineTo(100, 164)
      ..lineTo(91, 145)
      ..lineTo(105, 122)
      ..lineTo(88, 103)
      ..lineTo(101, 75)
      ..close();

    for (var i = 0; i < 2; i++) {
      final isLeft = i == 0;
      canvas.save();
      canvas.translate(isLeft ? -6 : 6, isLeft ? -3 : 2);
      canvas.translate(100, 124);
      canvas.rotate(isLeft ? -0.10 : 0.10);
      canvas.translate(-100, -124);
      canvas.clipPath(isLeft ? left : right);
      _drawBody(canvas);
      canvas.restore();
    }

    // The cap is still recognisable, just airborne after the pop.
    canvas.save();
    canvas.translate(127, 39);
    canvas.rotate(0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12, -7, 24, 14),
        const Radius.circular(3),
      ),
      _fill(_ink),
    );
    canvas.drawLine(
      const Offset(1, -7),
      const Offset(6, -16),
      _stroke(_ink, 3),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BombPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.sway != sway ||
      oldDelegate.exploded != exploded ||
      oldDelegate.sparkColor != sparkColor;
}
