import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';

/// Local-notification implementation used for daily review reminders.
class FlutterNotificationService implements NotificationService {
  FlutterNotificationService(this._plugin);

  /// Payload consumed by the app root to open the review flow.
  static const String reviewPayload = 'open_review';

  /// Stable ID so every new schedule replaces the previous daily reminder.
  static const int _dailyReminderId = 1001;

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String> _tapController = StreamController<String>.broadcast();

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
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
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
    // No due items means no reminder should be shown.
    if (dueCount <= 0) {
      await _plugin.cancel(_dailyReminderId);
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'review_channel',
      'Review reminders',
      channelDescription: 'Daily reminders for English review practice',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.periodicallyShow(
      _dailyReminderId,
      'Hora de practicar ingles',
      'Tienes $dueCount frases pendientes para revisar hoy.',
      // Uses plugin-provided daily interval; not a fixed wall-clock time.
      RepeatInterval.daily,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reviewPayload,
    );
  }
}
