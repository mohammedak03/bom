import 'dart:async';

import 'package:bomb_questions/data/question_packages.dart';
import 'package:bomb_questions/models/package_selection.dart';
import 'package:bomb_questions/screens/packages_screen.dart';
import 'package:bomb_questions/services/rewarded_ad_service.dart';
import 'package:bomb_questions/theme/game_theme.dart';
import 'package:bomb_questions/widgets/game_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('free topics can be mixed and an empty selection disables start', (
    tester,
  ) async {
    final fixture = await _pumpPackages(tester);

    expect(fixture.selection.selectedIds, {'general'});
    expect(_startButton(tester).onPressed, isNotNull);
    await _tapCard(tester, 'countries');

    expect(fixture.selection.selectedIds, {'general', 'countries'});
    final combinedCount = questionPackages
        .where((package) => package.isFree)
        .fold(0, (count, package) => count + package.questions.length);
    expect(
      find.text('2 باكيج مختار · $combinedCount سؤال'),
      findsOneWidget,
    );
    expect(_cardSemantics(tester, 'countries').properties.selected, isTrue);

    await _tapCard(tester, 'general');
    await _tapCard(tester, 'countries');

    expect(fixture.selection.selectedIds, isEmpty);
    expect(find.text('اختاروا باكيج واحد على الأقل'), findsOneWidget);
    expect(_startButton(tester).onPressed, isNull);
    expect(_cardSemantics(tester, 'countries').properties.selected, isFalse);
    expect(fixture.ads.showCalls, 0);
  });

  testWidgets('opening or dismissing a locked topic never starts an ad', (
    tester,
  ) async {
    final fixture = await _pumpPackages(tester);
    await _tapCard(tester, 'football');

    expect(find.byKey(const ValueKey('watch-ad-football')), findsOneWidget);
    expect(
      find.text('إعلان واحد يفتح هالباكيج لهاللعبة، بكل جولاتها.'),
      findsOneWidget,
    );
    expect(find.text('الإعلان في هالنسخة تجريبي.'), findsOneWidget);
    expect(fixture.ads.showCalls, 0);
    expect(fixture.selection.unlockedIds, isEmpty);

    final dismiss = find.text('خلّيني أختار غيرها');
    await tester.ensureVisible(dismiss);
    await tester.tap(dismiss);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('watch-ad-football')), findsNothing);
    expect(fixture.ads.showCalls, 0);
    expect(fixture.selection.unlockedIds, isEmpty);
    expect(fixture.selection.selectedIds, {'general'});
  });

  testWidgets('only an earned reward opens and selects the requested topic', (
    tester,
  ) async {
    final fixture = await _pumpPackages(tester);
    await _beginAd(tester, 'football');

    expect(fixture.ads.showCalls, 1);
    expect(fixture.selection.isBusy, isTrue);
    expect(fixture.selection.unlockedIds, isEmpty);
    expect(fixture.selection.selectedIds, {'general'});
    expect(_startButton(tester).onPressed, isNull);
    expect(find.text('لحظة، بنجهّز الإعلان…'), findsOneWidget);
    final popScope = tester.widget<PopScope>(
      find.descendant(
        of: find.byType(PackagesScreen),
        matching: find.byType(PopScope),
      ),
    );
    expect(popScope.canPop, isFalse);

    fixture.ads.complete(RewardOutcome.earned);
    await tester.pumpAndSettle();

    expect(fixture.selection.isBusy, isFalse);
    expect(fixture.selection.unlockedIds, {'football'});
    expect(fixture.selection.selectedIds, {'general', 'football'});
    expect(_cardSemantics(tester, 'football').properties.selected, isTrue);
    expect(_startButton(tester).onPressed, isNotNull);
    expect(find.text('لحظة، بنجهّز الإعلان…'), findsNothing);
    for (final package in questionPackages.where(
      (package) => !package.isFree && package.id != 'football',
    )) {
      expect(fixture.selection.isAccessible(package), isFalse);
    }
  });

  for (final outcome in [RewardOutcome.dismissed, RewardOutcome.unavailable]) {
    testWidgets('$outcome keeps access locked and permits another attempt', (
      tester,
    ) async {
      final fixture = await _pumpPackages(tester);
      await _beginAd(tester, 'football');
      fixture.ads.complete(outcome);
      await tester.pumpAndSettle();

      expect(fixture.selection.isBusy, isFalse);
      expect(fixture.selection.unlockedIds, isEmpty);
      expect(fixture.selection.selectedIds, {'general'});
      expect(_startButton(tester).onPressed, isNotNull);
      expect(
        find.text(
          outcome == RewardOutcome.dismissed
              ? 'الإعلان تسكّر قبل ما يكتمل. الباكيج لسه مقفول.'
              : 'الإعلان مش متاح هسا. جرّب كمان شوي، أو بلّش بالمجاني.',
        ),
        findsOneWidget,
      );

      await _beginAd(tester, 'football');
      expect(fixture.ads.showCalls, 2);
      fixture.ads.complete(RewardOutcome.earned);
      await tester.pumpAndSettle();

      expect(fixture.selection.unlockedIds, {'football'});
      expect(fixture.selection.selectedIds, {'general', 'football'});
    });
  }

  testWidgets('subscription preview states unavailability and grants no access', (
    tester,
  ) async {
    final fixture = await _pumpPackages(tester);
    final preview = find.byKey(const ValueKey('subscription-preview'));
    await tester.ensureVisible(preview);
    await tester.tap(preview);
    await tester.pumpAndSettle();

    expect(find.text('اشتراك اللمّة'), findsOneWidget);
    expect(
      find.text('الاشتراك لسه مش متاح. حاليًا افتح الباكيجات بإعلان.'),
      findsOneWidget,
    );
    expect(fixture.selection.unlockedIds, isEmpty);
    expect(fixture.ads.showCalls, 0);
    final sheetButtons = tester.widgetList<GameButton>(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(GameButton),
      ),
    );
    expect(sheetButtons.map((button) => button.label), ['رجعني للمواضيع']);

    final close = find.text('رجعني للمواضيع');
    await tester.ensureVisible(close);
    await tester.tap(close);
    await tester.pumpAndSettle();

    expect(find.text('اشتراك اللمّة'), findsNothing);
    expect(fixture.selection.selectedIds, {'general'});
    expect(fixture.selection.unlockedIds, isEmpty);
  });

  testWidgets('external selection and rewards survive going back and reopening', (
    tester,
  ) async {
    final fixture = await _pumpPackages(tester, withBackRoute: true);
    await _tapCard(tester, 'countries');
    await _beginAd(tester, 'football');
    fixture.ads.complete(RewardOutcome.earned);
    await tester.pumpAndSettle();

    final back = find.byKey(const ValueKey('packages-back'));
    await tester.ensureVisible(back);
    await tester.tap(back);
    await tester.pumpAndSettle();

    expect(find.byType(PackagesScreen), findsNothing);
    expect(fixture.ads.disposeCalls, 0);
    expect(fixture.selection.unlockedIds, {'football'});
    await tester.tap(find.byKey(const ValueKey('open-packages')));
    await tester.pumpAndSettle();

    expect(fixture.selection.selectedIds, {'general', 'countries', 'football'});
    expect(_cardSemantics(tester, 'countries').properties.selected, isTrue);
    await tester.ensureVisible(find.byKey(const ValueKey('package-football')));
    expect(_cardSemantics(tester, 'football').properties.selected, isTrue);
    expect(fixture.ads.showCalls, 1);
    expect(fixture.ads.disposeCalls, 0);

    await _tapCard(tester, 'football');
    expect(fixture.selection.selectedIds, {'general', 'countries'});
    expect(fixture.selection.unlockedIds, {'football'});
    expect(fixture.ads.showCalls, 1);
  });
}

Future<_Fixture> _pumpPackages(
  WidgetTester tester, {
  bool withBackRoute = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final ads = _FakeRewardedAdGateway();
  final selection = PackageSelection(packages: questionPackages, ads: ads);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    selection.dispose();
  });

  Widget packagesScreen() => PackagesScreen(
    playerNames: const ['محمد', 'سارة'],
    selection: selection,
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: GameTheme.light,
      home: withBackRoute
          ? Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    key: const ValueKey('open-packages'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => packagesScreen(),
                      ),
                    ),
                    child: const Text('المواضيع'),
                  ),
                ),
              ),
            )
          : packagesScreen(),
    ),
  );
  if (withBackRoute) {
    await tester.tap(find.byKey(const ValueKey('open-packages')));
    await tester.pump();
  }
  await tester.runAsync(() => GoogleFonts.pendingFonts());
  await tester.pumpAndSettle();
  return _Fixture(selection, ads);
}

Future<void> _tapCard(WidgetTester tester, String id) async {
  final card = find.byKey(ValueKey('package-$id'));
  await tester.ensureVisible(card);
  await tester.tap(card);
  await tester.pumpAndSettle();
}

Future<void> _beginAd(WidgetTester tester, String id) async {
  await _tapCard(tester, id);
  final watch = find.byKey(ValueKey('watch-ad-$id'));
  await tester.ensureVisible(watch);
  await tester.tap(watch);
  // The loading spinner deliberately stays active until the fake ad completes.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

FilledButton _startButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.descendant(
    of: find.byKey(const ValueKey('start-selected-game')),
    matching: find.byType(FilledButton),
  ),
);

Semantics _cardSemantics(WidgetTester tester, String id) =>
    tester.widget<Semantics>(
      find.descendant(
        of: find.byKey(ValueKey('package-$id')),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.selected != null,
        ),
      ),
    );

class _Fixture {
  const _Fixture(this.selection, this.ads);

  final PackageSelection selection;
  final _FakeRewardedAdGateway ads;
}

class _FakeRewardedAdGateway implements RewardedAdGateway {
  Completer<RewardOutcome>? _pending;
  int showCalls = 0;
  int disposeCalls = 0;

  @override
  Future<RewardOutcome> show() {
    showCalls++;
    if (_pending != null) return Future.value(RewardOutcome.busy);
    _pending = Completer<RewardOutcome>();
    return _pending!.future;
  }

  void complete(RewardOutcome outcome) {
    final pending = _pending!;
    _pending = null;
    pending.complete(outcome);
  }

  @override
  void dispose() {
    disposeCalls++;
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) {
      pending.complete(RewardOutcome.unavailable);
    }
  }
}
