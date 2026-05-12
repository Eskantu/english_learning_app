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
  static const String _notificationChannelId = 'review_channel';
  static const String _notificationChannelName = 'Review reminders';
  static const String _notificationChannelDescription =
      'Daily reminders for English review practice';
  static const int _defaultHour = 20;
  static const int _defaultMinute = 0;

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String> _tapController =
      StreamController<String>.broadcast();
  late final Box<dynamic> _settingsBox;
  bool _canScheduleExact = false;

  @override
  Stream<String> get onNotificationTap => _tapController.stream;

  @override
  Future<void> initialize() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: _notificationChannelDescription,
      importance: Importance.high,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    bool? result = await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Forward payload taps to the app-level listener.
        final String? payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _tapController.add(payload);
        }
      },
    );
    if (result != true) {
      print(
        'Warning: Failed to initialize notifications plugin. Reminders will not work.',
      );
    }

    final AndroidFlutterLocalNotificationsPlugin? androidImpl =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    bool? permissionGranted =
        await androidImpl?.requestNotificationsPermission();
    bool? exactAlarmPermissionGranted =
        await androidImpl?.requestExactAlarmsPermission();
    print(
      'Notification permission granted: $permissionGranted, exact alarm permission granted: $exactAlarmPermissionGranted',
    );
    await androidImpl?.createNotificationChannel(channel);
    if (permissionGranted != true) {
      print(
        'Warning: Notification permissions not granted. Reminders will not work.',
      );
    }
    final bool? canScheduleExact =
        await androidImpl?.canScheduleExactNotifications();
    _canScheduleExact = canScheduleExact ?? false;
    print('canScheduleExact: $canScheduleExact');

    tz.initializeTimeZones();
    final String timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));
    print('Notifications initialized with timezone: $timezoneName');
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
    print(
      'Scheduling daily review reminder. Due count: $dueCount, notifications enabled: $notificationsEnabled',
    );
    // Only disable if user explicitly turned notifications off.
    if (!notificationsEnabled) {
      await _plugin.cancel(_dailyReminderId);
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _notificationChannelId,
          _notificationChannelName,
          channelDescription: _notificationChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final int hour = await getReminderHour();
    final int minute = await getReminderMinute();
    final tz.TZDateTime scheduleAt = _nextInstanceOfTime(hour, minute);
    final AndroidScheduleMode scheduleMode =
        _canScheduleExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;
    final String body =
        dueCount > 0
            ? 'Tienes $dueCount frases pendientes para revisar hoy.'
            : 'Abre Voxly para revisar tu progreso de ingles de hoy.';

    print(
      'Scheduling reminder for: $scheduleAt (local timezone) with due count: $dueCount and mode: $scheduleMode',
    );

    _plugin.show(0, 'Instant notification', body, notificationDetails);

    // Repeat daily at the configured local wall-clock time.
    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Hora de practicar ingles',
      body,
      scheduleAt,
      notificationDetails,
      androidScheduleMode: scheduleMode,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: reviewPayload,
    );
    // tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    // tz.TZDateTime scheduleAt2 = now.add(const Duration(seconds: 10));
    // _plugin.zonedSchedule(
    //   _dailyReminderId,
    //   'Hora de practicar ingles',
    //   body,
    //   scheduleAt2,
    //   notificationDetails,
    //   androidScheduleMode: scheduleMode,
    //   matchDateTimeComponents: DateTimeComponents.time,
    //   payload: reviewPayload,
    // );

    final pending = await _plugin.pendingNotificationRequests();
    // For debugging: log all pending notifications after scheduling.
    print(
      'Scheduled notifications: ${pending.map((e) => 'ID: ${e.id}, Title: ${e.title}, Payload: ${e.payload}').join('; ')}',
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
    print('Next instance of time for $hour:$minute is $scheduled');
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
    print('Setting reminder time to $hour:$minute');
    await _settingsBox.put(_notificationHourKey, hour);
    await _settingsBox.put(_notificationMinuteKey, minute);
  }

  @override
  Future<int> getPendingReminderCount() async {
    final List<PendingNotificationRequest> pending =
        await _plugin.pendingNotificationRequests();
    int pendingCount =
        pending
            .where((PendingNotificationRequest e) => e.id == _dailyReminderId)
            .length;
    print('Pending reminders: $pendingCount');
    return pendingCount;
  }
}
