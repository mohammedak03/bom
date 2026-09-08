import 'package:flutter/material.dart';

import '../data/question_packages.dart';
import '../models/package_selection.dart';
import '../models/game_state.dart';
import '../services/rewarded_ad_service.dart';
import '../theme/game_theme.dart';
import '../widgets/bomb_widget.dart';
import '../widgets/game_ui.dart';
import '../widgets/settings_sheet.dart';
import 'packages_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _playerCount = 2;
  MatchMode _matchMode = MatchMode.normal;
  bool _starting = false;
  final _nameControllers = List.generate(8, (_) => TextEditingController());
  final _packages = PackageSelection(
    packages: questionPackages,
    ads: AdMobRewardedAdService(),
  );

  @override
  void dispose() {
    _packages.dispose();
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _startGame() async {
    if (_starting) return;
    _starting = true;
    FocusScope.of(context).unfocus();
    final names = List.generate(_playerCount, (index) {
      final name = _nameControllers[index].text.trim();
      return name.isEmpty ? 'اللاعب ${index + 1}' : name;
    });
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PackagesScreen(
          playerNames: names,
          matchMode: _matchMode,
          selection: _packages,
        ),
      ),
    );
    if (mounted) _starting = false;
  }

  void _showRules() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GamePalette.paper,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'سهلة… بس بدها سرعة.',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                for (final rule in [
                  (
                    '01',
                    'جاوب بصوت عالي',
                    'السؤال يظل معك لحد ما المجموعة تقبل الإجابة.',
                  ),
                  (
                    '02',
                    'جاوبت؟ مرّرها',
                    'الجواب المقبول فقط يمرّر الدور ويغيّر السؤال.',
                  ),
                  (
                    '03',
                    'تخطٍّ واحد وانتبه للقنبلة!',
                    'التخطّي يبدّل السؤال ويبقي الدور عليك؛ والأقل خسائر يفوز.',
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.$1,
                          style: const TextStyle(
                            color: GamePalette.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rule.$2,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                rule.$3,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: GamePalette.muted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                GameButton(
                  label: 'وصلت، يلا!',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return GamePage(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameButton(
            key: const ValueKey('start-game'),
            label: 'نختار المواضيع',
            onPressed: _startGame,
          ),
          if (!keyboardOpen) ...[
            const SizedBox(height: 12),
            const Text(
              'موبايل واحد. والكل داخل باللعبة.',
              style: TextStyle(fontSize: 13, color: GamePalette.muted),
            ),
          ],
        ],
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: GameEyebrow(label: 'قنبلة الأسئلة')),
                IconButton(
                  onPressed: () => showGameSettingsSheet(context),
                  tooltip: 'الإعدادات',
                  icon: const Icon(Icons.settings_outlined, size: 23),
                ),
                IconButton(
                  onPressed: _showRules,
                  tooltip: 'كيف نلعب؟',
                  icon: const Icon(Icons.help_outline_rounded, size: 23),
                ),
              ],
            ),
            if (!keyboardOpen) ...[
              const SizedBox(height: 16),
              const _WelcomePoster(),
              const SizedBox(height: 30),
            ] else
              const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مين باللمّة؟',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'من 2 إلى 8 لاعبين',
                        style: TextStyle(
                          fontSize: 13,
                          color: GamePalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: GamePalette.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const ValueKey('add-player'),
                        tooltip: 'إضافة لاعب',
                        onPressed: _playerCount < 8
                            ? () => setState(() => _playerCount++)
                            : null,
                        icon: const Icon(Icons.add_rounded, size: 21),
                      ),
                      Semantics(
                        label: 'عدد اللاعبين',
                        value: '$_playerCount',
                        liveRegion: true,
                        child: SizedBox(
                          width: 22,
                          child: Text(
                            '$_playerCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('remove-player'),
                        tooltip: 'إزالة لاعب',
                        onPressed: _playerCount > 2
                            ? () => setState(() => _playerCount--)
                            : null,
                        icon: const Icon(Icons.remove_rounded, size: 21),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            for (var index = 0; index < _playerCount; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    PlayerMark(index: index, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _nameControllers[index],
                        textInputAction: index == _playerCount - 1
                            ? TextInputAction.done
                            : TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'اسم اللاعب ${index + 1}',
                          labelText: 'اسم اللاعب ${index + 1}',
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                        onSubmitted: index == _playerCount - 1
                            ? (_) => FocusScope.of(context).unfocus()
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'الأسماء اختيارية، الحماس إجباري.',
                style: TextStyle(fontSize: 13, color: GamePalette.muted),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'طول المباراة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final mode in MatchMode.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ChoiceChip(
                  label: Text(
                    '${switch (mode) {
                      MatchMode.quick => 'سريعة',
                      MatchMode.normal => 'عادية',
                      MatchMode.open => 'مفتوحة',
                    }} — ${switch (mode) {
                      MatchMode.quick => 'جولة لكل لاعب',
                      MatchMode.normal => 'جولتان لكل لاعب',
                      MatchMode.open => 'أنهِ النتائج وقت ما تحبّوا',
                    }}',
                  ),
                  selected: _matchMode == mode,
                  onSelected: (_) => setState(() => _matchMode = mode),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePoster extends StatelessWidget {
  const _WelcomePoster();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 320;
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          decoration: BoxDecoration(
            color: GamePalette.orange,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: GamePalette.ink.withValues(alpha: .5),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'لعبة اللمّة',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Flexible(
                    child: Text(
                      'جاهزين؟',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'جاوبها.\nومرّرها.',
                      style: TextStyle(
                        fontSize: compact ? 36 : 44,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                        letterSpacing: -1.3,
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: -.12,
                    child: BombWidget(
                      progress: 1,
                      size: compact ? 100 : 132,
                      animate: false,
                      sparkColor: GamePalette.paper,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'السؤال عليك. والقنبلة ما بتستنى.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
  }
}
