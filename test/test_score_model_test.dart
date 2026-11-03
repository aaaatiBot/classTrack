import 'package:flutter_test/flutter_test.dart';
import 'package:classtrack/features/test_scores/domain/test_score_model.dart';

void main() {
  group('TestScoreItem Model Tests', () {
    test('computes percentage properly', () {
      final score = TestScoreItem(
        id: '1',
        studentId: 'student_1',
        subjectName: 'Math',
        title: 'Unit Test 1',
        testDate: DateTime(2026, 11, 15),
        marks: 18,
        maxMarks: 20,
        createdAt: DateTime.now(),
      );

      expect(score.percentage, equals(90.0));
    });

    test('serializes to and from map', () {
      final score = TestScoreItem(
        id: 'score_101',
        studentId: 'stud_abc',
        subjectName: 'Physics',
        title: 'Weekly Quiz',
        testDate: DateTime(2026, 11, 20),
        marks: 22.5,
        maxMarks: 25.0,
        createdAt: DateTime(2026, 11, 1),
      );

      final map = score.toMap();
      expect(map['student_id'], equals('stud_abc'));
      expect(map['subject_name'], equals('Physics'));
      expect(map['marks'], equals(22.5));
      expect(map['test_date'], equals('2026-11-20'));
    });
  });
}
