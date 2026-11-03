import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/homework_repository.dart';
import '../domain/homework_model.dart';

final homeworkRepositoryProvider = Provider<HomeworkRepository>((ref) {
  return HomeworkRepository(Supabase.instance.client);
});

// Selected batch filter for homework
final homeworkBatchFilterProvider = StateProvider<String>((ref) => 'All');

// Today's homework list
final todayHomeworkProvider = FutureProvider<List<Homework>>((ref) async {
  final repo = ref.watch(homeworkRepositoryProvider);
  final batch = ref.watch(homeworkBatchFilterProvider);
  return repo.getHomework(
    date: DateTime.now(),
    classBatch: batch,
  );
});

// All / History homework list
final allHomeworkProvider = FutureProvider<List<Homework>>((ref) async {
  final repo = ref.watch(homeworkRepositoryProvider);
  final batch = ref.watch(homeworkBatchFilterProvider);
  return repo.getHomework(classBatch: batch);
});
