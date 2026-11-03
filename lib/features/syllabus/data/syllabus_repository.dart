import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/syllabus_models.dart';

class SyllabusRepository {
  final SupabaseClient _client;

  SyllabusRepository(this._client);

  /// Fetches all subjects and their nested chapters for a student
  Future<List<Subject>> getStudentSyllabus(String studentId) async {
    final subjectsData = await _client
        .from('subjects')
        .select('*, chapters(*)')
        .eq('student_id', studentId)
        .order('sort_order', ascending: true);

    final List<Subject> subjects = [];
    for (final sMap in (subjectsData as List)) {
      final chaptersRaw = sMap['chapters'] as List? ?? [];
      final chapters = chaptersRaw
          .map((c) => Chapter.fromMap(c))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      subjects.add(Subject.fromMap(sMap, chapters: chapters));
    }

    return subjects;
  }

  /// Adds a new subject for the student
  Future<Subject> addSubject({
    required String studentId,
    required String name,
  }) async {
    final existing = await _client
        .from('subjects')
        .select('sort_order')
        .eq('student_id', studentId)
        .order('sort_order', ascending: false)
        .limit(1);

    int nextSortOrder = 0;
    if ((existing as List).isNotEmpty) {
      nextSortOrder = ((existing.first['sort_order'] as num?)?.toInt() ?? 0) + 1;
    }

    final response = await _client
        .from('subjects')
        .insert({
          'student_id': studentId,
          'name': name.trim(),
          'sort_order': nextSortOrder,
        })
        .select()
        .single();

    return Subject.fromMap(response);
  }

  /// Renames an existing subject
  Future<void> renameSubject(String subjectId, String newName) async {
    await _client
        .from('subjects')
        .update({'name': newName.trim()})
        .eq('id', subjectId);
  }

  /// Deletes a subject and cascades deletion of its chapters
  Future<void> deleteSubject(String subjectId) async {
    await _client.from('subjects').delete().eq('id', subjectId);
  }

  /// Adds a chapter to a subject
  Future<Chapter> addChapter({
    required String subjectId,
    required String title,
    required int term,
  }) async {
    final existing = await _client
        .from('chapters')
        .select('sort_order')
        .eq('subject_id', subjectId)
        .order('sort_order', ascending: false)
        .limit(1);

    int nextSortOrder = 0;
    if ((existing as List).isNotEmpty) {
      nextSortOrder = ((existing.first['sort_order'] as num?)?.toInt() ?? 0) + 1;
    }

    final response = await _client
        .from('chapters')
        .insert({
          'subject_id': subjectId,
          'term': term,
          'title': title.trim(),
          'sort_order': nextSortOrder,
          'is_complete': false,
        })
        .select()
        .single();

    return Chapter.fromMap(response);
  }

  /// Updates chapter title or term
  Future<void> updateChapter({
    required String chapterId,
    String? title,
    int? term,
  }) async {
    final Map<String, dynamic> updates = {};
    if (title != null) updates['title'] = title.trim();
    if (term != null) updates['term'] = term;

    await _client.from('chapters').update(updates).eq('id', chapterId);
  }

  /// Toggles chapter completion status and records date
  Future<void> toggleChapterCompletion({
    required String chapterId,
    required bool isComplete,
  }) async {
    final dateStr = isComplete
        ? "${DateTime.now().year.toString().padLeft(4, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}"
        : null;

    await _client.from('chapters').update({
      'is_complete': isComplete,
      'completed_on': dateStr,
    }).eq('id', chapterId);
  }

  /// Deletes a chapter
  Future<void> deleteChapter(String chapterId) async {
    await _client.from('chapters').delete().eq('id', chapterId);
  }

  /// Updates the order of chapters
  Future<void> reorderChapters(List<Chapter> chapters) async {
    for (int i = 0; i < chapters.length; i++) {
      await _client
          .from('chapters')
          .update({'sort_order': i})
          .eq('id', chapters[i].id);
    }
  }
}
