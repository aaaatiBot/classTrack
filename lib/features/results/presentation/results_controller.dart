import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/results_repository.dart';
import '../domain/result_model.dart';

final resultsRepositoryProvider = Provider<ResultsRepository>((ref) {
  return ResultsRepository(Supabase.instance.client);
});

final studentResultsListProvider =
    FutureProvider.family<List<ExamResult>, String>((ref, studentId) async {
  final repo = ref.watch(resultsRepositoryProvider);
  return repo.getStudentResults(studentId);
});
