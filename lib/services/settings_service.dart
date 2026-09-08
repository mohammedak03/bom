import 'package:shared_preferences/shared_preferences.dart';

enum TimerDisplayMode { mystery, visible }

class GameSettings {
  const GameSettings({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.timerDisplayMode = TimerDisplayMode.mystery,
  });
  final bool soundEnabled;
  final bool vibrationEnabled;
  final TimerDisplayMode timerDisplayMode;
}

class SettingsService {
  factory SettingsService() => _instance;
  SettingsService._();
  static final SettingsService _instance = SettingsService._();
  static const _soundKey = 'settings_sound';
  static const _vibrationKey = 'settings_vibration';
  static const _timerKey = 'settings_timer_display';
  GameSettings _settings = const GameSettings();
  GameSettings get settings => _settings;

  Future<GameSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final timer = prefs.getString(_timerKey);
    bool readBool(String key) {
      try {
        return prefs.getBool(key) ?? true;
      } catch (_) {
        return true;
      }
    }

    _settings = GameSettings(
      soundEnabled: readBool(_soundKey),
      vibrationEnabled: readBool(_vibrationKey),
      timerDisplayMode: timer == TimerDisplayMode.visible.name
          ? TimerDisplayMode.visible
          : TimerDisplayMode.mystery,
    );
    return _settings;
  }

  Future<void> update(GameSettings value) async {
    _settings = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value.soundEnabled);
    await prefs.setBool(_vibrationKey, value.vibrationEnabled);
    await prefs.setString(_timerKey, value.timerDisplayMode.name);
  }
}
