class Subject {
  final String id;
  final String studentId;
  final String name;
  final int sortOrder;
  final List<Chapter> chapters;

  const Subject({
    required this.id,
    required this.studentId,
    required this.name,
    this.sortOrder = 0,
    this.chapters = const [],
  });

  int get totalChapters => chapters.length;
  int get completedChapters => chapters.where((c) => c.isComplete).length;
  double get completionPercentage =>
      totalChapters > 0 ? (completedChapters / totalChapters) * 100 : 0.0;

  List<Chapter> chaptersForTerm(int? term) {
    if (term == null) return chapters;
    return chapters.where((c) => c.term == term).toList();
  }

  factory Subject.fromMap(Map<String, dynamic> map, {List<Chapter> chapters = const []}) {
    return Subject(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      name: map['name'] as String,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      chapters: chapters,
    );
  }

  Subject copyWith({
    String? id,
    String? studentId,
    String? name,
    int? sortOrder,
    List<Chapter>? chapters,
  }) {
    return Subject(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      chapters: chapters ?? this.chapters,
    );
  }
}

class Chapter {
  final String id;
  final String subjectId;
  final int term; // 1, 2, or 3
  final String title;
  final int sortOrder;
  final bool isComplete;
  final DateTime? completedOn;

  const Chapter({
    required this.id,
    required this.subjectId,
    required this.term,
    required this.title,
    this.sortOrder = 0,
    this.isComplete = false,
    this.completedOn,
  });

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String,
      term: (map['term'] as num?)?.toInt() ?? 1,
      title: map['title'] as String,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isComplete: map['is_complete'] as bool? ?? false,
      completedOn: map['completed_on'] != null
          ? DateTime.tryParse(map['completed_on'].toString())
          : null,
    );
  }

  Chapter copyWith({
    String? id,
    String? subjectId,
    int? term,
    String? title,
    int? sortOrder,
    bool? isComplete,
    DateTime? completedOn,
  }) {
    return Chapter(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      term: term ?? this.term,
      title: title ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
      isComplete: isComplete ?? this.isComplete,
      completedOn: completedOn ?? this.completedOn,
    );
  }
}
