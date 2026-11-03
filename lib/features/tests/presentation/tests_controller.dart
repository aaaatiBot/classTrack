import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/tests_repository.dart';
import '../domain/test_routine_model.dart';

final testsRepositoryProvider = Provider<TestsRepository>((ref) {
  return TestsRepository(ref.watch(supabaseClientProvider));
});

class TestsState {
  final bool isLoading;
  final String? errorMessage;
  final List<TestRoutineItem> tests;

  const TestsState({
    this.isLoading = false,
    this.errorMessage,
    this.tests = const [],
  });

  TestsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<TestRoutineItem>? tests,
  }) {
    return TestsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      tests: tests ?? this.tests,
    );
  }
}

class TestsController extends StateNotifier<TestsState> {
  final TestsRepository _repo;
  final String? _studentId;

  TestsController(this._repo, this._studentId) : super(const TestsState()) {
    loadTests();
  }

  Future<void> loadTests() async {
    if (_studentId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final tests = await _repo.getStudentTests(_studentId);
      state = state.copyWith(isLoading: false, tests: tests);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> addTest({
    required DateTime testDate,
    required String subjectName,
    String? topics,
  }) async {
    if (_studentId == null) return false;
    try {
      final newItem = await _repo.addTest(
        studentId: _studentId,
        testDate: testDate,
        subjectName: subjectName,
        topics: topics,
      );
      final updated = List<TestRoutineItem>.from(state.tests)..add(newItem);
      updated.sort((a, b) => a.testDate.compareTo(b.testDate));
      state = state.copyWith(tests: updated);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> addMultipleTests(List<TestRoutineItem> items) async {
    if (_studentId == null) return false;
    try {
      for (final item in items) {
        await _repo.addTest(
          studentId: _studentId,
          testDate: item.testDate,
          subjectName: item.subjectName,
          topics: item.topics,
        );
      }
      await loadTests();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateTest({
    required String testId,
    required int oldNotificationId,
    required DateTime testDate,
    required String subjectName,
    String? topics,
  }) async {
    try {
      await _repo.updateTest(
        testId: testId,
        oldNotificationId: oldNotificationId,
        testDate: testDate,
        subjectName: subjectName,
        topics: topics,
      );
      await loadTests();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteTest(String testId, int notificationId) async {
    try {
      await _repo.deleteTest(testId, notificationId);
      final updated = state.tests.where((t) => t.id != testId).toList();
      state = state.copyWith(tests: updated);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final testsControllerProvider =
    StateNotifierProvider.family<TestsController, TestsState, String?>((ref, studentIdOverride) {
  final repo = ref.watch(testsRepositoryProvider);
  final effectiveId = studentIdOverride ?? ref.watch(authControllerProvider).userProfile?.id;
  return TestsController(repo, effectiveId);
});
