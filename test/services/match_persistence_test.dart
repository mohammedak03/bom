import 'dart:convert';

import 'package:bomb_questions/models/game_state.dart';
import 'package:bomb_questions/services/match_persistence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'persists and restores an unfinished playing match from package ids',
    () async {
      final storage = MatchPersistence();
      final state = GameState(
        playerNames: ['Ali', 'Sara'],
        lossPoints: [1, 2],
        currentPlayerIndex: 1,
        currentRound: 3,
        answeredCount: 7,
        phase: GamePhase.playing,
        selectedPackageIds: ['countries'],
      );
      await storage.save(state);
      final restored = await storage.restore();
      expect(restored, isNotNull);
      expect(restored!.phase, GamePhase.playing);
      expect(restored.playerNames, state.playerNames);
      expect(restored.lossPoints, state.lossPoints);
      expect(restored.currentRound, 3);
      expect(restored.questionPool, isNotEmpty);
    },
  );

  test('persists boom without adding a second loss', () async {
    final storage = MatchPersistence();
    final state = GameState(
      playerNames: ['Ali', 'Sara'],
      lossPoints: [0, 1],
      phase: GamePhase.boom,
      selectedPackageIds: ['countries'],
    );
    await storage.save(state);
    final restored = await storage.restore();
    expect(restored!.phase, GamePhase.boom);
    expect(restored.lossPoints, [0, 1]);
  });

  test('corrupt and obsolete snapshots are cleared safely', () async {
    SharedPreferences.setMockInitialValues({
      'unfinished_match_v1': jsonEncode({'version': 99}),
    });
    final storage = MatchPersistence();
    expect(await storage.restore(), isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('unfinished_match_v1'), isFalse);
  });

  test('clearing a completed or ended match removes its snapshot', () async {
    final storage = MatchPersistence();
    await storage.save(
      GameState(
        playerNames: ['Ali', 'Sara'],
        phase: GamePhase.playing,
        selectedPackageIds: ['countries'],
      ),
    );
    await storage.clear();
    expect(await storage.restore(), isNull);
  });
}
