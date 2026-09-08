import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/setup_screen.dart';
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
      home: const SetupScreen(),
    );
  }
}
