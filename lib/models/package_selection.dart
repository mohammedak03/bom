import 'package:flutter/foundation.dart';

import '../services/rewarded_ad_service.dart';
import '../services/package_unlock_store.dart';
import 'question.dart';
import 'question_package.dart';

/// Access earned here lasts for this match only. A new selection session starts
/// locked again; GameState owns an immutable snapshot once the match starts.
class PackageSelection extends ChangeNotifier {
  PackageSelection({
    required List<QuestionPackage> packages,
    required RewardedAdGateway ads,
    PackageUnlockStore? unlockStore,
  }) : packages = List.unmodifiable(packages),
       _ads = ads,
       _unlockStore = unlockStore ?? PackageUnlockStore() {
    final freePackages = this.packages.where(
      (package) => package.isFree && package.questions.isNotEmpty,
    );
    if (freePackages.isNotEmpty) _selectedIds.add(freePackages.first.id);
  }

  final List<QuestionPackage> packages;
  final RewardedAdGateway _ads;
  final PackageUnlockStore _unlockStore;
  final Set<String> _selectedIds = {};
  final Set<String> _unlockedIds = {};
  bool _isBusy = false;
  bool _disposed = false;

  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  Set<String> get unlockedIds => Set.unmodifiable(_unlockedIds);
  bool get isBusy => _isBusy;
  int get selectedQuestionCount => selectedQuestions.length;
  bool get canStart => !_isBusy && selectedQuestions.isNotEmpty;

  Future<void> loadPersistentUnlocks() async {
    if (_disposed) return;
    final ids = await _unlockStore.activeIds();
    if (_disposed) return;
    final known = packages.map((package) => package.id).toSet();
    _unlockedIds.addAll(ids.where(known.contains));
    notifyListeners();
  }

  bool isAccessible(QuestionPackage package) =>
      package.isFree || _unlockedIds.contains(package.id);

  List<Question> get selectedQuestions => List.unmodifiable(
    packages
        .where(
          (package) =>
              _selectedIds.contains(package.id) && isAccessible(package),
        )
        .expand((package) => package.questions),
  );

  QuestionPackage? _find(String id) {
    for (final package in packages) {
      if (package.id == id) return package;
    }
    return null;
  }

  void toggle(String id) {
    if (_disposed || _isBusy) return;
    final package = _find(id);
    if (package == null ||
        !isAccessible(package) ||
        package.questions.isEmpty) {
      return;
    }
    if (!_selectedIds.remove(id)) _selectedIds.add(id);
    notifyListeners();
  }

  Future<RewardOutcome> unlockWithAd(String id) async {
    if (_disposed) return RewardOutcome.unavailable;
    if (_isBusy) return RewardOutcome.busy;
    final package = _find(id);
    if (package == null || package.questions.isEmpty) {
      return RewardOutcome.unavailable;
    }
    if (isAccessible(package)) return RewardOutcome.unavailable;
    _isBusy = true;
    notifyListeners();
    try {
      final result = await _ads.show();
      if (_disposed) return RewardOutcome.unavailable;
      if (result == RewardOutcome.earned) {
        _unlockedIds.add(id);
        _selectedIds.add(id);
        await _unlockStore.grant(id);
      }
      return result;
    } catch (_) {
      return RewardOutcome.unavailable;
    } finally {
      _isBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ads.dispose();
    super.dispose();
  }
}
