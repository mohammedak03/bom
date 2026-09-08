import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardOutcome { earned, dismissed, unavailable, busy }

abstract interface class RewardedAdGateway {
  Future<RewardOutcome> show();

  void dispose();
}

/// Uses Google's sample rewarded units exclusively during development.
/// Creating this service never initializes the SDK or requests an ad.
class AdMobRewardedAdService implements RewardedAdGateway {
  static const _androidTestUnit = 'ca-app-pub-3940256099942544/5224354917';
  static const _iosTestUnit = 'ca-app-pub-3940256099942544/1712485313';
  static const _initializationTimeout = Duration(seconds: 15);
  static const _loadTimeout = Duration(seconds: 25);
  static const _showTimeout = Duration(seconds: 10);

  Future<bool>? _initialization;
  _RewardRequest? _active;
  bool _disposed = false;

  @override
  Future<RewardOutcome> show() {
    if (_disposed ||
        kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return Future.value(RewardOutcome.unavailable);
    }
    if (_active != null) {
      return Future.value(RewardOutcome.busy);
    }

    final request = _RewardRequest();
    _active = request;
    unawaited(_load(request));
    return request.result.future;
  }

  Future<bool> _initialize() async {
    try {
      await MobileAds.instance.initialize().timeout(_initializationTimeout);
      return true;
    } catch (error) {
      debugPrint('Rewarded ad initialization failed: $error');
      return false;
    }
  }

  Future<void> _load(_RewardRequest request) async {
    try {
      final initialized = await (_initialization ??= _initialize());
      if (!initialized) {
        _initialization = null;
        _finish(request, RewardOutcome.unavailable);
        return;
      }
      if (!_isActive(request)) return;

      request.timeout = Timer(
        _loadTimeout,
        () => _finish(request, RewardOutcome.unavailable),
      );
      await RewardedAd.load(
        adUnitId: defaultTargetPlatform == TargetPlatform.android
            ? _androidTestUnit
            : _iosTestUnit,
        request: const AdRequest(nonPersonalizedAds: true),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (!_isActive(request)) {
              // A native load can complete after timeout or screen disposal.
              unawaited(_disposeAd(ad));
              return;
            }
            request.ad = ad;
            unawaited(_present(request, ad));
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad load failed: $error');
            _finish(request, RewardOutcome.unavailable);
          },
        ),
      ).timeout(_loadTimeout);
    } catch (error) {
      debugPrint('Rewarded ad request failed: $error');
      if (!request.visible) _finish(request, RewardOutcome.unavailable);
    }
  }

  Future<void> _present(_RewardRequest request, RewardedAd ad) async {
    request.timeout?.cancel();
    request.timeout = Timer(
      _showTimeout,
      () => _finish(request, RewardOutcome.unavailable),
    );

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (_) {
        request.visible = true;
        // Once visible, the user controls when the ad is dismissed.
        request.timeout?.cancel();
      },
      onAdDismissedFullScreenContent: (_) {
        _finish(
          request,
          request.earned ? RewardOutcome.earned : RewardOutcome.dismissed,
        );
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        debugPrint('Rewarded ad presentation failed: $error');
        _finish(request, RewardOutcome.unavailable);
      },
    );

    try {
      await ad
          .show(
            onUserEarnedReward: (_, _) {
              if (_isActive(request)) request.earned = true;
              // Wait for dismissal before allowing the app to open the pack.
            },
          )
          .timeout(_showTimeout);
    } catch (error) {
      debugPrint('Rewarded ad show failed: $error');
      if (!request.visible) _finish(request, RewardOutcome.unavailable);
    }
  }

  bool _isActive(_RewardRequest request) =>
      !_disposed && identical(_active, request) && !request.result.isCompleted;

  void _finish(_RewardRequest request, RewardOutcome outcome) {
    if (request.result.isCompleted) return;

    request.timeout?.cancel();
    final ad = request.ad;
    request.ad = null;
    if (ad != null) unawaited(_disposeAd(ad));
    if (identical(_active, request)) _active = null;
    request.result.complete(outcome);
  }

  Future<void> _disposeAd(RewardedAd ad) async {
    try {
      await ad.dispose().timeout(const Duration(seconds: 5));
    } catch (error) {
      debugPrint('Rewarded ad disposal failed: $error');
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final request = _active;
    if (request != null) _finish(request, RewardOutcome.unavailable);
  }
}

class _RewardRequest {
  final result = Completer<RewardOutcome>();
  RewardedAd? ad;
  Timer? timeout;
  bool earned = false;
  bool visible = false;
}
