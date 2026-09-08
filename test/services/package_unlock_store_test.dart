import 'dart:convert';

import 'package:bomb_questions/services/package_unlock_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('earned package persists for 24 hours and expires safely', () async {
    var now = DateTime(2026, 1, 1, 12);
    SharedPreferences.setMockInitialValues({});
    final store = PackageUnlockStore(now: () => now);
    await store.grant('football');
    expect(await store.activeIds(), {'football'});

    now = now.add(const Duration(hours: 23, minutes: 59));
    expect(await store.activeIds(), {'football'});
    now = now.add(const Duration(minutes: 2));
    expect(await store.activeIds(), isEmpty);
  });

  test(
    'corrupt unlock storage is cleared instead of granting access',
    () async {
      SharedPreferences.setMockInitialValues({
        'package_unlocks_v1': jsonEncode({'football': 'tomorrow'}),
      });
      final store = PackageUnlockStore();
      expect(await store.activeIds(), isEmpty);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey('package_unlocks_v1'), isFalse);
    },
  );
}
