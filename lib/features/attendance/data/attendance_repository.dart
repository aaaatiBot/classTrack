import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/attendance_record.dart';

class AttendanceRepository {
  final SupabaseClient _client;

  AttendanceRepository(this._client);

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Fetches attendance records for a specific date (Admin view)
  Future<List<AttendanceRecord>> getAttendanceForDate(DateTime date) async {
    final dateStr = _formatDate(date);
    final response = await _client
        .from('attendance')
        .select('*, profiles(name)')
        .eq('date', dateStr);

    return (response as List)
        .map((m) => AttendanceRecord.fromMap(m))
        .toList();
  }

  /// Saves or updates attendance records in bulk for a date
  Future<void> saveAttendance({
    required DateTime date,
    required Map<String, String> studentStatusMap, // studentId -> 'present'|'absent'
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    final dateStr = _formatDate(date);

    final List<Map<String, dynamic>> records = studentStatusMap.entries.map((entry) {
      return {
        'student_id': entry.key,
        'date': dateStr,
        'status': entry.value,
        'marked_by': currentUserId,
      };
    }).toList();

    if (records.isEmpty) return;

    await _client.from('attendance').upsert(
      records,
      onConflict: 'student_id,date',
    );
  }

  /// Fetches student's attendance records (for student calendar)
  Future<List<AttendanceRecord>> getStudentAttendance(String studentId) async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('student_id', studentId)
        .order('date', ascending: false);

    return (response as List)
        .map((m) => AttendanceRecord.fromMap(m))
        .toList();
  }

  /// Calculates attendance summary metrics for a student
  Future<AttendanceSummary> getStudentSummary(String studentId) async {
    final records = await getStudentAttendance(studentId);
    int present = 0;
    int absent = 0;

    for (final r in records) {
      if (r.isPresent) {
        present++;
      } else {
        absent++;
      }
    }

    return AttendanceSummary(
      totalClasses: records.length,
      presentCount: present,
      absentCount: absent,
    );
  }
}
