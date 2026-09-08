import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

import 'screens/setup_screen.dart';
import 'screens/game_screen.dart';
import 'screens/boom_screen.dart';
import 'services/match_persistence.dart';
import 'models/game_state.dart';
import 'theme/game_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const BombQuestionsApp());
}

class BombQuestionsApp extends StatelessWidget {
  const BombQuestionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'قنبلة الأسئلة',
      debugShowCheckedModeBanner: false,
      theme: GameTheme.light,
      home: const _RestoreGate(),
    );
  }
}

class _RestoreGate extends StatefulWidget {
  const _RestoreGate();

  @override
  State<_RestoreGate> createState() => _RestoreGateState();
}

class _RestoreGateState extends State<_RestoreGate> {
  final MatchPersistence _persistence = MatchPersistence();
  GameState? _restored;
  bool _prompted = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    _restored = await _persistence.restore();
    if (mounted) setState(() {});
  }

  Future<void> _chooseRestore() async {
    final state = _restored;
    if (state == null) return;
    final continueMatch = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('في مباراة غير مكتملة'),
        content: const Text('بدكم تكملوا من مكان ما وقفتوا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ابدأ من جديد'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (continueMatch == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => state.phase == GamePhase.boom
              ? BoomScreen(gameState: state)
              : GameScreen(gameState: state),
        ),
      );
    } else {
      await _persistence.clear();
      if (mounted) setState(() => _restored = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_restored != null && !_prompted) {
      _prompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _restored != null) _chooseRestore();
      });
    }
    return const SetupScreen();
  }
}
