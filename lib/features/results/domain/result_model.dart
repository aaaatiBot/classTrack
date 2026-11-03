class ResultEntry {
  String subject;
  double marks;
  double maxMarks;

  ResultEntry({
    required this.subject,
    required this.marks,
    this.maxMarks = 100.0,
  });

  double get percentage => maxMarks > 0 ? (marks / maxMarks) * 100 : 0.0;

  Map<String, dynamic> toMap() => {
        'subject': subject,
        'marks': marks,
        'max_marks': maxMarks,
      };

  factory ResultEntry.fromMap(Map<String, dynamic> map) => ResultEntry(
        subject: map['subject'] as String? ?? 'Subject',
        marks: (map['marks'] as num?)?.toDouble() ?? 0.0,
        maxMarks: (map['max_marks'] as num?)?.toDouble() ?? 100.0,
      );
}

class ExamResult {
  final String id;
  final String studentId;
  final int term; // 1, 2, or 3
  final int year;
  final String? examName;
  final List<ResultEntry> entries;
  final DateTime createdAt;

  const ExamResult({
    required this.id,
    required this.studentId,
    required this.term,
    required this.year,
    this.examName,
    required this.entries,
    required this.createdAt,
  });

  double get totalMarks => entries.fold(0.0, (sum, e) => sum + e.marks);
  double get totalMaxMarks => entries.fold(0.0, (sum, e) => sum + e.maxMarks);
  double get overallPercentage =>
      totalMaxMarks > 0 ? (totalMarks / totalMaxMarks) * 100 : 0.0;

  factory ExamResult.fromMap(Map<String, dynamic> map) {
    final rawEntries = map['entries'] as List? ?? [];
    return ExamResult(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      term: (map['term'] as num?)?.toInt() ?? 1,
      year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
      examName: map['exam_name'] as String?,
      entries: rawEntries
          .map((e) => ResultEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'student_id': studentId,
        'term': term,
        'year': year,
        'exam_name': examName,
        'entries': entries.map((e) => e.toMap()).toList(),
      };
}
