import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../theme/game_theme.dart';
import '../widgets/game_ui.dart';

import '../models/game_state.dart';
import '../models/question.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/match_persistence.dart';
import '../widgets/bomb_widget.dart';
import '../widgets/question_card.dart';
import '../widgets/timer_bar.dart';
import 'boom_screen.dart';
import 'setup_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.gameState,
    this.elapsedTime,
    this.timerDuration,
    this.enableAudio = true,
  });

  final GameState gameState;

  /// A monotonic clock seam used only by deterministic widget tests.
  final Duration Function()? elapsedTime;
  final Duration? timerDuration;
  final bool enableAudio;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final Random _random = Random();
  final AudioService _audioService = AudioService();
  final HapticService _hapticService = HapticService();
  final MatchPersistence _persistence = MatchPersistence();

  Timer? _timer;
  late final Stopwatch _stopwatch;
  late Duration _timerDuration;
  late Question _currentQuestion;

  double _progress = 1;
  bool _roundEnded = false;
  bool _navigationStarted = false;
  bool _tickingSpedUp = false;
  Duration? _lastActionAt;
  bool _paused = false;
  bool _countingDown = false;
  int _countdown = 3;
  bool _exitDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stopwatch = Stopwatch()..start();
    _currentQuestion =
        widget.gameState.questionById(widget.gameState.currentQuestionId) ??
        widget.gameState.nextQuestion();
    if (widget.enableAudio) {
      _audioService.startTicking();
    }
    _startTimer();
    unawaited(_persistence.save(widget.gameState));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    if (widget.enableAudio) {
      unawaited(_audioService.stopTicking());
    }
    super.dispose();
  }

  void _startTimer() {
    _timerDuration =
        widget.timerDuration ?? Duration(seconds: 20 + _random.nextInt(41));
    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateTimerProgress(),
    );
  }

  void _updateTimerProgress() {
    if (_paused || _countingDown || _roundEnded) return;
    final elapsed = _elapsed;
    final nextProgress =
        1 - (elapsed.inMilliseconds / _timerDuration.inMilliseconds);

    if (nextProgress <= 0) {
      _endRound();
      return;
    }

    final clampedProgress = nextProgress.clamp(0.0, 1.0).toDouble();
    if (clampedProgress < 0.3 && !_tickingSpedUp) {
      _tickingSpedUp = true;
      if (widget.enableAudio) {
        _audioService.speedUpTicking();
      }
    }

    if (mounted) {
      setState(() {
        _progress = clampedProgress;
      });
    }
  }

  void _goToBoomScreen() {
    if (_navigationStarted || !mounted) return;
    _navigationStarted = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BoomScreen(gameState: widget.gameState),
      ),
    );
  }

  void _answerQuestion() {
    if (_paused || _countingDown) return;
    final now = _elapsed;
    // The deadline wins even if the periodic callback has not run yet.
    if (now >= _timerDuration) {
      _endRound();
      return;
    }
    if (_roundEnded ||
        (_lastActionAt != null &&
            now - _lastActionAt! < const Duration(milliseconds: 400))) {
      return;
    }

    _lastActionAt = now;

    if (widget.enableAudio) {
      unawaited(_audioService.playSuccess());
    }
    unawaited(_hapticService.lightTap());

    setState(() {
      widget.gameState.nextPlayer();
      _currentQuestion = widget.gameState.nextQuestion();
    });
    unawaited(_persistence.save(widget.gameState));
  }

  void _skipQuestion() {
    if (_paused || _countingDown) return;
    final now = _elapsed;
    if (now >= _timerDuration) {
      _endRound();
      return;
    }
    if (_roundEnded ||
        !widget.gameState.canSkipCurrentPlayer() ||
        (_lastActionAt != null &&
            now - _lastActionAt! < const Duration(milliseconds: 400))) {
      return;
    }
    _lastActionAt = now;
    setState(() {
      widget.gameState.useSkip();
      _currentQuestion = widget.gameState.nextQuestion();
    });
    unawaited(_persistence.save(widget.gameState));
  }

  Duration get _elapsed => widget.elapsedTime?.call() ?? _stopwatch.elapsed;

  void _endRound() {
    if (_roundEnded) return;
    _roundEnded = true;
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    widget.gameState.recordLoss();
    unawaited(_persistence.save(widget.gameState));
    if (widget.enableAudio) {
      unawaited(_audioService.playExplosion());
    }
    unawaited(_hapticService.heavyExplosion());

    if (!mounted) return;
    setState(() => _progress = 0);
    _goToBoomScreen();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _pauseForInterruption();
    }
  }

  void _pauseForInterruption() {
    if (_paused || _roundEnded || _countingDown) return;
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
    if (widget.enableAudio) unawaited(_audioService.stopTicking());
    if (mounted) setState(() => _paused = true);
  }

  Future<void> _continueAfterPause() async {
    if (!_paused || _countingDown || _roundEnded) return;
    setState(() {
      _countingDown = true;
      _countdown = 3;
    });
    for (var value = 3; value >= 1; value--) {
      if (!mounted || !_countingDown) return;
      setState(() => _countdown = value);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted || !_countingDown || _roundEnded) return;
    setState(() {
      _paused = false;
      _countingDown = false;
    });
    _stopwatch.start();
    if (widget.enableAudio) _audioService.startTicking();
    _timer ??= Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateTimerProgress(),
    );
  }

  Future<void> _confirmExit() async {
    if (_exitDialogOpen || !mounted) return;
    _exitDialogOpen = true;
    final leave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('إنهاء المباراة؟'),
        content: const Text('مباراة القنبلة ما زالت مستمرة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('كمّل اللعب'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('أنهِ المباراة'),
          ),
        ],
      ),
    );
    _exitDialogOpen = false;
    if (leave == true && mounted) {
      await _persistence.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const SetupScreen()),
        (route) => false,
      );
    }
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _confirmExit(),
      child: Stack(
        children: [
          GamePage(
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
                const SizedBox(height: 10),
                GameButton(
                  key: const ValueKey('skip-question'),
                  label: widget.gameState.canSkipCurrentPlayer()
                      ? 'تخطّي السؤال (متاح)'
                      : 'تخطّي السؤال (استخدمته)',
                  onPressed: widget.gameState.canSkipCurrentPlayer()
                      ? _skipQuestion
                      : null,
                  icon: Icons.skip_next_rounded,
                  secondary: true,
                ),
                const SizedBox(height: 12),
                Text(
                  'بعدك: $nextPlayer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GamePalette.muted,
                  ),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 620;
                final shortScreen = constraints.maxHeight < 520;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    shortScreen ? 20 : 28,
                    24,
                    12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GameEyebrow(
                        label: 'قنبلة الأسئلة',
                        trailing: 'سؤال ${widget.gameState.answeredCount + 1}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.gameState.totalRounds == null
                            ? 'الجولة ${widget.gameState.currentRound}'
                            : 'الجولة ${widget.gameState.currentRound} من ${widget.gameState.totalRounds}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: GamePalette.muted,
                        ),
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
                      QuestionCard(
                        question: _currentQuestion,
                        compact: compact,
                      ),
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
                            BombWidget(
                              progress: _progress,
                              size: compact ? 86 : 105,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          if (_paused || _countingDown)
            Positioned.fill(
              child: Material(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: _countingDown
                          ? Text(
                              '$_countdown',
                              style: const TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'اللعبة متوقفة مؤقتاً',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _continueAfterPause,
                                  child: const Text('متابعة'),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
