import 'dart:async';

import 'package:english_learning_ap/core/services/notification_service.dart';

class FakeNotificationService implements NotificationService {
  bool notificationsEnabled = true;
  int reminderHour = 20;
  int reminderMinute = 0;
  int lastDueCount = 0;
  int pendingReminderCount = 0;
  int scheduleCallCount = 0;
  int cancelCallCount = 0;

  void resetState() {
    notificationsEnabled = true;
    reminderHour = 20;
    reminderMinute = 0;
    resetTracking();
  }

  void resetTracking() {
    lastDueCount = 0;
    pendingReminderCount = 0;
    scheduleCallCount = 0;
    cancelCallCount = 0;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleDailyReviewReminder({required int dueCount}) async {
    scheduleCallCount += 1;
    lastDueCount = dueCount;
    if (!notificationsEnabled || dueCount <= 0) {
      pendingReminderCount = 0;
      cancelCallCount += 1;
      return;
    }
    pendingReminderCount = 1;
  }

  @override
  Future<bool> getNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    notificationsEnabled = enabled;
    if (!enabled) {
      pendingReminderCount = 0;
      cancelCallCount += 1;
    }
  }

  @override
  Future<int> getReminderHour() async => reminderHour;

  @override
  Future<int> getReminderMinute() async => reminderMinute;

  @override
  Future<void> setReminderTime({required int hour, required int minute}) async {
    reminderHour = hour;
    reminderMinute = minute;
  }

  @override
  Future<int> getPendingReminderCount() async => pendingReminderCount;

  @override
  Future<String?> getLaunchPayload() async => null;

  @override
  Stream<String> get onNotificationTap => const Stream.empty();
}
