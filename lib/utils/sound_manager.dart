import 'package:flutter/services.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  Future<void> playMoveSound() async {
    if (!_soundEnabled) return;
    try {
      // Use system click sound for regular moves
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // Silently handle any sound errors
      print('Move sound error (non-critical): $e');
    }
  }

  Future<void> playCaptureSound() async {
    if (!_soundEnabled) return;
    try {
      // Use system alert sound for captures (more dramatic)
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      // Silently handle any sound errors
      print('Capture sound error (non-critical): $e');
    }
  }

  // Keep this method for backward compatibility but make it a no-op
  Future<void> dispose() async {
    // Nothing to dispose for system sounds
  }
}
