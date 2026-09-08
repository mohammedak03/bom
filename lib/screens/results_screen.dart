import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../services/match_persistence.dart';
import '../theme/game_theme.dart';
import '../widgets/game_ui.dart';
import 'setup_screen.dart';
import 'game_screen.dart';
import 'dart:math';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.gameState,
    this.random,
    this.nextStarter,
  });

  final GameState gameState;
  final Random? random;
  final int Function(int max)? nextStarter;
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _actionStarted = false;
  GameState get gameState => widget.gameState;

  void _newSettings(BuildContext context) {
    if (_actionStarted) return;
    _actionStarted = true;
    MatchPersistence().clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SetupScreen()),
      (route) => false,
    );
  }

  void _sameGroup(BuildContext context) {
    if (_actionStarted) return;
    setState(() => _actionStarted = true);
    final fresh = GameState(
      playerNames: gameState.playerNames,
      questionPool: gameState.questionPool,
      selectedPackageIds: gameState.selectedPackageIds,
      matchMode: gameState.matchMode,
      initialStarterIndex:
          widget.nextStarter?.call(gameState.playerNames.length) ??
          (widget.random ?? Random()).nextInt(gameState.playerNames.length),
      phase: GamePhase.playing,
    );
    MatchPersistence().clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => GameScreen(gameState: fresh)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final leaderboard = _leaderboardRows();
    final winners = leaderboard.isEmpty
        ? <_LeaderboardRow>[]
        : leaderboard
              .where((row) => row.lossPoints == leaderboard.first.lossPoints)
              .toList();
    final isTie = winners.length > 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GamePage(
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameButton(
              key: const ValueKey('same-group-replay'),
              label: 'نفس اللّمّة',
              onPressed: () => _sameGroup(context),
              icon: Icons.replay_rounded,
            ),
            const SizedBox(height: 10),
            GameButton(
              key: const ValueKey('new-settings'),
              label: 'إعدادات جديدة',
              onPressed: () => _newSettings(context),
              icon: Icons.tune_rounded,
              secondary: true,
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GameEyebrow(
                label: 'حصيلة السهرة',
                trailing: '${leaderboard.length} لاعبين',
              ),
              const SizedBox(height: 28),
              const Center(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    size: Size(132, 116),
                    painter: _TrophyPainter(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                winners.isEmpty
                    ? 'انتهت السهرة'
                    : isTie
                    ? 'الصدارة مشتركة'
                    : 'نجمتها اليوم',
                textAlign: TextAlign.center,
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              if (winners.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  winners.map((row) => row.name).join('، '),
                  textAlign: TextAlign.center,
                  style: textTheme.headlineLarge?.copyWith(
                    color: GamePalette.orange,
                    fontSize: isTie ? 26 : 38,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'الأقل انفجارات يكسب اللقب.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: GamePalette.muted),
              ),
              const SizedBox(height: 32),
              Text(
                '${_modeLabel(gameState.matchMode)} · ${gameState.totalRounds == null ? 'انتهت بعد الجولة ${gameState.currentRound}' : 'أُكملت ${gameState.currentRound} من ${gameState.totalRounds} جولات'}',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: GamePalette.muted),
              ),
              const SizedBox(height: 4),
              Text(
                'الإجابات المقبولة: ${gameState.answeredCount}',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: GamePalette.muted),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'الترتيب',
                        style: textTheme.labelLarge?.copyWith(
                          color: GamePalette.muted,
                        ),
                      ),
                    ),
                    Text(
                      'الانفجارات',
                      style: textTheme.labelLarge?.copyWith(
                        color: GamePalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: GamePalette.ink),
              for (var index = 0; index < leaderboard.length; index++)
                _LeaderboardTile(
                  rank:
                      leaderboard.indexWhere(
                        (row) =>
                            row.lossPoints == leaderboard[index].lossPoints,
                      ) +
                      1,
                  row: leaderboard[index],
                  isWinner:
                      leaderboard[index].lossPoints ==
                      leaderboard.first.lossPoints,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_LeaderboardRow> _leaderboardRows() {
    final rows = <_LeaderboardRow>[];
    for (var index = 0; index < gameState.playerNames.length; index++) {
      final name = gameState.playerNames[index].trim();
      rows.add(
        _LeaderboardRow(
          name: name.isEmpty ? 'اللاعب ${index + 1}' : name,
          lossPoints: index < gameState.lossPoints.length
              ? gameState.lossPoints[index]
              : 0,
          originalIndex: index,
        ),
      );
    }
    rows.sort((a, b) {
      final pointsComparison = a.lossPoints.compareTo(b.lossPoints);
      return pointsComparison != 0
          ? pointsComparison
          : a.originalIndex.compareTo(b.originalIndex);
    });
    return rows;
  }

  String _modeLabel(MatchMode mode) => switch (mode) {
    MatchMode.quick => 'سريعة',
    MatchMode.normal => 'عادية',
    MatchMode.open => 'مفتوحة',
  };
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.row,
    required this.isWinner,
  });

  final int rank;
  final _LeaderboardRow row;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label:
          'المركز $rank، ${row.name}، ${row.lossPoints} انفجارات'
          '${isWinner ? '، في الصدارة' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: GamePalette.line)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 27,
              child: Text(
                '$rank',
                style: textTheme.bodyMedium?.copyWith(color: GamePalette.muted),
              ),
            ),
            PlayerMark(index: row.originalIndex, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  if (isWinner) ...[
                    const SizedBox(height: 4),
                    Text(
                      'في الصدارة',
                      style: textTheme.labelSmall?.copyWith(
                        color: GamePalette.accentInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${row.lossPoints}',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isWinner ? GamePalette.orange : GamePalette.ink,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow {
  const _LeaderboardRow({
    required this.name,
    required this.lossPoints,
    required this.originalIndex,
  });

  final String name;
  final int lossPoints;
  final int originalIndex;
}

class _TrophyPainter extends CustomPainter {
  const _TrophyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 132, size.height / 116);
    final outline = Paint()
      ..color = GamePalette.ink
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final orange = Paint()..color = GamePalette.orange;
    final paper = Paint()..color = GamePalette.paper;

    canvas.drawCircle(
      const Offset(66, 57),
      48,
      Paint()..color = GamePalette.sage.withValues(alpha: 0.4),
    );
    final handles = Path()
      ..moveTo(40, 27)
      ..lineTo(28, 27)
      ..quadraticBezierTo(23, 55, 45, 57)
      ..moveTo(92, 27)
      ..lineTo(104, 27)
      ..quadraticBezierTo(109, 55, 87, 57);
    canvas.drawPath(handles, outline);

    final cup = Path()
      ..moveTo(40, 20)
      ..lineTo(92, 20)
      ..lineTo(87, 54)
      ..quadraticBezierTo(84, 70, 66, 71)
      ..quadraticBezierTo(48, 70, 45, 54)
      ..close();
    canvas.drawPath(cup, orange);
    canvas.drawPath(cup, outline);
    canvas.drawLine(const Offset(66, 72), const Offset(66, 87), outline);
    final base = RRect.fromRectAndRadius(
      const Rect.fromLTWH(49, 88, 34, 10),
      const Radius.circular(2),
    );
    canvas.drawRRect(base, paper);
    canvas.drawRRect(base, outline);

    final star = Path()
      ..moveTo(66, 32)
      ..lineTo(69, 40)
      ..lineTo(78, 41)
      ..lineTo(71, 47)
      ..lineTo(73, 56)
      ..lineTo(66, 51)
      ..lineTo(59, 56)
      ..lineTo(61, 47)
      ..lineTo(54, 41)
      ..lineTo(63, 40)
      ..close();
    canvas.drawPath(star, paper);
    canvas.drawLine(const Offset(14, 12), const Offset(20, 19), outline);
    canvas.drawLine(const Offset(10, 27), const Offset(17, 29), outline);
    canvas.drawLine(const Offset(111, 11), const Offset(106, 18), outline);
    canvas.drawLine(const Offset(115, 23), const Offset(122, 21), outline);
    canvas.drawLine(const Offset(108, 82), const Offset(108, 94), outline);
    canvas.drawLine(const Offset(102, 88), const Offset(114, 88), outline);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrophyPainter oldDelegate) => false;
}
