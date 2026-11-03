import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance_record.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(Supabase.instance.client);
});

// Selected Date Provider for Admin Register
final selectedAttendanceDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

// Attendance records for selected date
final dateAttendanceProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final date = ref.watch(selectedAttendanceDateProvider);
  final records = await repo.getAttendanceForDate(date);

  final Map<String, String> statusMap = {};
  for (final r in records) {
    statusMap[r.studentId] = r.status;
  }
  return statusMap;
});

// Student personal attendance list
final studentAttendanceRecordsProvider =
    FutureProvider.family<List<AttendanceRecord>, String>((ref, studentId) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getStudentAttendance(studentId);
});

// Student attendance summary metrics
final studentAttendanceSummaryProvider =
    FutureProvider.family<AttendanceSummary, String>((ref, studentId) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getStudentSummary(studentId);
});
