import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

class HapticService {
  Future<void> lightTap() {
    return _vibrate(duration: 35, amplitude: 90);
  }

  Future<void> heavyExplosion() async {
    try {
      if (!await Vibration.hasVibrator()) {
        return;
      }

      if (await Vibration.hasCustomVibrationsSupport()) {
        await Vibration.vibrate(
          pattern: const [0, 120, 55, 220, 70, 320],
          intensities: const [0, 170, 0, 225, 0, 255],
        );
        return;
      }

      await Vibration.vibrate(duration: 700, amplitude: 255);
    } catch (error) {
      debugPrint('HapticService heavyExplosion error: $error');
    }
  }

  Future<void> _vibrate({required int duration, required int amplitude}) async {
    try {
      if (!await Vibration.hasVibrator()) {
        return;
      }

      await Vibration.vibrate(duration: duration, amplitude: amplitude);
    } catch (error) {
      debugPrint('HapticService vibration error: $error');
    }
  }
}
