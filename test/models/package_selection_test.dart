import 'dart:async';

import 'package:bomb_questions/data/question_packages.dart';
import 'package:bomb_questions/models/game_state.dart';
import 'package:bomb_questions/models/package_selection.dart';
import 'package:bomb_questions/services/rewarded_ad_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeRewardedAds implements RewardedAdGateway {
  final response = Completer<RewardOutcome>();
  int calls = 0;
  bool disposed = false;
  @override
  Future<RewardOutcome> show() {
    calls++;
    return response.future;
  }

  @override
  void dispose() {
    disposed = true;
  }
}

void main() {
  late FakeRewardedAds ads;
  late PackageSelection selection;
  setUp(() {
    ads = FakeRewardedAds();
    selection = PackageSelection(packages: questionPackages, ads: ads);
  });

  test('default game is free, offline and contains no locked packages', () {
    expect(selection.selectedIds, {'general'});
    expect(selection.canStart, isTrue);
    expect(ads.calls, 0);
    expect(
      GameState(playerNames: ['A', 'B']).questionPool.every(
        (q) => {'general', 'countries'}.contains(q.packageId),
      ),
      isTrue,
    );
    selection.dispose();
  });

  test('multiple free packages mix and removing all blocks start', () {
    selection.toggle('countries');
    expect(selection.selectedQuestions.map((q) => q.packageId).toSet(), {
      'general',
      'countries',
    });
    selection.toggle('general');
    selection.toggle('countries');
    expect(selection.canStart, isFalse);
    expect(selection.selectedQuestionCount, 0);
    selection.dispose();
  });

  test(
    'earned access survives a new selection for the next 24 hours',
    () async {
      SharedPreferences.setMockInitialValues({});
      final firstAds = FakeRewardedAds();
      final first = PackageSelection(packages: questionPackages, ads: firstAds);
      final pending = first.unlockWithAd('football');
      firstAds.response.complete(RewardOutcome.earned);
      await pending;
      first.dispose();

      final second = PackageSelection(
        packages: questionPackages,
        ads: FakeRewardedAds(),
      );
      await second.loadPersistentUnlocks();
      expect(second.unlockedIds, {'football'});
      second.dispose();
    },
  );

  test('locked and unknown package IDs cannot be selected', () {
    selection.toggle('football');
    selection.toggle('missing');
    expect(selection.selectedIds, {'general'});
    expect(
      selection.selectedQuestions.any((q) => q.packageId == 'football'),
      isFalse,
    );
    selection.dispose();
  });

  for (final outcome in [RewardOutcome.dismissed, RewardOutcome.unavailable]) {
    test('$outcome never grants or selects a locked package', () async {
      final pending = selection.unlockWithAd('football');
      expect(selection.canStart, isFalse);
      ads.response.complete(outcome);
      expect(await pending, outcome);
      expect(selection.isBusy, isFalse);
      expect(selection.unlockedIds, isEmpty);
      expect(selection.selectedIds, {'general'});
      selection.dispose();
    });
  }

  test(
    'earned reward unlocks only its package; match keeps immutable questions across rounds',
    () async {
      final pending = selection.unlockWithAd('football');
      ads.response.complete(RewardOutcome.earned);
      expect(await pending, RewardOutcome.earned);
      expect(selection.unlockedIds, {'football'});
      expect(selection.selectedIds, {'general', 'football'});
      selection.toggle('general');
      final state = GameState(
        playerNames: ['A', 'B'],
        questionPool: selection.selectedQuestions,
      );
      selection.toggle('football');
      selection.dispose();
      expect(
        state.questionPool.every((q) => q.packageId == 'football'),
        isTrue,
      );
      state.recordLoss();
      state.phase = GamePhase.playing;
      state.nextPlayer();
      expect(
        state.questionPool.every((q) => q.packageId == 'football'),
        isTrue,
      );
      expect(() => state.questionPool.clear(), throwsUnsupportedError);
    },
  );

  test(
    'concurrent unlocks do not request a second ad or allow selection changes',
    () async {
      final pending = selection.unlockWithAd('football');
      expect(await selection.unlockWithAd('screen'), RewardOutcome.busy);
      selection.toggle('countries');
      expect(selection.selectedIds, {'general'});
      expect(ads.calls, 1);
      ads.response.complete(RewardOutcome.earned);
      await pending;
      selection.dispose();
    },
  );

  test('returning a late reward after leaving cannot grant access', () async {
    final pending = selection.unlockWithAd('football');
    selection.dispose();
    ads.response.complete(RewardOutcome.earned);
    expect(await pending, RewardOutcome.unavailable);
    expect(selection.unlockedIds, isEmpty);
    expect(ads.disposed, isTrue);
  });

  test('ad failure is recoverable and never unlocks content', () async {
    final pending = selection.unlockWithAd('screen');
    ads.response.completeError(StateError('no network'));
    expect(await pending, RewardOutcome.unavailable);
    expect(selection.isBusy, isFalse);
    expect(selection.unlockedIds, isEmpty);
    selection.dispose();
  });

  test(
    'new match needs a new reward and an empty question pool is rejected',
    () async {
      final pending = selection.unlockWithAd('football');
      ads.response.complete(RewardOutcome.earned);
      await pending;
      selection.dispose();
      final next = PackageSelection(
        packages: questionPackages,
        ads: FakeRewardedAds(),
      );
      expect(next.unlockedIds, isEmpty);
      expect(next.selectedIds, {'general'});
      expect(
        () => GameState(playerNames: ['A', 'B'], questionPool: []),
        throwsArgumentError,
      );
      next.dispose();
    },
  );
}
