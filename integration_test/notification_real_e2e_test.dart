import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:english_learning_ap/core/di/service_locator.dart';
import 'package:english_learning_ap/main.dart';

const MethodChannel _notificationProbeChannel = MethodChannel(
  'voxly/test_notifications',
);
const int _dailyReminderId = 1001;

Future<bool> _isNotificationActive(int id) async {
  try {
    final bool? active = await _notificationProbeChannel
        .invokeMethod<bool>('isNotificationActive', <String, Object>{'id': id})
        .timeout(const Duration(seconds: 2));
    return active ?? false;
  } on TimeoutException {
    return false;
  } on PlatformException {
    return false;
  }
}

DateTime _twoMinuteTarget() {
  final DateTime now = DateTime.now();
  DateTime target = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
  ).add(const Duration(minutes: 1));

  // Avoid edge cases when scheduling too close to minute rollover.
  if (target.difference(now) < const Duration(seconds: 45)) {
    target = target.add(const Duration(minutes: 1));
  }
  return target;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ServiceLocator.init();
  });

  testWidgets(
    'schedules +1m reminder and verifies Android posts it',
    (WidgetTester tester) async {
      if (!Platform.isAndroid) {
        return;
      }

      await tester.pumpWidget(const EnglishLearningApp());
      await tester.pump(const Duration(milliseconds: 2200));
      await tester.pumpAndSettle();

      final DateTime target = _twoMinuteTarget();

      await ServiceLocator.notificationService.setNotificationsEnabled(true);
      await ServiceLocator.notificationService.setReminderTime(
        hour: target.hour,
        minute: target.minute,
      );
      await ServiceLocator.notificationService.scheduleDailyReviewReminder(
        dueCount: 3,
      );

      final int pendingCountBeforeFire =
          await ServiceLocator.notificationService.getPendingReminderCount();
      expect(pendingCountBeforeFire, 1);

      bool fired = false;
      final DateTime deadline = DateTime.now().add(const Duration(minutes: 4));

      // Poll using real clock so Android has time to deliver the alarm.
      while (DateTime.now().isBefore(deadline)) {
        final bool? probeResult = await tester.runAsync<bool>(
          () => _isNotificationActive(_dailyReminderId),
        );
        fired = probeResult ?? false;
        if (fired) {
          break;
        }
        await tester.runAsync<void>(
          () => Future<void>.delayed(const Duration(seconds: 5)),
        );
      }

      expect(
        fired,
        isTrue,
        reason:
            'Expected Android to post notification ID 1001 within 4 minutes after scheduling.',
      );

      await ServiceLocator.notificationService.setNotificationsEnabled(false);
      await ServiceLocator.notificationService.setNotificationsEnabled(true);
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
