import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/domain/user_profile.dart';

class StudentsRepository {
  final SupabaseClient _client;

  StudentsRepository(this._client);

  /// Calls the deployed Supabase Edge Function 'create-student'
  /// Keeps service role key on server side; verifies admin caller; admin stays logged in.
  Future<UserProfile> createStudent({
    required String name,
    required String username,
    required String password,
    String? classBatch,
  }) async {
    final response = await _client.functions.invoke(
      'create-student',
      body: {
        'name': name.trim(),
        'username': username.trim().toLowerCase(),
        'password': password,
        'class_batch': classBatch?.trim(),
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Failed to create student (${response.status})';
      throw Exception(error);
    }

    final data = response.data;
    if (data['success'] != true || data['student'] == null) {
      throw Exception(data['error'] ?? 'Could not create student.');
    }

    return UserProfile.fromMap(data['student']);
  }

  /// Fetches all students with optional search query and class filter
  Future<List<UserProfile>> getStudents({String? query, String? classBatch}) async {
    var request = _client
        .from('profiles')
        .select()
        .eq('role', 'student');

    if (classBatch != null && classBatch.isNotEmpty && classBatch != 'All') {
      request = request.eq('class_batch', classBatch);
    }

    final response = await request.order('name', ascending: true);
    final list = (response as List).map((map) => UserProfile.fromMap(map)).toList();

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      return list.where((s) =>
          s.name.toLowerCase().contains(q) ||
          s.username.toLowerCase().contains(q) ||
          (s.classBatch?.toLowerCase().contains(q) ?? false)).toList();
    }

    return list;
  }

  /// Updates a student's profile information
  Future<UserProfile> updateStudent({
    required String id,
    String? name,
    String? classBatch,
    bool? active,
  }) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name.trim();
    if (classBatch != null) updates['class_batch'] = classBatch.trim();
    if (active != null) updates['active'] = active;

    final response = await _client
        .from('profiles')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return UserProfile.fromMap(response);
  }

  /// Deactivates or activates a student
  Future<void> toggleStudentStatus(String id, bool active) async {
    await _client.from('profiles').update({'active': active}).eq('id', id);
  }

  /// Deletes a student account
  Future<void> deleteStudent(String id) async {
    await _client.from('profiles').delete().eq('id', id);
  }
}
