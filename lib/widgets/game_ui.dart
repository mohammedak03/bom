import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

class GamePage extends StatelessWidget {
  const GamePage({
    super.key,
    required this.child,
    this.bottom,
    this.backgroundColor = GamePalette.paper,
  });

  final Widget child;
  final Widget? bottom;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: child),
                  if (bottom != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                      child: bottom,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.west_rounded,
    this.secondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: secondary ? Colors.transparent : GamePalette.ink,
          foregroundColor: secondary ? GamePalette.ink : GamePalette.paper,
          disabledBackgroundColor: GamePalette.line,
          disabledForegroundColor: GamePalette.muted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: secondary
                ? const BorderSide(color: GamePalette.line)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: secondary
                    ? Colors.transparent
                    : onPressed == null
                    ? GamePalette.line
                    : GamePalette.orange,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: GamePalette.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class GameEyebrow extends StatelessWidget {
  const GameEyebrow({super.key, required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _SmallSpark(),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              fontSize: 12,
              color: GamePalette.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _SmallSpark extends StatelessWidget {
  const _SmallSpark();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size.square(18), painter: _SparkPainter());
}

class _SparkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GamePalette.orange
      ..strokeWidth = 2.7
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 4;
      final delta = Offset(math.cos(angle), math.sin(angle)) * 7;
      canvas.drawLine(
        size.center(Offset.zero) - delta,
        size.center(Offset.zero) + delta,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => false;
}

class PlayerMark extends StatelessWidget {
  const PlayerMark({super.key, required this.index, this.size = 40});

  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _PlayerPainter(index),
      ),
    );
  }
}

class _PlayerPainter extends CustomPainter {
  const _PlayerPainter(this.index);
  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 40, size.height / 40);
    const colors = [
      GamePalette.sage,
      Color(0xFFF2BA8C),
      Color(0xFFCDC4DF),
      Color(0xFFE8CD78),
    ];
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(1, 1, 38, 38),
        Radius.circular(index.isEven ? 13 : 19),
      ),
      Paint()..color = colors[index % colors.length],
    );
    final ink = Paint()
      ..color = GamePalette.ink
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final x in [14.0, 25.0]) {
      canvas.drawLine(Offset(x, 15), Offset(x, 18), ink);
    }
    canvas.drawArc(
      const Rect.fromLTWH(15, 17, 10, 10),
      .15,
      math.pi - .3,
      false,
      ink,
    );
    if (index % 3 == 2) {
      canvas.drawLine(const Offset(11, 13), const Offset(17, 12), ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlayerPainter oldDelegate) =>
      oldDelegate.index != index;
}
