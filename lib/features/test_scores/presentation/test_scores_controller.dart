import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/test_scores_repository.dart';
import '../domain/test_score_model.dart';

final testScoresRepositoryProvider = Provider<TestScoresRepository>((ref) {
  return TestScoresRepository(ref.watch(supabaseClientProvider));
});

class TestScoresState {
  final bool isLoading;
  final String? errorMessage;
  final List<TestScoreItem> scores;
  final String selectedSubject;

  const TestScoresState({
    this.isLoading = false,
    this.errorMessage,
    this.scores = const [],
    this.selectedSubject = 'All',
  });

  TestScoresState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<TestScoreItem>? scores,
    String? selectedSubject,
  }) {
    return TestScoresState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      scores: scores ?? this.scores,
      selectedSubject: selectedSubject ?? this.selectedSubject,
    );
  }
}

class TestScoresController extends StateNotifier<TestScoresState> {
  final TestScoresRepository _repo;
  final String? _studentId;
  final bool _isAdmin;

  TestScoresController(this._repo, this._studentId, this._isAdmin)
      : super(const TestScoresState()) {
    loadScores();
  }

  Future<void> loadScores() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final List<TestScoreItem> items;
      if (_isAdmin && _studentId == null) {
        items = await _repo.getAllScores(
          subjectName: state.selectedSubject == 'All' ? null : state.selectedSubject,
        );
      } else if (_studentId != null) {
        items = await _repo.getStudentScores(
          _studentId,
          subjectName: state.selectedSubject == 'All' ? null : state.selectedSubject,
        );
      } else {
        items = [];
      }
      state = state.copyWith(isLoading: false, scores: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void filterSubject(String subject) {
    state = state.copyWith(selectedSubject: subject);
    loadScores();
  }

  Future<bool> addScore({
    required String studentId,
    required String subjectName,
    required String title,
    required DateTime testDate,
    required double marks,
    required double maxMarks,
    String? enteredBy,
  }) async {
    try {
      await _repo.addScore(
        studentId: studentId,
        subjectName: subjectName,
        title: title,
        testDate: testDate,
        marks: marks,
        maxMarks: maxMarks,
        enteredBy: enteredBy,
      );
      await loadScores();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> bulkAddScores(List<Map<String, dynamic>> rows) async {
    try {
      await _repo.bulkAddScores(rows);
      await loadScores();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateScore({
    required String id,
    required String subjectName,
    required String title,
    required DateTime testDate,
    required double marks,
    required double maxMarks,
  }) async {
    try {
      await _repo.updateScore(
        id: id,
        subjectName: subjectName,
        title: title,
        testDate: testDate,
        marks: marks,
        maxMarks: maxMarks,
      );
      await loadScores();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteScore(String id) async {
    try {
      await _repo.deleteScore(id);
      final updated = state.scores.where((s) => s.id != id).toList();
      state = state.copyWith(scores: updated);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final testScoresControllerProvider =
    StateNotifierProvider.family<TestScoresController, TestScoresState, String?>((ref, studentIdOverride) {
  final repo = ref.watch(testScoresRepositoryProvider);
  final auth = ref.watch(authControllerProvider);
  final isAdmin = auth.userProfile?.isAdmin ?? false;
  final effectiveId = studentIdOverride ?? (isAdmin ? null : auth.userProfile?.id);
  return TestScoresController(repo, effectiveId, isAdmin);
});
