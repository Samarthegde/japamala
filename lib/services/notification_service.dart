import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// A single daily reminder to sit and practise.
class NotificationService {
  static const int _dailyReminderId = 1;
  static const String _channelId = 'japamala_daily_reminder';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();
      // Scheduling in the device's own zone, so a reminder set for 6 AM stays
      // at 6 AM local time rather than drifting with UTC.
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Could not initialize notifications: $e');
    }
  }

  /// Returns false when the user declines, so callers can avoid promising a
  /// reminder that will never arrive.
  static Future<bool> requestPermission() async {
    await init();
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }

      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
    } catch (e) {
      debugPrint('Could not request notification permission: $e');
    }
    return false;
  }

  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await init();
    try {
      await _plugin.zonedSchedule(
        id: _dailyReminderId,
        title: 'Time for your practice',
        body: 'Your mala is waiting.',
        scheduledDate: _nextInstanceOf(time),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Daily practice reminder',
            channelDescription: 'A daily nudge to sit for japa.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
    } catch (e) {
      debugPrint('Could not schedule reminder: $e');
    }
  }

  static Future<void> cancelDailyReminder() async {
    await init();
    try {
      await _plugin.cancel(id: _dailyReminderId);
    } catch (e) {
      debugPrint('Could not cancel reminder: $e');
    }
  }

  static tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
