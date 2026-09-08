import 'package:bomb_questions/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults safely to sound, vibration, and mystery', () async {
    final settings = await SettingsService().load();
    expect(settings.soundEnabled, isTrue);
    expect(settings.vibrationEnabled, isTrue);
    expect(settings.timerDisplayMode, TimerDisplayMode.mystery);
  });

  test('persists settings and rejects unknown or corrupt values', () async {
    final service = SettingsService();
    await service.update(
      const GameSettings(
        soundEnabled: false,
        vibrationEnabled: false,
        timerDisplayMode: TimerDisplayMode.visible,
      ),
    );
    final reloaded = await SettingsService().load();
    expect(reloaded.soundEnabled, isFalse);
    expect(reloaded.vibrationEnabled, isFalse);
    expect(reloaded.timerDisplayMode, TimerDisplayMode.visible);

    SharedPreferences.setMockInitialValues({
      'settings_sound': 'bad',
      'settings_vibration': 'bad',
      'settings_timer_display': 'unknown',
    });
    final fallback = await SettingsService().load();
    expect(fallback.soundEnabled, isTrue);
    expect(fallback.vibrationEnabled, isTrue);
    expect(fallback.timerDisplayMode, TimerDisplayMode.mystery);
  });
}
