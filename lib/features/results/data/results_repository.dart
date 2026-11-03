import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/result_model.dart';

class ResultsRepository {
  final SupabaseClient _client;

  ResultsRepository(this._client);

  /// Fetches saved report card results for a student
  Future<List<ExamResult>> getStudentResults(String studentId) async {
    final response = await _client
        .from('results')
        .select()
        .eq('student_id', studentId)
        .order('year', ascending: true)
        .order('term', ascending: true);

    return (response as List).map((m) => ExamResult.fromMap(m)).toList();
  }

  /// Saves a new confirmed exam result
  Future<ExamResult> saveResult(ExamResult result) async {
    final response = await _client
        .from('results')
        .insert(result.toMap())
        .select()
        .single();

    return ExamResult.fromMap(response);
  }

  /// Deletes a saved result record
  Future<void> deleteResult(String resultId) async {
    await _client.from('results').delete().eq('id', resultId);
  }
}
