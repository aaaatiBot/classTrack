import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    // Request Android 13+ permission
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Schedules 2 reminders for an upcoming test:
  /// 1. Evening before the test at 19:00 (7 PM)
  /// 2. Morning of the test at 07:30 (7:30 AM)
  static Future<void> scheduleTestReminders({
    required int testNotificationId, // numeric id generated from test id hash
    required String subjectName,
    required DateTime testDate,
    String? topics,
  }) async {
    await initialize();

    final now = DateTime.now();

    // 1. Evening Before at 19:00 (7 PM)
    final eveningBefore = DateTime(
      testDate.year,
      testDate.month,
      testDate.day - 1,
      19,
      0,
    );

    if (eveningBefore.isAfter(now)) {
      try {
        await _notifications.zonedSchedule(
          testNotificationId * 2,
          'Test Tomorrow: $subjectName',
          topics != null && topics.isNotEmpty
              ? 'Topics: $topics. Review your notes tonight!'
              : 'Prepare for your $subjectName test tomorrow.',
          tz.TZDateTime.from(eveningBefore, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'test_reminders',
              'Test Reminders',
              channelDescription: 'Notifications for upcoming class and school exams',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('Error scheduling evening reminder: $e');
      }
    }

    // 2. Morning of the test at 07:30 AM
    final morningOf = DateTime(
      testDate.year,
      testDate.month,
      testDate.day,
      7,
      30,
    );

    if (morningOf.isAfter(now)) {
      try {
        await _notifications.zonedSchedule(
          testNotificationId * 2 + 1,
          'Test Today: $subjectName',
          'Good luck! Stay calm and do your best in $subjectName.',
          tz.TZDateTime.from(morningOf, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'test_reminders',
              'Test Reminders',
              channelDescription: 'Notifications for upcoming class and school exams',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('Error scheduling morning reminder: $e');
      }
    }
  }

  /// Cancels reminders when a test is modified or deleted
  static Future<void> cancelTestReminders(int testNotificationId) async {
    await initialize();
    await _notifications.cancel(testNotificationId * 2);
    await _notifications.cancel(testNotificationId * 2 + 1);
  }
}
