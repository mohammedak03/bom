import 'dart:async';

import 'package:bomb_questions/services/rewarded_ad_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// The SDK exposes its native channel and ad registry for adapter tests.
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart' as ads;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdMobRewardedAdService service;
  late List<MethodCall> calls;
  Future<InitializationStatus> Function()? initialize;
  bool failShow = false;

  setUp(() {
    service = AdMobRewardedAdService();
    calls = [];
    initialize = null;
    failShow = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ads.instanceManager.channel, (call) async {
          calls.add(call);
          if (call.method == 'MobileAds#initialize') {
            return initialize != null
                ? await initialize!()
                : InitializationStatus({});
          }
          if (call.method == 'showAdWithoutView' && failShow) {
            throw PlatformException(code: 'show_failed');
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ads.instanceManager.channel, null);
  });

  Future<RewardedAd> requestedAd(WidgetTester tester) async {
    await tester.pump();
    final load = calls.lastWhere((call) => call.method == 'loadRewardedAd');
    return ads.instanceManager.adFor(load.arguments['adId'] as int)!
        as RewardedAd;
  }

  Future<RewardedAd> presentAd(WidgetTester tester) async {
    final ad = await requestedAd(tester);
    ad.rewardedAdLoadCallback.onAdLoaded(ad);
    await tester.pump();
    ad.fullScreenContentCallback!.onAdShowedFullScreenContent!(ad);
    return ad;
  }

  void serviceTest(String description, WidgetTesterCallback callback) {
    testWidgets(description, (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await callback(tester);
      } finally {
        service.dispose();
        debugDefaultTargetPlatformOverride = null;
        await tester.pump();
      }
    });
  }

  serviceTest('does not contact the SDK until an ad is requested', (
    tester,
  ) async {
    await tester.pump();
    expect(calls, isEmpty);
  });

  serviceTest('desktop reports unavailable without native calls', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(await service.show(), RewardOutcome.unavailable);
    expect(calls, isEmpty);
  });

  serviceTest('grants only after earned reward and dismissal', (tester) async {
    RewardOutcome? observed;
    final result = service.show()..then((value) => observed = value);
    final ad = await presentAd(tester);
    expect(ad.adUnitId, 'ca-app-pub-3940256099942544/5224354917');
    expect(ad.request!.nonPersonalizedAds, isTrue);

    ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'pack'));
    await tester.pump();
    expect(observed, isNull);
    expect(await service.show(), RewardOutcome.busy);

    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    expect(await result, RewardOutcome.earned);
    await tester.pump();
    expect(calls.where((call) => call.method == 'disposeAd'), hasLength(1));
  });

  serviceTest('closing without a reward never grants access', (tester) async {
    final result = service.show();
    final ad = await presentAd(tester);
    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    expect(await result, RewardOutcome.dismissed);

    // Even a stale callback after dismissal cannot change the result.
    ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'pack'));
    expect(await result, RewardOutcome.dismissed);
    await tester.pump();
  });

  serviceTest('initialization failure returns unavailable and can retry', (
    tester,
  ) async {
    initialize = () => Future.error(PlatformException(code: 'init_failed'));
    final failed = service.show();
    await tester.pump();
    expect(await failed, RewardOutcome.unavailable);
    expect(calls.where((call) => call.method == 'loadRewardedAd'), isEmpty);

    initialize = null;
    final retry = service.show();
    final ad = await presentAd(tester);
    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    expect(await retry, RewardOutcome.dismissed);
    await tester.pump();
  });

  serviceTest('initialization timeout cannot start a late ad', (tester) async {
    final nativeInitialization = Completer<InitializationStatus>();
    initialize = () => nativeInitialization.future;
    final result = service.show();
    await tester.pump();
    await tester.pump(const Duration(seconds: 16));
    expect(await result, RewardOutcome.unavailable);

    nativeInitialization.complete(InitializationStatus({}));
    await tester.pump();
    expect(calls.where((call) => call.method == 'loadRewardedAd'), isEmpty);
  });

  serviceTest(
    'loading is exclusive and late loads are disposed after timeout',
    (tester) async {
      final result = service.show();
      final ad = await requestedAd(tester);
      expect(await service.show(), RewardOutcome.busy);
      await tester.pump(const Duration(seconds: 26));
      expect(await result, RewardOutcome.unavailable);

      ad.rewardedAdLoadCallback.onAdLoaded(ad);
      await tester.pump();
      expect(
        calls.where((call) => call.method == 'showAdWithoutView'),
        isEmpty,
      );
      expect(calls.where((call) => call.method == 'disposeAd'), hasLength(1));
    },
  );

  serviceTest('native presentation failure cannot grant access', (
    tester,
  ) async {
    failShow = true;
    final result = service.show();
    final ad = await requestedAd(tester);
    ad.rewardedAdLoadCallback.onAdLoaded(ad);
    await tester.pump();
    expect(await result, RewardOutcome.unavailable);
    expect(calls.where((call) => call.method == 'disposeAd'), hasLength(1));
  });

  serviceTest('load failure reports unavailable', (tester) async {
    final result = service.show();
    final ad = await requestedAd(tester);
    ad.rewardedAdLoadCallback.onAdFailedToLoad(_TestLoadError());
    expect(await result, RewardOutcome.unavailable);
    // In the native SDK path, its event handler disposes failed loads itself.
    await ad.dispose();
    await tester.pump();
  });

  serviceTest('disposing during loading completes the pending request', (
    tester,
  ) async {
    final result = service.show();
    final ad = await requestedAd(tester);
    service.dispose();
    expect(await result, RewardOutcome.unavailable);
    expect(await service.show(), RewardOutcome.unavailable);

    ad.rewardedAdLoadCallback.onAdLoaded(ad);
    await tester.pump();
    expect(calls.where((call) => call.method == 'showAdWithoutView'), isEmpty);
    expect(calls.where((call) => call.method == 'disposeAd'), hasLength(1));
  });

  serviceTest('disposing a visible ad cannot grant a late reward', (
    tester,
  ) async {
    final result = service.show();
    final ad = await presentAd(tester);
    service.dispose();
    ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'pack'));
    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    expect(await result, RewardOutcome.unavailable);
    await tester.pump();
    expect(calls.where((call) => call.method == 'disposeAd'), hasLength(1));
  });

  serviceTest('iOS also requests only the Google test unit', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final result = service.show();
    final ad = await presentAd(tester);
    expect(ad.adUnitId, 'ca-app-pub-3940256099942544/1712485313');
    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    expect(await result, RewardOutcome.dismissed);
    await tester.pump();
  });
}

class _TestLoadError extends LoadAdError {
  _TestLoadError() : super(1, 'test', 'No ad available', null);
}
