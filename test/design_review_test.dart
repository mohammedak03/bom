import 'package:bomb_questions/models/game_state.dart';
import 'package:bomb_questions/screens/boom_screen.dart';
import 'package:bomb_questions/screens/game_screen.dart';
import 'package:bomb_questions/screens/packages_screen.dart';
import 'package:bomb_questions/screens/results_screen.dart';
import 'package:bomb_questions/screens/setup_screen.dart';
import 'package:bomb_questions/theme/game_theme.dart';
import 'package:bomb_questions/widgets/timer_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events',
      'xyz.luan/audioplayers/events/bomb_tick_player',
      'xyz.luan/audioplayers/events/bomb_effect_player',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        if (call.method == 'setSourceBytes') {
          final id = (call.arguments as Map)['playerId'];
          await messenger.handlePlatformMessage(
            'xyz.luan/audioplayers/events/$id',
            const StandardMethodCodec().encodeSuccessEnvelope({
              'event': 'audio.onPrepared',
              'value': true,
            }),
            (_) {},
          );
        }
        return call.method == 'getCurrentPosition' ||
                call.method == 'getDuration'
            ? 0
            : null;
      },
    );
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    testWidgets('all redesigned screens fit ${size.width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = GameState(
        playerNames: ['محمد', 'أحمد', 'عمر'],
        lossPoints: [2, 0, 1],
        currentRound: 4,
        answeredCount: 12,
      );
      final screens = <String, Widget>{
        'setup': const SetupScreen(),
        'packages': const PackagesScreen(playerNames: ['محمد', 'أحمد']),
        'game': GameScreen(gameState: state),
        'boom': BoomScreen(gameState: state),
        'results': ResultsScreen(gameState: state),
      };
      for (final screen in screens.entries) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(screen.key),
            theme: GameTheme.light,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: screen.value,
          ),
        );
        await tester.runAsync(() => GoogleFonts.pendingFonts());
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.key} at $size',
        );
        if (screen.key == 'game') {
          expect(find.byType(TimerBar).hitTestable(), findsOneWidget);
          expect(
            find.byKey(const ValueKey('answer-question')).hitTestable(),
            findsOneWidget,
          );
        }
        if (const bool.fromEnvironment('RENDER_DESIGN')) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              '../design-review/new-${screen.key}-${size.width.toInt()}.png',
            ),
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });
  }

  testWidgets(
    'eight players, keyboard, large text and long names remain usable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      Widget app(Widget screen) => MaterialApp(
        theme: GameTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.6),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: screen,
      );
      await tester.pumpWidget(app(const SetupScreen()));
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byKey(const ValueKey('add-player')));
        await tester.pump();
      }
      expect(find.byType(TextField), findsNWidgets(8));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      await tester.ensureVisible(find.byType(TextField).last);
      await tester.enterText(
        find.byType(TextField).last,
        'محمد عبد الرحمن الطويل',
      );
      expect(
        find.byKey(const ValueKey('start-game')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      tester.testTextInput.hide();
      final state = GameState(
        playerNames: List.generate(8, (i) => 'محمد عبد الرحمن الطويل ${i + 1}'),
        lossPoints: List.filled(8, 0),
      );
      for (final screen in [
        const PackagesScreen(playerNames: ['محمد', 'أحمد']),
        GameScreen(gameState: state),
        BoomScreen(gameState: state),
        ResultsScreen(gameState: state),
      ]) {
        await tester.pumpWidget(app(screen));
        await tester.runAsync(() => GoogleFonts.pendingFonts());
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.runtimeType} with enlarged text',
        );
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -1500),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    },
  );
}
