import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Counts beads from the hardware volume keys, so a round can be told with the
/// phone in a pocket or with eyes closed.
///
/// Android only: iOS gives apps no supported way to intercept the volume
/// buttons, so [isSupported] is false there and every call is a no-op.
class VolumeKeyService {
  static const MethodChannel _control = MethodChannel('japamala/volume_keys');
  static const EventChannel _events = EventChannel(
    'japamala/volume_keys/events',
  );

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Fires for each volume key press while capture is enabled. The value is
  /// 'up' or 'down'.
  static Stream<String> get presses {
    if (!isSupported) return const Stream<String>.empty();
    return _events.receiveBroadcastStream().map((event) => event as String);
  }

  /// While captured, the volume keys stop changing the system volume.
  /// Always pair enabling with a matching disable when leaving the screen.
  static Future<void> setCaptureEnabled(bool enabled) async {
    if (!isSupported) return;
    try {
      await _control.invokeMethod('setCaptureVolumeKeys', enabled);
    } catch (e) {
      debugPrint('Could not toggle volume key capture: $e');
    }
  }
}
