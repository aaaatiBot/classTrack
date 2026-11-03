import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/syllabus_repository.dart';
import '../domain/syllabus_models.dart';

final syllabusRepositoryProvider = Provider<SyllabusRepository>((ref) {
  return SyllabusRepository(Supabase.instance.client);
});

// Selected Term Filter: null = All, 1 = Term 1, 2 = Term 2, 3 = Term 3
final selectedTermFilterProvider = StateProvider<int?>((ref) => null);

// Fetches syllabus for the specified studentId
final studentSyllabusProvider =
    FutureProvider.family<List<Subject>, String>((ref, studentId) async {
  final repo = ref.watch(syllabusRepositoryProvider);
  return repo.getStudentSyllabus(studentId);
});

// Overall stats calculator
class SyllabusOverallProgress {
  final int totalChapters;
  final int completedChapters;

  const SyllabusOverallProgress({
    required this.totalChapters,
    required this.completedChapters,
  });

  double get percentage =>
      totalChapters > 0 ? (completedChapters / totalChapters) * 100 : 0.0;
}

final syllabusProgressProvider =
    Provider.family<SyllabusOverallProgress, List<Subject>>((ref, subjects) {
  final termFilter = ref.watch(selectedTermFilterProvider);
  int total = 0;
  int completed = 0;

  for (final s in subjects) {
    final chapters = s.chaptersForTerm(termFilter);
    total += chapters.length;
    completed += chapters.where((c) => c.isComplete).length;
  }

  return SyllabusOverallProgress(
    totalChapters: total,
    completedChapters: completed,
  );
});
