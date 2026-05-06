import 'dart:async';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart';

/// Local-notification implementation used for daily review reminders.
class FlutterNotificationService implements NotificationService {
  FlutterNotificationService(this._plugin);

  /// Payload consumed by the app root to open the review flow.
  static const String reviewPayload = 'open_review';

  /// Stable ID so every new schedule replaces the previous daily reminder.
  static const int _dailyReminderId = 1001;
  static const String _settingsBoxName = 'app_settings_box';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationHourKey = 'notification_hour';
  static const String _notificationMinuteKey = 'notification_minute';
  static const int _defaultHour = 20;
  static const int _defaultMinute = 0;

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String> _tapController =
      StreamController<String>.broadcast();
  late final Box<dynamic> _settingsBox;

  @override
  Stream<String> get onNotificationTap => _tapController.stream;

  @override
  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Forward payload taps to the app-level listener.
        final String? payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _tapController.add(payload);
        }
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImpl =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidImpl?.requestNotificationsPermission();

    tz.initializeTimeZones();
    final String timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));

    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
    await _ensureDefaults();
  }

  Future<void> _ensureDefaults() async {
    if (!_settingsBox.containsKey(_notificationsEnabledKey)) {
      await _settingsBox.put(_notificationsEnabledKey, true);
    }
    if (!_settingsBox.containsKey(_notificationHourKey)) {
      await _settingsBox.put(_notificationHourKey, _defaultHour);
    }
    if (!_settingsBox.containsKey(_notificationMinuteKey)) {
      await _settingsBox.put(_notificationMinuteKey, _defaultMinute);
    }
  }

  @override
  Future<String?> getLaunchPayload() async {
    final NotificationAppLaunchDetails? details =
        await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details?.notificationResponse?.payload;
    }
    return null;
  }

  @override
  Future<void> scheduleDailyReviewReminder({required int dueCount}) async {
    final bool notificationsEnabled = await getNotificationsEnabled();

    // No due items means no reminder should be shown.
    if (!notificationsEnabled || dueCount <= 0) {
      await _plugin.cancel(_dailyReminderId);
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'review_channel',
          'Review reminders',
          channelDescription: 'Daily reminders for English review practice',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final int hour = await getReminderHour();
    final int minute = await getReminderMinute();
    final tz.TZDateTime scheduleAt = _nextInstanceOfTime(hour, minute);

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Hora de practicar ingles',
      'Tienes $dueCount frases pendientes para revisar hoy.',
      scheduleAt,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: reviewPayload,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    return (_settingsBox.get(_notificationsEnabledKey) as bool?) ?? true;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsBox.put(_notificationsEnabledKey, enabled);
    if (!enabled) {
      await _plugin.cancel(_dailyReminderId);
    }
  }

  @override
  Future<int> getReminderHour() async {
    return (_settingsBox.get(_notificationHourKey) as int?) ?? _defaultHour;
  }

  @override
  Future<int> getReminderMinute() async {
    return (_settingsBox.get(_notificationMinuteKey) as int?) ?? _defaultMinute;
  }

  @override
  Future<void> setReminderTime({required int hour, required int minute}) async {
    await _settingsBox.put(_notificationHourKey, hour);
    await _settingsBox.put(_notificationMinuteKey, minute);
  }

  @override
  Future<int> getPendingReminderCount() async {
    final List<PendingNotificationRequest> pending =
        await _plugin.pendingNotificationRequests();
    return pending
        .where((PendingNotificationRequest e) => e.id == _dailyReminderId)
        .length;
  }
}
