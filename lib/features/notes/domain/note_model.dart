class NoteModel {
  final String id;
  final String? classBatch;
  final String subjectName;
  final String title;
  final String filePath;
  final String? uploadedBy;
  final DateTime uploadedOn;

  const NoteModel({
    required this.id,
    this.classBatch,
    required this.subjectName,
    required this.title,
    required this.filePath,
    this.uploadedBy,
    required this.uploadedOn,
  });

  bool get isPdf => filePath.toLowerCase().endsWith('.pdf');
  bool get isImage =>
      filePath.toLowerCase().endsWith('.jpg') ||
      filePath.toLowerCase().endsWith('.jpeg') ||
      filePath.toLowerCase().endsWith('.png') ||
      filePath.toLowerCase().endsWith('.webp');

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      classBatch: map['class_batch'] as String?,
      subjectName: map['subject_name'] as String,
      title: map['title'] as String,
      filePath: map['file_path'] as String,
      uploadedBy: map['uploaded_by'] as String?,
      uploadedOn: map['uploaded_on'] != null
          ? DateTime.tryParse(map['uploaded_on'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
