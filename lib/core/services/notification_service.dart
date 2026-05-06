abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleDailyReviewReminder({required int dueCount});
  Future<bool> getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool enabled);
  Future<int> getReminderHour();
  Future<int> getReminderMinute();
  Future<void> setReminderTime({required int hour, required int minute});
  Future<int> getPendingReminderCount();
  Future<String?> getLaunchPayload();
  Stream<String> get onNotificationTap;
}
