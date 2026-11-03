import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/domain/user_profile.dart';
import '../data/students_repository.dart';

final studentsRepositoryProvider = Provider<StudentsRepository>((ref) {
  return StudentsRepository(Supabase.instance.client);
});

class StudentsFilterState {
  final String searchQuery;
  final String selectedBatch;

  const StudentsFilterState({
    this.searchQuery = '',
    this.selectedBatch = 'All',
  });

  StudentsFilterState copyWith({
    String? searchQuery,
    String? selectedBatch,
  }) {
    return StudentsFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedBatch: selectedBatch ?? this.selectedBatch,
    );
  }
}

final studentsFilterProvider =
    StateNotifierProvider<StudentsFilterNotifier, StudentsFilterState>((ref) {
  return StudentsFilterNotifier();
});

class StudentsFilterNotifier extends StateNotifier<StudentsFilterState> {
  StudentsFilterNotifier() : super(const StudentsFilterState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedBatch(String batch) {
    state = state.copyWith(selectedBatch: batch);
  }
}

final studentsListProvider = FutureProvider<List<UserProfile>>((ref) async {
  final repo = ref.watch(studentsRepositoryProvider);
  final filter = ref.watch(studentsFilterProvider);
  return repo.getStudents(
    query: filter.searchQuery,
    classBatch: filter.selectedBatch,
  );
});

final classBatchesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(studentsRepositoryProvider);
  final students = await repo.getStudents();
  final batches = students
      .map((s) => s.classBatch)
      .where((b) => b != null && b.trim().isNotEmpty)
      .map((b) => b!.trim())
      .toSet()
      .toList();
  batches.sort();
  return ['All', ...batches];
});
