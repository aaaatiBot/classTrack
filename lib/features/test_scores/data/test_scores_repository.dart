import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/test_score_model.dart';

class TestScoresRepository {
  final SupabaseClient _client;

  TestScoresRepository(this._client);

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Get scores for a student, ordered chronologically
  Future<List<TestScoreItem>> getStudentScores(String studentId, {String? subjectName}) async {
    var query = _client.from('test_scores').select().eq('student_id', studentId);
    if (subjectName != null && subjectName.isNotEmpty && subjectName != 'All') {
      query = query.eq('subject_name', subjectName);
    }
    final response = await query.order('test_date', ascending: false);
    return (response as List).map((m) => TestScoreItem.fromMap(m)).toList();
  }

  /// Get all test scores (for admin oversight)
  Future<List<TestScoreItem>> getAllScores({String? subjectName}) async {
    var query = _client.from('test_scores').select();
    if (subjectName != null && subjectName.isNotEmpty && subjectName != 'All') {
      query = query.eq('subject_name', subjectName);
    }
    final response = await query.order('test_date', ascending: false);
    return (response as List).map((m) => TestScoreItem.fromMap(m)).toList();
  }

  /// Add a single score
  Future<TestScoreItem> addScore({
    required String studentId,
    required String subjectName,
    required String title,
    required DateTime testDate,
    required double marks,
    required double maxMarks,
    String? enteredBy,
  }) async {
    final response = await _client
        .from('test_scores')
        .insert({
          'student_id': studentId,
          'subject_name': subjectName.trim(),
          'title': title.trim(),
          'test_date': _formatDate(testDate),
          'marks': marks,
          'max_marks': maxMarks,
          if (enteredBy != null) 'entered_by': enteredBy,
        })
        .select()
        .single();

    return TestScoreItem.fromMap(response);
  }

  /// Bulk add test scores for a batch (FR-9.2 Mode B)
  Future<void> bulkAddScores(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from('test_scores').insert(rows);
  }

  /// Update an existing score
  Future<void> updateScore({
    required String id,
    required String subjectName,
    required String title,
    required DateTime testDate,
    required double marks,
    required double maxMarks,
  }) async {
    await _client.from('test_scores').update({
      'subject_name': subjectName.trim(),
      'title': title.trim(),
      'test_date': _formatDate(testDate),
      'marks': marks,
      'max_marks': maxMarks,
    }).eq('id', id);
  }

  /// Delete a test score
  Future<void> deleteScore(String id) async {
    await _client.from('test_scores').delete().eq('id', id);
  }
}
