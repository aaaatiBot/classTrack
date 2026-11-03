import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/note_model.dart';

class NotesRepository {
  final SupabaseClient _client;

  NotesRepository(this._client);

  static const String bucketName = 'notes';

  /// Fetches notes list
  Future<List<NoteModel>> getNotes({String? classBatch, String? subjectName}) async {
    var query = _client.from('notes').select();

    if (classBatch != null && classBatch.isNotEmpty && classBatch != 'All') {
      query = query.or('class_batch.is.null,class_batch.eq.$classBatch');
    }

    if (subjectName != null && subjectName.isNotEmpty && subjectName != 'All') {
      query = query.eq('subject_name', subjectName);
    }

    final response = await query.order('uploaded_on', ascending: false);
    return (response as List).map((m) => NoteModel.fromMap(m)).toList();
  }

  /// Uploads note file to private bucket and records metadata in database
  Future<NoteModel> uploadNote({
    required String subjectName,
    required String title,
    required String fileName,
    required Uint8List fileBytes,
    String? classBatch,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = 'notes/${timestamp}_$cleanFileName';

    // Upload to private bucket
    await _client.storage.from(bucketName).uploadBinary(
      storagePath,
      fileBytes,
      fileOptions: const FileOptions(upsert: true),
    );

    // Save metadata
    final response = await _client
        .from('notes')
        .insert({
          'subject_name': subjectName.trim(),
          'title': title.trim(),
          'file_path': storagePath,
          'class_batch': classBatch?.trim().isNotEmpty == true ? classBatch!.trim() : null,
          'uploaded_by': currentUserId,
        })
        .select()
        .single();

    return NoteModel.fromMap(response);
  }

  /// Generates a short-lived signed URL for secure download/preview (SEC-3)
  Future<String> getSignedUrl(String filePath, {int expiresInSeconds = 3600}) async {
    return await _client.storage.from(bucketName).createSignedUrl(
      filePath,
      expiresInSeconds,
    );
  }

  /// Deletes a note and its storage file (Admin only)
  Future<void> deleteNote(String noteId, String filePath) async {
    try {
      await _client.storage.from(bucketName).remove([filePath]);
    } catch (_) {
      // Ignore if file was already removed from storage
    }
    await _client.from('notes').delete().eq('id', noteId);
  }
}
