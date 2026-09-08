import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../theme/game_theme.dart';
import '../widgets/game_ui.dart';

import '../models/game_state.dart';
import '../models/question.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../widgets/bomb_widget.dart';
import '../widgets/question_card.dart';
import '../widgets/timer_bar.dart';
import 'boom_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.gameState});

  final GameState gameState;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Random _random = Random();
  final AudioService _audioService = AudioService();
  final HapticService _hapticService = HapticService();

  Timer? _timer;
  late DateTime _timerStartedAt;
  late Duration _timerDuration;
  late Question _currentQuestion;

  double _progress = 1;
  bool _timerEnded = false;
  bool _tickingSpedUp = false;

  @override
  void initState() {
    super.initState();
    _currentQuestion = _randomQuestion();
    _audioService.startTicking();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_audioService.stopTicking());
    super.dispose();
  }

  void _startTimer() {
    _timerStartedAt = DateTime.now();
    _timerDuration = Duration(seconds: 20 + _random.nextInt(41));
    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateTimerProgress(),
    );
  }

  void _updateTimerProgress() {
    final elapsed = DateTime.now().difference(_timerStartedAt);
    final nextProgress =
        1 - (elapsed.inMilliseconds / _timerDuration.inMilliseconds);

    if (nextProgress <= 0) {
      _timer?.cancel();
      _timerEnded = true;
      widget.gameState.recordLoss();
      unawaited(_audioService.playExplosion());
      unawaited(_hapticService.heavyExplosion());

      if (mounted) {
        setState(() {
          _progress = 0;
        });
        _goToBoomScreen();
      }
      return;
    }

    final clampedProgress = nextProgress.clamp(0.0, 1.0).toDouble();
    if (clampedProgress < 0.3 && !_tickingSpedUp) {
      _tickingSpedUp = true;
      _audioService.speedUpTicking();
    }

    if (mounted) {
      setState(() {
        _progress = clampedProgress;
      });
    }
  }

  void _goToBoomScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BoomScreen(gameState: widget.gameState),
      ),
    );
  }

  void _answerQuestion() {
    if (_timerEnded) {
      return;
    }

    unawaited(_audioService.playSuccess());
    unawaited(_hapticService.lightTap());

    setState(() {
      widget.gameState.nextPlayer();
      _currentQuestion = _randomQuestion(previousQuestion: _currentQuestion);
    });
  }

  Question _randomQuestion({Question? previousQuestion}) {
    final questions = widget.gameState.questionPool;
    if (questions.length == 1) {
      return questions.first;
    }

    Question nextQuestion;
    do {
      nextQuestion = questions[_random.nextInt(questions.length)];
    } while (nextQuestion == previousQuestion);

    return nextQuestion;
  }

  String get _currentPlayerName {
    final playerNames = widget.gameState.playerNames;
    if (playerNames.isEmpty) {
      return 'اللاعب';
    }

    final currentIndex =
        widget.gameState.currentPlayerIndex % playerNames.length;
    final playerName = playerNames[currentIndex].trim();

    if (playerName.isEmpty) {
      return 'اللاعب ${currentIndex + 1}';
    }

    return playerName;
  }

  @override
  Widget build(BuildContext context) {
    final urgent = _progress < .3;
    final playerCount = widget.gameState.playerNames.length;
    final nextPlayer = playerCount == 0
        ? 'اللاعب التالي'
        : widget.gameState.playerNames[(widget.gameState.currentPlayerIndex +
                  1) %
              playerCount];
    return GamePage(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: urgent ? 'الوقت أوشك على الانتهاء' : 'الوقت المتبقي',
            child: TimerBar(progress: _progress),
          ),
          const SizedBox(height: 18),
          GameButton(
            key: const ValueKey('answer-question'),
            label: 'جاوبت، مرّرها',
            onPressed: _answerQuestion,
            icon: Icons.west_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            'بعدك: $nextPlayer',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: GamePalette.muted),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 620;
          final shortScreen = constraints.maxHeight < 520;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, shortScreen ? 20 : 28, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameEyebrow(
                  label: 'قنبلة الأسئلة',
                  trailing: 'سؤال ${widget.gameState.answeredCount + 1}',
                ),
                SizedBox(
                  height: shortScreen
                      ? 14
                      : compact
                      ? 22
                      : 32,
                ),
                Row(
                  children: [
                    if (shortScreen)
                      BombWidget(progress: _progress, size: 48)
                    else
                      PlayerMark(
                        index: widget.gameState.currentPlayerIndex,
                        size: 48,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الدور عليك يا',
                            style: TextStyle(
                              fontSize: 13,
                              color: GamePalette.muted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _currentPlayerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: GamePalette.sage.withValues(alpha: .35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.gameState.currentPlayerIndex + 1} / $playerCount',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: shortScreen
                      ? 14
                      : compact
                      ? 22
                      : 32,
                ),
                QuestionCard(question: _currentQuestion, compact: compact),
                if (!shortScreen) ...[
                  SizedBox(height: compact ? 16 : 26),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              urgent ? 'مرّرها… بسرعة!' : 'تك… تك…',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: urgent
                                    ? GamePalette.orange
                                    : GamePalette.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              urgent
                                  ? 'القنبلة على آخرها.'
                                  : 'خليك جاهز، ما بتستنى حدا.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: GamePalette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      BombWidget(progress: _progress, size: compact ? 86 : 105),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
