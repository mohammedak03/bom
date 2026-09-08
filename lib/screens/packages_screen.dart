import 'package:flutter/material.dart';
import 'dart:math';

import '../data/question_packages.dart';
import '../models/game_state.dart';
import '../models/package_selection.dart';
import '../models/question_package.dart';
import '../services/rewarded_ad_service.dart';
import '../theme/game_theme.dart';
import '../widgets/game_ui.dart';
import 'game_screen.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({
    super.key,
    required this.playerNames,
    this.matchMode = MatchMode.normal,
    this.ads,
    this.selection,
  });

  final List<String> playerNames;
  final MatchMode matchMode;
  final RewardedAdGateway? ads;
  final PackageSelection? selection;

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  late final PackageSelection _selection;
  late final bool _ownsSelection;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _ownsSelection = widget.selection == null;
    _selection =
        widget.selection ??
        PackageSelection(
          packages: questionPackages,
          ads: widget.ads ?? AdMobRewardedAdService(),
        );
  }

  @override
  void dispose() {
    if (_ownsSelection) _selection.dispose();
    super.dispose();
  }

  void _startGame() {
    if (_starting || !_selection.canStart || _selection.isBusy) return;
    setState(() => _starting = true);
    final starter = Random().nextInt(widget.playerNames.length);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          gameState: GameState(
            playerNames: widget.playerNames,
            currentPlayerIndex: starter,
            initialStarterIndex: starter,
            phase: GamePhase.playing,
            matchMode: widget.matchMode,
            questionPool: _selection.selectedQuestions,
            selectedPackageIds: _selection.selectedIds.toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _choosePackage(QuestionPackage package) async {
    if (_selection.isBusy || _starting) return;
    if (_selection.isAccessible(package)) {
      _selection.toggle(package.id);
      return;
    }

    final watchAd = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: GamePalette.paper,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _SheetBody(
        children: [
          _TopicMark(packageId: package.id, size: 58),
          const SizedBox(height: 20),
          Text(
            package.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            package.description,
            style: const TextStyle(
              fontSize: 16,
              color: GamePalette.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${package.questions.length} سؤال للّمة',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          const Text(
            'إعلان واحد يفتح هالباكيج لهاللعبة، بكل جولاتها.',
            style: TextStyle(fontSize: 17, height: 1.5),
          ),
          const SizedBox(height: 18),
          GameButton(
            key: ValueKey('watch-ad-${package.id}'),
            label: 'شاهد إعلان وافتحها',
            icon: Icons.play_arrow_rounded,
            onPressed: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: 10),
          const Text(
            'الإعلان في هالنسخة تجريبي.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: GamePalette.muted),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('خلّيني أختار غيرها'),
          ),
        ],
      ),
    );

    if (watchAd != true || !mounted || _selection.isBusy) return;
    final outcome = await _selection.unlockWithAd(package.id);
    if (!mounted) return;
    final message = switch (outcome) {
      RewardOutcome.earned => '${package.name} انفتحت وانضافت لاختياركم!',
      RewardOutcome.dismissed =>
        'الإعلان تسكّر قبل ما يكتمل. الباكيج لسه مقفول.',
      RewardOutcome.unavailable =>
        'الإعلان مش متاح هسا. جرّب كمان شوي، أو بلّش بالمجاني.',
      RewardOutcome.busy => 'في إعلان عم يجهز، استنّى شوي.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSubscription() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GamePalette.paper,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _SheetBody(
        children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Icon(
              Icons.workspace_premium_outlined,
              size: 44,
              color: GamePalette.accentInk,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'اشتراك اللمّة',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'كل المواضيع، على مزاجكم.',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          const _SubscriptionBenefit(label: 'كل الباكيجات مفتوحة'),
          const SizedBox(height: 14),
          const _SubscriptionBenefit(label: 'اختاروا واخلطوا بدون إعلانات فتح'),
          const SizedBox(height: 24),
          const Text(
            'الاشتراك لسه مش متاح. حاليًا افتح الباكيجات بإعلان.',
            style: TextStyle(
              fontSize: 16,
              color: GamePalette.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GameButton(
            label: 'رجعني للمواضيع',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _selection,
      builder: (context, _) => PopScope(
        canPop: !_selection.isBusy && !_starting,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              GamePage(
                bottom: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _selection.selectedIds.isEmpty
                          ? 'اختاروا باكيج واحد على الأقل'
                          : '${_selection.selectedIds.length} باكيج مختار · '
                                '${_selection.selectedQuestionCount} سؤال',
                      key: const ValueKey('package-selection-summary'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: GamePalette.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GameButton(
                      key: const ValueKey('start-selected-game'),
                      label: 'يلا نلعب',
                      onPressed:
                          _selection.canStart &&
                              !_selection.isBusy &&
                              !_starting
                          ? _startGame
                          : null,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: GameEyebrow(label: 'مواضيع اللمّة'),
                          ),
                          IconButton(
                            key: const ValueKey('packages-back'),
                            tooltip: 'الرجوع للاعبين',
                            onPressed: _selection.isBusy || _starting
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_forward_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'شو جوّ اللمّة؟',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'اختاروا موضوع… أو اخلطوها.',
                        style: TextStyle(
                          fontSize: 16,
                          color: GamePalette.muted,
                        ),
                      ),
                      const SizedBox(height: 26),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final singleColumn =
                              constraints.maxWidth < 300 ||
                              MediaQuery.textScalerOf(context).scale(16) > 20;
                          final packages = _selection.packages;
                          return Column(
                            children: [
                              for (
                                var index = 0;
                                index < packages.length;
                                index += singleColumn ? 1 : 2
                              )
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: singleColumn
                                      ? _buildCard(packages[index])
                                      : IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                child: _buildCard(
                                                  packages[index],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child:
                                                    index + 1 < packages.length
                                                    ? _buildCard(
                                                        packages[index + 1],
                                                      )
                                                    : const SizedBox.shrink(),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        key: const ValueKey('subscription-preview'),
                        onPressed: _showSubscription,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.workspace_premium_outlined, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'كل الباكيجات باشتراك',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'قريبًا',
                              style: TextStyle(
                                fontSize: 12,
                                color: GamePalette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selection.isBusy)
                const Positioned.fill(child: _AdLoadingOverlay()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(QuestionPackage package) => _PackageCard(
    key: ValueKey('package-${package.id}'),
    package: package,
    selected: _selection.selectedIds.contains(package.id),
    accessible: _selection.isAccessible(package),
    onTap: () => _choosePackage(package),
  );
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    super.key,
    required this.package,
    required this.selected,
    required this.accessible,
    required this.onTap,
  });

  final QuestionPackage package;
  final bool selected;
  final bool accessible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = package.isFree
        ? 'مجاني'
        : accessible
        ? 'مفتوح لهاللعبة'
        : 'يفتح بإعلان';
    return Semantics(
      button: true,
      onTap: onTap,
      selected: selected,
      label: '${package.name}، $status، ${package.questions.length} سؤال',
      hint: accessible
          ? selected
                ? 'إلغاء الاختيار'
                : 'إضافة إلى اللعبة'
          : 'عرض طريقة فتح الباكيج',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? _topicColor(package.id).withValues(alpha: .28)
            : GamePalette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21),
          side: BorderSide(
            color: selected ? GamePalette.ink : GamePalette.line,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _TopicMark(packageId: package.id),
                    const Spacer(),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : accessible
                          ? Icons.radio_button_unchecked_rounded
                          : Icons.lock_outline_rounded,
                      size: 22,
                      color: selected ? GamePalette.ink : GamePalette.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Text(
                  package.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  package.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GamePalette.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  '${package.questions.length} سؤال',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accessible ? GamePalette.ink : GamePalette.accentInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicMark extends StatelessWidget {
  const _TopicMark({required this.packageId, this.size = 44});

  final String packageId;
  final double size;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _topicColor(packageId),
        borderRadius: BorderRadius.circular(size * .32),
      ),
      child: Icon(
        switch (packageId) {
          'countries' => Icons.public_rounded,
          'football' => Icons.sports_soccer_rounded,
          'screen' => Icons.movie_outlined,
          'food' => Icons.restaurant_rounded,
          'science' => Icons.science_outlined,
          _ => Icons.lightbulb_outline_rounded,
        },
        color: GamePalette.ink,
        size: size * .56,
      ),
    ),
  );
}

Color _topicColor(String id) => switch (id) {
  'countries' => const Color(0xFFF2BA8C),
  'football' => const Color(0xFFBEC8A8),
  'screen' => const Color(0xFFCDC4DF),
  'food' => const Color(0xFFE8CD78),
  'science' => const Color(0xFFB9D3CD),
  _ => const Color(0xFFECC5B5),
};

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

class _SubscriptionBenefit extends StatelessWidget {
  const _SubscriptionBenefit({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.check_rounded, size: 21, color: GamePalette.accentInk),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 17))),
    ],
  );
}

class _AdLoadingOverlay extends StatelessWidget {
  const _AdLoadingOverlay();

  @override
  Widget build(BuildContext context) => BlockSemantics(
    child: Material(
      color: GamePalette.paper.withValues(alpha: .96),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: GamePalette.orange),
                const SizedBox(height: 24),
                const Text(
                  'لحظة، بنجهّز الإعلان…',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'كمّله للآخر عشان ينفتح الباكيج.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: GamePalette.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
