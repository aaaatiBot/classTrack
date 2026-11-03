class TestScoreItem {
  final String id;
  final String studentId;
  final String subjectName;
  final String title;
  final DateTime testDate;
  final double marks;
  final double maxMarks;
  final String? enteredBy;
  final DateTime createdAt;

  const TestScoreItem({
    required this.id,
    required this.studentId,
    required this.subjectName,
    required this.title,
    required this.testDate,
    required this.marks,
    required this.maxMarks,
    this.enteredBy,
    required this.createdAt,
  });

  double get percentage => maxMarks > 0 ? (marks / maxMarks) * 100 : 0.0;

  factory TestScoreItem.fromMap(Map<String, dynamic> map) {
    return TestScoreItem(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      subjectName: map['subject_name'] as String,
      title: map['title'] as String,
      testDate: DateTime.parse(map['test_date'].toString()),
      marks: (map['marks'] as num).toDouble(),
      maxMarks: (map['max_marks'] as num).toDouble(),
      enteredBy: map['entered_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'student_id': studentId,
        'subject_name': subjectName,
        'title': title,
        'test_date':
            "${testDate.year.toString().padLeft(4, '0')}-${testDate.month.toString().padLeft(2, '0')}-${testDate.day.toString().padLeft(2, '0')}",
        'marks': marks,
        'max_marks': maxMarks,
        if (enteredBy != null) 'entered_by': enteredBy,
      };
}
