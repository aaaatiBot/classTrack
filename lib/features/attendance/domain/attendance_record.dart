class AttendanceRecord {
  final String id;
  final String studentId;
  final DateTime date;
  final String status; // 'present' or 'absent'
  final String? markedBy;
  final String? studentName;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
    this.markedBy,
    this.studentName,
  });

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, {String? studentName}) {
    return AttendanceRecord(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      date: DateTime.parse(map['date'].toString()),
      status: map['status'] as String,
      markedBy: map['marked_by'] as String?,
      studentName: studentName ?? (map['profiles'] != null ? map['profiles']['name'] : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'date': "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'status': status,
    };
  }
}

class AttendanceSummary {
  final int totalClasses;
  final int presentCount;
  final int absentCount;

  const AttendanceSummary({
    required this.totalClasses,
    required this.presentCount,
    required this.absentCount,
  });

  double get percentage =>
      totalClasses > 0 ? (presentCount / totalClasses) * 100 : 0.0;
}
