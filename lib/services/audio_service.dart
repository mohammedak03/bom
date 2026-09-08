import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  factory AudioService() => _instance;

  AudioService._();

  static final AudioService _instance = AudioService._();

  static const _normalTickInterval = Duration(milliseconds: 780);
  static const _fastTickInterval = Duration(milliseconds: 260);

  static final Uint8List _normalTickSound = _buildToneSequence([
    const _ToneSegment(
      frequency: 760,
      duration: Duration(milliseconds: 70),
      volume: 0.38,
    ),
  ]);

  static final Uint8List _fastTickSound = _buildToneSequence([
    const _ToneSegment(
      frequency: 1040,
      duration: Duration(milliseconds: 55),
      volume: 0.5,
    ),
  ]);

  static final Uint8List _successSound = _buildToneSequence([
    const _ToneSegment(
      frequency: 820,
      duration: Duration(milliseconds: 80),
      volume: 0.38,
    ),
    const _ToneSegment(
      frequency: 1180,
      duration: Duration(milliseconds: 120),
      volume: 0.42,
    ),
  ]);

  static final Uint8List _explosionSound = _buildExplosion();

  final AudioPlayer _tickPlayer = AudioPlayer(playerId: 'bomb_tick_player');
  final AudioPlayer _effectPlayer = AudioPlayer(playerId: 'bomb_effect_player');

  Timer? _tickTimer;
  Duration? _currentTickInterval;
  bool _isPlayingTick = false;

  void startTicking() {
    _startTickLoop(_normalTickInterval, _normalTickSound, volume: 0.55);
  }

  void speedUpTicking() {
    _startTickLoop(_fastTickInterval, _fastTickSound, volume: 0.72);
  }

  Future<void> stopTicking() async {
    _tickTimer?.cancel();
    _tickTimer = null;
    _currentTickInterval = null;
    _isPlayingTick = false;

    try {
      await _tickPlayer.stop();
    } catch (error) {
      debugPrint('AudioService stopTicking error: $error');
    }
  }

  Future<void> playExplosion() async {
    await stopTicking();
    await _playEffect(_explosionSound, volume: 0.9);
  }

  Future<void> playSuccess() {
    return _playEffect(_successSound, volume: 0.65);
  }

  void _startTickLoop(
    Duration interval,
    Uint8List sound, {
    required double volume,
  }) {
    if (_tickTimer?.isActive == true && _currentTickInterval == interval) {
      return;
    }

    _tickTimer?.cancel();
    _currentTickInterval = interval;

    unawaited(_playTick(sound, volume: volume));
    _tickTimer = Timer.periodic(
      interval,
      (_) => unawaited(_playTick(sound, volume: volume)),
    );
  }

  Future<void> _playTick(Uint8List sound, {required double volume}) async {
    if (_isPlayingTick) {
      return;
    }

    _isPlayingTick = true;
    try {
      await _tickPlayer.play(
        BytesSource(sound, mimeType: 'audio/wav'),
        mode: PlayerMode.lowLatency,
        volume: volume,
      );
    } catch (error) {
      debugPrint('AudioService tick error: $error');
    } finally {
      _isPlayingTick = false;
    }
  }

  Future<void> _playEffect(Uint8List sound, {required double volume}) async {
    try {
      await _effectPlayer.stop();
      await _effectPlayer.play(
        BytesSource(sound, mimeType: 'audio/wav'),
        mode: PlayerMode.lowLatency,
        volume: volume,
      );
    } catch (error) {
      debugPrint('AudioService effect error: $error');
    }
  }

  static Uint8List _buildToneSequence(
    List<_ToneSegment> segments, {
    int sampleRate = 22050,
  }) {
    final samples = <int>[];

    for (final segment in segments) {
      final sampleCount = (sampleRate * segment.duration.inMilliseconds / 1000)
          .round();
      final fadeSamples = math.min(
        (sampleRate * 0.012).round(),
        math.max(1, sampleCount ~/ 2),
      );

      for (var index = 0; index < sampleCount; index++) {
        final time = index / sampleRate;
        final fadeIn = index < fadeSamples ? index / fadeSamples : 1.0;
        final fadeOut = sampleCount - index < fadeSamples
            ? (sampleCount - index) / fadeSamples
            : 1.0;
        final envelope = math.min(fadeIn, fadeOut);
        final wave = math.sin(2 * math.pi * segment.frequency * time);

        samples.add(_toPcm16(wave * segment.volume * envelope));
      }
    }

    return _wavFromPcm16(samples, sampleRate);
  }

  static Uint8List _buildExplosion({int sampleRate = 22050}) {
    const duration = Duration(milliseconds: 640);
    final random = math.Random(9);
    final sampleCount = (sampleRate * duration.inMilliseconds / 1000).round();
    final samples = <int>[];

    for (var index = 0; index < sampleCount; index++) {
      final progress = index / sampleCount;
      final time = index / sampleRate;
      final envelope = math.pow(1 - progress, 2.2).toDouble();
      final noise = (random.nextDouble() * 2) - 1;
      final rumble = math.sin(2 * math.pi * 72 * time);
      final crack = math.sin(2 * math.pi * 145 * time);
      final wave =
          ((noise * 0.78) + (rumble * 0.34) + (crack * 0.18)) * envelope * 0.9;

      samples.add(_toPcm16(wave));
    }

    return _wavFromPcm16(samples, sampleRate);
  }

  static Uint8List _wavFromPcm16(List<int> samples, int sampleRate) {
    final dataSize = samples.length * 2;
    final byteData = ByteData(44 + dataSize);

    void writeString(int offset, String value) {
      for (var index = 0; index < value.length; index++) {
        byteData.setUint8(offset + index, value.codeUnitAt(index));
      }
    }

    writeString(0, 'RIFF');
    byteData.setUint32(4, 36 + dataSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    byteData.setUint32(40, dataSize, Endian.little);

    for (var index = 0; index < samples.length; index++) {
      byteData.setInt16(44 + (index * 2), samples[index], Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  static int _toPcm16(double sample) {
    return (sample.clamp(-1.0, 1.0) * 32767).round();
  }
}

class _ToneSegment {
  const _ToneSegment({
    required this.frequency,
    required this.duration,
    required this.volume,
  });

  final double frequency;
  final Duration duration;
  final double volume;
}
