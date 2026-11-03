import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/test_routine_model.dart';
import '../utils/notification_service.dart';

class TestsRepository {
  final SupabaseClient _client;

  TestsRepository(this._client);

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Fetches test routine entries for a student
  Future<List<TestRoutineItem>> getStudentTests(String studentId) async {
    final response = await _client
        .from('tests')
        .select()
        .eq('student_id', studentId)
        .order('test_date', ascending: true);

    return (response as List)
        .map((m) => TestRoutineItem.fromMap(m))
        .toList();
  }

  /// Adds a test and schedules local phone reminders (FR-8.4)
  Future<TestRoutineItem> addTest({
    required String studentId,
    required DateTime testDate,
    required String subjectName,
    String? topics,
  }) async {
    final response = await _client
        .from('tests')
        .insert({
          'student_id': studentId,
          'test_date': _formatDate(testDate),
          'subject_name': subjectName.trim(),
          'topics': topics?.trim(),
        })
        .select()
        .single();

    final item = TestRoutineItem.fromMap(response);

    // Schedule local reminders
    await NotificationService.scheduleTestReminders(
      testNotificationId: item.notificationId,
      subjectName: item.subjectName,
      testDate: item.testDate,
      topics: item.topics,
    );

    return item;
  }

  /// Updates test and reschedules reminders (FR-8.6)
  Future<void> updateTest({
    required String testId,
    required int oldNotificationId,
    required DateTime testDate,
    required String subjectName,
    String? topics,
  }) async {
    await NotificationService.cancelTestReminders(oldNotificationId);

    final response = await _client
        .from('tests')
        .update({
          'test_date': _formatDate(testDate),
          'subject_name': subjectName.trim(),
          'topics': topics?.trim(),
        })
        .eq('id', testId)
        .select()
        .single();

    final item = TestRoutineItem.fromMap(response);

    await NotificationService.scheduleTestReminders(
      testNotificationId: item.notificationId,
      subjectName: item.subjectName,
      testDate: item.testDate,
      topics: item.topics,
    );
  }

  /// Deletes a test and cancels reminders (FR-8.6)
  Future<void> deleteTest(String testId, int notificationId) async {
    await NotificationService.cancelTestReminders(notificationId);
    await _client.from('tests').delete().eq('id', testId);
  }
}
