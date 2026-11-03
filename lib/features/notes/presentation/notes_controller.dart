import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/notes_repository.dart';
import '../domain/note_model.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(Supabase.instance.client);
});

// Selected batch filter for notes
final notesBatchFilterProvider = StateProvider<String>((ref) => 'All');

// Selected subject filter for notes
final notesSubjectFilterProvider = StateProvider<String>((ref) => 'All');

// Notes list
final notesListProvider = FutureProvider<List<NoteModel>>((ref) async {
  final repo = ref.watch(notesRepositoryProvider);
  final batch = ref.watch(notesBatchFilterProvider);
  final subject = ref.watch(notesSubjectFilterProvider);
  return repo.getNotes(
    classBatch: batch,
    subjectName: subject,
  );
});
