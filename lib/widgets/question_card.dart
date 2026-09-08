import 'package:flutter/material.dart';

import '../models/question.dart';
import '../theme/game_theme.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.question, this.compact = false});

  final Question question;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 230 : 280),
      padding: EdgeInsets.all(compact ? 22 : 28),
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: GamePalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GamePalette.ink, width: 1.3),
        boxShadow: const [
          BoxShadow(color: GamePalette.ink, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: GamePalette.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                question.category,
                style: const TextStyle(
                  fontSize: 14,
                  color: GamePalette.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.question_mark_rounded,
                color: GamePalette.line,
                size: 24,
              ),
            ],
          ),
          SizedBox(height: compact ? 24 : 32),
          Text(
            question.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 27 : 31,
              color: GamePalette.ink,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          SizedBox(height: compact ? 24 : 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic_none_rounded, size: 16, color: GamePalette.muted),
              SizedBox(width: 5),
              Text(
                'جاوب بصوت عالي',
                style: TextStyle(color: GamePalette.muted, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
