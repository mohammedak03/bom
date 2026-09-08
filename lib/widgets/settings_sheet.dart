import 'package:flutter/material.dart';
import '../services/settings_service.dart';

Future<void> showGameSettingsSheet(BuildContext context) async {
  final service = SettingsService();
  var settings = await service.load();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'الإعدادات',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SwitchListTile(
                title: const Text('الصوت'),
                value: settings.soundEnabled,
                onChanged: (value) async {
                  settings = GameSettings(
                    soundEnabled: value,
                    vibrationEnabled: settings.vibrationEnabled,
                    timerDisplayMode: settings.timerDisplayMode,
                  );
                  setState(() {});
                  await service.update(settings);
                },
              ),
              SwitchListTile(
                title: const Text('الاهتزاز'),
                value: settings.vibrationEnabled,
                onChanged: (value) async {
                  settings = GameSettings(
                    soundEnabled: settings.soundEnabled,
                    vibrationEnabled: value,
                    timerDisplayMode: settings.timerDisplayMode,
                  );
                  setState(() {});
                  await service.update(settings);
                },
              ),
              RadioListTile<TimerDisplayMode>(
                title: const Text('المؤقت الغامض'),
                value: TimerDisplayMode.mystery,
                groupValue: settings.timerDisplayMode,
                onChanged: (value) async {
                  if (value == null) return;
                  settings = GameSettings(
                    soundEnabled: settings.soundEnabled,
                    vibrationEnabled: settings.vibrationEnabled,
                    timerDisplayMode: value,
                  );
                  setState(() {});
                  await service.update(settings);
                },
              ),
              RadioListTile<TimerDisplayMode>(
                title: const Text('المؤقت الظاهر'),
                value: TimerDisplayMode.visible,
                groupValue: settings.timerDisplayMode,
                onChanged: (value) async {
                  if (value == null) return;
                  settings = GameSettings(
                    soundEnabled: settings.soundEnabled,
                    vibrationEnabled: settings.vibrationEnabled,
                    timerDisplayMode: value,
                  );
                  setState(() {});
                  await service.update(settings);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
