class Homework {
  final String id;
  final DateTime date;
  final String subjectName;
  final String description;
  final String? classBatch;
  final String? createdBy;
  final DateTime createdAt;

  const Homework({
    required this.id,
    required this.date,
    required this.subjectName,
    required this.description,
    this.classBatch,
    this.createdBy,
    required this.createdAt,
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  factory Homework.fromMap(Map<String, dynamic> map) {
    return Homework(
      id: map['id'] as String,
      date: DateTime.parse(map['date'].toString()),
      subjectName: map['subject_name'] as String,
      description: map['description'] as String,
      classBatch: map['class_batch'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'subject_name': subjectName,
      'description': description,
      'class_batch': classBatch,
      'created_by': createdBy,
    };
  }
}
