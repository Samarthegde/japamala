import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Completion sounds for practice. Deliberately separate from haptics: a phone
/// in a bag or on a cushion gives no useful vibration feedback.
class SoundService {
  static const String bellAsset = 'sounds/bell.wav';
  static const String cueInAsset = 'sounds/cue_in.wav';
  static const String cueOutAsset = 'sounds/cue_out.wav';
  static const String cueHoldAsset = 'sounds/cue_hold.wav';

  static final AudioPlayer _player = AudioPlayer();

  /// Breath cues get their own player so a cue never cuts off the bell, and
  /// so rapid phase changes don't fight over one player.
  static final AudioPlayer _cuePlayer = AudioPlayer();

  /// Plays the bell without blocking the caller. Failures are swallowed —
  /// a missing audio route should never interrupt a practice session.
  static Future<void> bell() async {
    try {
      await _player.stop();
      await _player.play(AssetSource(bellAsset));
    } catch (e) {
      debugPrint('Could not play bell: $e');
    }
  }

  /// A short tone marking a breathing phase change. Quieter than the bell,
  /// and pitched to suggest the direction of the breath.
  static Future<void> cue(String asset) async {
    try {
      await _cuePlayer.stop();
      await _cuePlayer.play(AssetSource(asset));
    } catch (e) {
      debugPrint('Could not play breath cue: $e');
    }
  }

  static Future<void> dispose() async {
    await _player.dispose();
    await _cuePlayer.dispose();
  }
}
