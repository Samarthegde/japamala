package com.eterniqo.japamala

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Forwards volume key presses to Flutter so a mala can be counted with the
 * phone in a pocket or with eyes closed.
 *
 * Flutter opts in per screen via the method channel; when it hasn't, the keys
 * behave normally and adjust the volume.
 */
class MainActivity : FlutterActivity() {

    private var volumeKeysCaptured = false
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTROL_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setCaptureVolumeKeys" -> {
                        volumeKeysCaptured = call.arguments as? Boolean ?: false
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (volumeKeysCaptured && isVolumeKey(keyCode)) {
            // Ignore auto-repeat, so holding the key doesn't run up the count.
            if (event?.repeatCount == 0) {
                eventSink?.success(
                    if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) "up" else "down"
                )
            }
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        // Swallow the matching key-up too, otherwise the system volume UI
        // still appears on release.
        if (volumeKeysCaptured && isVolumeKey(keyCode)) {
            return true
        }
        return super.onKeyUp(keyCode, event)
    }

    private fun isVolumeKey(keyCode: Int): Boolean =
        keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN

    override fun onPause() {
        // Never leave the keys captured for another screen or app.
        volumeKeysCaptured = false
        super.onPause()
    }

    companion object {
        private const val CONTROL_CHANNEL = "japamala/volume_keys"
        private const val EVENT_CHANNEL = "japamala/volume_keys/events"
    }
}
