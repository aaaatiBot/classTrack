class TestRoutineItem {
  final String id;
  final String studentId;
  final DateTime testDate;
  final String subjectName;
  final String? topics;
  final DateTime createdAt;

  const TestRoutineItem({
    required this.id,
    required this.studentId,
    required this.testDate,
    required this.subjectName,
    this.topics,
    required this.createdAt,
  });

  int get notificationId => id.hashCode.abs() % 1000000;

  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return testDate.isAfter(today) || testDate.isAtSameMomentAs(today);
  }

  factory TestRoutineItem.fromMap(Map<String, dynamic> map) {
    return TestRoutineItem(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      testDate: DateTime.parse(map['test_date'].toString()),
      subjectName: map['subject_name'] as String,
      topics: map['topics'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'student_id': studentId,
        'test_date':
            "${testDate.year.toString().padLeft(4, '0')}-${testDate.month.toString().padLeft(2, '0')}-${testDate.day.toString().padLeft(2, '0')}",
        'subject_name': subjectName,
        'topics': topics,
      };
}
