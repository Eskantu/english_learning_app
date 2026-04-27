abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleDailyReviewReminder({required int dueCount});
  Future<String?> getLaunchPayload();
  Stream<String> get onNotificationTap;
}
