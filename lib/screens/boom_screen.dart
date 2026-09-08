import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../services/match_persistence.dart';
import '../theme/game_theme.dart';
import '../widgets/bomb_widget.dart';
import '../widgets/game_ui.dart';
import 'game_screen.dart';
import 'results_screen.dart';
import 'setup_screen.dart';

class BoomScreen extends StatefulWidget {
  const BoomScreen({super.key, required this.gameState});

  final GameState gameState;

  @override
  State<BoomScreen> createState() => _BoomScreenState();
}

class _BoomScreenState extends State<BoomScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entrance;
  bool _actionStarted = false;
  bool _exitDialogOpen = false;
  final MatchPersistence _persistence = MatchPersistence();

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    )..forward();
    _entrance = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _startNewRound() {
    if (_actionStarted) return;
    setState(() => _actionStarted = true);
    widget.gameState.startNextRound();
    widget.gameState.phase = GamePhase.playing;
    _persistence.save(widget.gameState);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(gameState: widget.gameState),
      ),
    );
  }

  void _showResults() {
    if (_actionStarted) return;
    setState(() => _actionStarted = true);
    widget.gameState.phase = GamePhase.results;
    _persistence.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(gameState: widget.gameState),
      ),
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

  String get _loserName {
    final names = widget.gameState.playerNames;
    if (names.isEmpty) return 'اللاعب';
    final index = widget.gameState.currentPlayerIndex % names.length;
    final name = names[index].trim();
    return name.isEmpty ? 'اللاعب ${index + 1}' : name;
  }

  int get _loserLossPoints {
    final index = widget.gameState.currentPlayerIndex;
    final points = widget.gameState.lossPoints;
    return index >= 0 && index < points.length ? points[index] : 0;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _confirmExit(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: GamePage(
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GameButton(
                label: 'جولة كمان',
                onPressed: _actionStarted ? null : _startNewRound,
                icon: Icons.replay_rounded,
              ),
              const SizedBox(height: 10),
              GameButton(
                label: 'النتائج',
                onPressed: _actionStarted ? null : _showResults,
                icon: Icons.format_list_numbered_rounded,
                secondary: true,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 38)
                        .clamp(0.0, double.infinity)
                        .toDouble(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const GameEyebrow(
                        label: 'انتهت الجولة',
                        trailing: 'بــــوم!',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            ScaleTransition(
                              scale: MediaQuery.disableAnimationsOf(context)
                                  ? const AlwaysStoppedAnimation<double>(1)
                                  : _entrance,
                              child: const BombWidget(
                                progress: 0,
                                size: 190,
                                animate: false,
                                exploded: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'راحت عليك!',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 44,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              _loserName,
                              textAlign: TextAlign.center,
                              style: textTheme.headlineLarge?.copyWith(
                                color: GamePalette.orange,
                                fontSize: 34,
                                height: 1.25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'القنبلة اختارتك هالمرة.\nلسّه في مجال تردّها!',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyLarge?.copyWith(
                                color: GamePalette.muted,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: GamePalette.line),
                            bottom: BorderSide(color: GamePalette.line),
                          ),
                        ),
                        child: Row(
                          children: [
                            PlayerMark(
                              index: widget.gameState.currentPlayerIndex,
                              size: 38,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'رصيدك من الانفجارات',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: GamePalette.muted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$_loserLossPoints',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
