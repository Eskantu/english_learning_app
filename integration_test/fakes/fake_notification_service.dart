import 'dart:async';

import 'package:english_learning_ap/core/services/notification_service.dart';

class FakeNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleDailyReviewReminder({required int dueCount}) async {}

  @override
  Future<String?> getLaunchPayload() async => null;

  @override
  Stream<String> get onNotificationTap => const Stream.empty();
}
