import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/question.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/match_persistence.dart';
import '../services/settings_service.dart';
import '../theme/game_theme.dart';
import '../widgets/bomb_widget.dart';
import '../widgets/game_ui.dart';
import '../widgets/question_card.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/timer_bar.dart';
import 'boom_screen.dart';
import 'setup_screen.dart';

enum GameAudioRequest { ticking, success, explosion }

enum GameHapticRequest { lightTap, explosion }

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.gameState,
    this.elapsedTime,
    this.timerDuration,
    this.enableAudio = true,
    this.countdownDelay = const Duration(seconds: 1),
    this.audioService,
    this.hapticService,
    this.timerDisplayModeOverride,
    this.settingsOverride,
    this.startImmediatelyForTesting = true,
    this.onAudioRequest,
    this.onHapticRequest,
  });
  final GameState gameState;
  final Duration Function()? elapsedTime;
  final Duration? timerDuration;
  final bool enableAudio;
  final Duration countdownDelay;
  final AudioService? audioService;
  final HapticService? hapticService;
  final TimerDisplayMode? timerDisplayModeOverride;
  final GameSettings? settingsOverride;
  final bool startImmediatelyForTesting;
  final void Function(GameAudioRequest request)? onAudioRequest;
  final void Function(GameHapticRequest request)? onHapticRequest;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final _random = Random(),
      _persistence = MatchPersistence(),
      _settingsService = SettingsService();
  late final AudioService _audio;
  late final HapticService _haptic;
  Timer? _timer;
  late final Stopwatch _stopwatch;
  late final Duration _timerDuration;
  late Question _question;
  GameSettings _settings = const GameSettings();
  double _progress = 1;
  bool _ready = true,
      _paused = false,
      _countingDown = false,
      _ended = false,
      _navigating = false,
      _spedUp = false;
  int _countdown = 3, _generation = 0;
  Duration? _lastAction;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audio = widget.audioService ?? AudioService();
    _haptic = widget.hapticService ?? HapticService();
    _stopwatch = Stopwatch();
    _timerDuration =
        widget.timerDuration ?? Duration(seconds: 20 + _random.nextInt(41));
    _question =
        widget.gameState.questionById(widget.gameState.currentQuestionId) ??
        widget.gameState.questionPool.first;
    widget.gameState.phase = GamePhase.playing;
    _settings = widget.settingsOverride ?? _settings;
    if (widget.elapsedTime != null && widget.startImmediatelyForTesting) {
      _ready = false;
      _question =
          widget.gameState.questionById(widget.gameState.currentQuestionId) ??
          widget.gameState.nextQuestion();
      _stopwatch.start();
      _timer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _update(),
      );
      if (_sound) {
        widget.onAudioRequest?.call(GameAudioRequest.ticking);
        _audio.startTicking();
      }
    }
    unawaited(_persistence.save(widget.gameState));
    if (widget.settingsOverride == null) {
      unawaited(_loadSettings());
    }
  }

  Future<void> _loadSettings() async {
    final v = await _settingsService.load();
    if (mounted) setState(() => _settings = v);
  }

  bool get _sound => widget.enableAudio && _settings.soundEnabled;
  bool get _vibration => _settings.vibrationEnabled;
  bool get _mystery =>
      (widget.timerDisplayModeOverride ?? _settings.timerDisplayMode) ==
      TimerDisplayMode.mystery;
  Duration get _elapsed => widget.elapsedTime?.call() ?? _stopwatch.elapsed;
  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_sound) unawaited(_audio.stopTicking());
    super.dispose();
  }

  void _update() {
    if (_ready || _paused || _countingDown || _ended) return;
    final p = 1 - _elapsed.inMilliseconds / _timerDuration.inMilliseconds;
    if (p <= 0) return _end();
    final v = p.clamp(0.0, 1.0).toDouble();
    if (v < .3 && !_spedUp) {
      _spedUp = true;
      if (_sound) _audio.speedUpTicking();
    }
    if (mounted) setState(() => _progress = v);
  }

  Future<void> _count() async {
    final id = ++_generation;
    setState(() {
      _countingDown = true;
      _countdown = 3;
    });
    for (var n = 3; n >= 1; n--) {
      if (!mounted || id != _generation) return;
      setState(() => _countdown = n);
      await Future<void>.delayed(widget.countdownDelay);
    }
    if (!mounted || id != _generation || _ended) return;
    setState(() {
      _ready = false;
      _paused = false;
      _countingDown = false;
      _question =
          widget.gameState.questionById(widget.gameState.currentQuestionId) ??
          widget.gameState.nextQuestion();
    });
    _stopwatch.start();
    _timer ??= Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _update(),
    );
    if (_sound) {
      widget.onAudioRequest?.call(GameAudioRequest.ticking);
      _audio.startTicking();
    }
  }

  void _pause({bool ready = false}) {
    if (_ended) {
      return;
    }
    _generation++;
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    if (_sound) {
      unawaited(_audio.stopTicking());
    }
    if (mounted) {
      setState(() {
        _countingDown = false;
        _ready = ready || _ready;
        _paused = !ready && !_ready;
      });
    }
  }

  void _answer() {
    if (_ready || _paused || _countingDown || _ended) {
      return;
    }
    if (_elapsed >= _timerDuration) {
      return _end();
    }
    if (_lastAction != null &&
        _elapsed - _lastAction! < const Duration(milliseconds: 400)) {
      return;
    }
    _lastAction = _elapsed;
    if (_sound) {
      widget.onAudioRequest?.call(GameAudioRequest.success);
      unawaited(_audio.playSuccess());
    }
    if (_vibration) {
      widget.onHapticRequest?.call(GameHapticRequest.lightTap);
      unawaited(_haptic.lightTap());
    }
    setState(() {
      widget.gameState.nextPlayer();
      _question = widget.gameState.nextQuestion();
    });
    unawaited(_persistence.save(widget.gameState));
  }

  void _skip() {
    if (_ready ||
        _paused ||
        _countingDown ||
        _ended ||
        !widget.gameState.canSkipCurrentPlayer()) {
      return;
    }
    if (_elapsed >= _timerDuration) {
      return _end();
    }
    if (_lastAction != null &&
        _elapsed - _lastAction! < const Duration(milliseconds: 400)) {
      return;
    }
    _lastAction = _elapsed;
    setState(() {
      widget.gameState.useSkip();
      _question = widget.gameState.nextQuestion();
    });
    unawaited(_persistence.save(widget.gameState));
  }

  void _end() {
    if (_ended) {
      return;
    }
    _ended = true;
    _timer?.cancel();
    _stopwatch.stop();
    widget.gameState.recordLoss();
    unawaited(_persistence.save(widget.gameState));
    if (_sound) {
      widget.onAudioRequest?.call(GameAudioRequest.explosion);
      unawaited(_audio.playExplosion());
    }
    if (_vibration) {
      widget.onHapticRequest?.call(GameHapticRequest.explosion);
      unawaited(_haptic.heavyExplosion());
    }
    if (mounted) {
      setState(() => _progress = 0);
    }
    if (!_navigating && mounted) {
      _navigating = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BoomScreen(gameState: widget.gameState),
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.inactive ||
        s == AppLifecycleState.paused ||
        s == AppLifecycleState.hidden ||
        s == AppLifecycleState.detached) {
      _pause(ready: _ready || _countingDown);
    }
  }

  Future<void> _openSettings() async {
    if (!_ready && !_paused) {
      _pause();
    }
    await showGameSettingsSheet(context);
    if (!mounted) {
      return;
    }
    await _loadSettings();
  }

  String get _player {
    final a = widget.gameState.playerNames;
    if (a.isEmpty) return 'اللاعب';
    final x = a[widget.gameState.currentPlayerIndex % a.length].trim();
    return x.isEmpty ? 'اللاعب ${widget.gameState.currentPlayerIndex + 1}' : x;
  }

  @override
  Widget build(BuildContext context) {
    final active = !_ready && !_paused && !_countingDown;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) async {
        await _persistence.clear();
        if (!context.mounted) {
          return;
        }
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const SetupScreen()),
            (_) => false,
          );
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            GamePage(
              bottom: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_mystery)
                    Semantics(
                      label: 'شريط الوقت المتبقي',
                      child: TimerBar(progress: _mystery ? 1 : _progress),
                    )
                  else
                    Semantics(label: 'المؤقت غامض', child: SizedBox(height: 7)),
                  const SizedBox(height: 16),
                  GameButton(
                    key: const ValueKey('answer-question'),
                    label: 'جاوبت، مرّرها',
                    onPressed: active ? _answer : null,
                    icon: Icons.west_rounded,
                  ),
                  const SizedBox(height: 10),
                  GameButton(
                    key: const ValueKey('skip-question'),
                    label: 'تخطّي السؤال',
                    onPressed: active && widget.gameState.canSkipCurrentPlayer()
                        ? _skip
                        : null,
                    icon: Icons.skip_next_rounded,
                    secondary: true,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GameEyebrow(
                      label: 'قنبلة الأسئلة',
                      trailing: 'سؤال ${widget.gameState.answeredCount + 1}',
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: IconButton(
                        key: const ValueKey('game-settings'),
                        tooltip: 'الإعدادات',
                        onPressed: _openSettings,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ),
                    Text(
                      widget.gameState.totalRounds == null
                          ? 'الجولة ${widget.gameState.currentRound}'
                          : 'الجولة ${widget.gameState.currentRound} من ${widget.gameState.totalRounds}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: GamePalette.muted),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        BombWidget(
                          progress: _mystery ? 1 : _progress,
                          size: 72,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'الدور عليك يا\n$_player',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    QuestionCard(question: _question),
                    const SizedBox(height: 24),
                    Text(
                      _mystery
                          ? 'تك… تك… خليك جاهز.'
                          : (_progress < .3 ? 'مرّرها… بسرعة!' : 'تك… تك…'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_ready || _paused || _countingDown)
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
                                semanticsLabel: 'العد التنازلي $_countdown',
                                style: const TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _ready
                                        ? 'جاهز يا $_player؟'
                                        : 'اللعبة متوقفة مؤقتاً',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    widget.gameState.totalRounds == null
                                        ? 'الجولة ${widget.gameState.currentRound}'
                                        : 'الجولة ${widget.gameState.currentRound} من ${widget.gameState.totalRounds}',
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    key: const ValueKey('start-round'),
                                    onPressed: _ready ? _count : _count,
                                    child: Text(
                                      _ready ? 'جاهز، ابدأ الجولة' : 'متابعة',
                                    ),
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
      ),
    );
  }
}
