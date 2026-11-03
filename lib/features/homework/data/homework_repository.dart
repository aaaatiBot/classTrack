import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/homework_model.dart';

class HomeworkRepository {
  final SupabaseClient _client;

  HomeworkRepository(this._client);

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Fetches homework records
  Future<List<Homework>> getHomework({
    DateTime? date,
    String? classBatch,
  }) async {
    var query = _client.from('homework').select();

    if (date != null) {
      query = query.eq('date', _formatDate(date));
    }

    if (classBatch != null && classBatch.isNotEmpty && classBatch != 'All') {
      query = query.or('class_batch.is.null,class_batch.eq.$classBatch');
    }

    final response = await query.order('date', ascending: false).order('created_at', ascending: false);

    return (response as List).map((m) => Homework.fromMap(m)).toList();
  }

  /// Adds a new homework assignment (Admin only)
  Future<Homework> addHomework({
    required DateTime date,
    required String subjectName,
    required String description,
    String? classBatch,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;

    final response = await _client
        .from('homework')
        .insert({
          'date': _formatDate(date),
          'subject_name': subjectName.trim(),
          'description': description.trim(),
          'class_batch': classBatch?.trim().isNotEmpty == true ? classBatch!.trim() : null,
          'created_by': currentUserId,
        })
        .select()
        .single();

    return Homework.fromMap(response);
  }

  /// Deletes a homework entry (Admin only)
  Future<void> deleteHomework(String homeworkId) async {
    await _client.from('homework').delete().eq('id', homeworkId);
  }
}
