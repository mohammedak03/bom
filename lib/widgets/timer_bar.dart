import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

class TimerBar extends StatelessWidget {
  const TimerBar({super.key, required this.progress, this.height = 7});

  final double progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final color = _colorForProgress(clampedProgress);

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(color: GamePalette.line),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 100),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * clampedProgress,
                    height: height,
                    decoration: BoxDecoration(color: color),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _colorForProgress(double progress) {
    return progress < .3 ? GamePalette.orange : GamePalette.ink;
  }
}
