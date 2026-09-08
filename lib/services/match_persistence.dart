import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/question_packages.dart';
import '../models/game_state.dart';

class MatchPersistence {
  static const _key = 'unfinished_match_v1';
  static const _version = 1;

  Future<void> save(GameState state) async {
    if (state.phase != GamePhase.playing && state.phase != GamePhase.boom) {
      await clear();
      return;
    }
    final snapshot = <String, Object>{
      'version': _version,
      'players': state.playerNames,
      'losses': state.lossPoints,
      'player': state.currentPlayerIndex,
      'round': state.currentRound,
      'answered': state.answeredCount,
      'phase': state.phase.name,
      'packages': state.selectedPackageIds,
    };
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(snapshot));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }

  Future<GameState?> restore() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['version'] != _version) {
        await clear();
        return null;
      }
      final players = _strings(decoded['players']);
      final losses = _ints(decoded['losses']);
      final ids = _strings(decoded['packages']);
      final phase = switch (decoded['phase']) {
        'playing' => GamePhase.playing,
        'boom' => GamePhase.boom,
        _ => throw const FormatException('unfinished phase required'),
      };
      if (players.length < 2 ||
          players.length != losses.length ||
          ids.isEmpty) {
        throw const FormatException('invalid match dimensions');
      }
      final byId = {
        for (final package in questionPackages) package.id: package,
      };
      if (ids.any((id) => !byId.containsKey(id))) {
        throw const FormatException('unknown package');
      }
      final pool = [for (final id in ids) ...byId[id]!.questions];
      final player = _int(decoded['player']);
      final round = _int(decoded['round']);
      final answered = _int(decoded['answered']);
      if (player < 0 || player >= players.length || round < 1 || answered < 0) {
        throw const FormatException('invalid counters');
      }
      return GameState(
        playerNames: players,
        lossPoints: losses,
        currentPlayerIndex: player,
        currentRound: round,
        answeredCount: answered,
        phase: phase,
        questionPool: pool,
        selectedPackageIds: ids,
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  List<String> _strings(Object? value) => value is List
      ? value
            .map((item) {
              if (item is! String) throw const FormatException('string list');
              return item;
            })
            .toList(growable: false)
      : throw const FormatException('list required');

  List<int> _ints(Object? value) => value is List
      ? value.map(_int).toList(growable: false)
      : throw const FormatException('list required');

  int _int(Object? value) =>
      value is int ? value : throw const FormatException('integer required');
}
