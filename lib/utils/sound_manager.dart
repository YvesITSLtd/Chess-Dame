import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:typed_data';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  AudioPlayer? _audioPlayer;

  AudioPlayer get _player {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }

  Future<void> playMoveSound() async {
    await _player.play(
      BytesSource(
        Uint8List.fromList(
          _generateTone(frequency: 440, duration: 100, volume: 0.3)
        )
      )
    );
  }

  Future<void> playCaptureSound() async {
    await _player.play(
      BytesSource(
        Uint8List.fromList(
          _generateTone(frequency: 880, duration: 150, volume: 0.5)
        )
      )
    );
  }

  List<int> _generateTone({
    required double frequency,
    required int duration,
    required double volume
  }) {
    final sampleRate = 44100;
    final samples = (sampleRate * duration / 1000).round();
    final List<int> data = [];

    for (var i = 0; i < samples; i++) {
      final t = i / sampleRate;
      final amplitude = (volume * 32767 * sin(2 * pi * frequency * t)).round();
      data.add(amplitude & 0xFF);
      data.add((amplitude >> 8) & 0xFF);
    }

    return data;
  }

  Future<void> dispose() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.stop();
      await _audioPlayer!.dispose();
      _audioPlayer = null;
    }
  }
}
