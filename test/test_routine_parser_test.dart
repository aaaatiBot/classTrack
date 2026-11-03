import 'package:flutter_test/flutter_test.dart';
import 'package:classtrack/features/tests/utils/test_routine_parser.dart';

void main() {
  group('TestRoutineParser Tests', () {
    test('extracts dates with DD/MM/YYYY and subjects', () {
      const ocr = '''
      UNIT TEST SCHEDULE - 2026
      15/11/2026 - Mathematics: Chapter 1 to 4
      17/11/2026 - Physics - Force and Laws of Motion
      20/11/2026 - Chemistry
      ''';

      final results = TestRoutineParser.parseOcrText(ocr);
      expect(results.length, equals(3));

      expect(results[0].subjectName, equals('Mathematics'));
      expect(results[0].topics, equals('Chapter 1 to 4'));
      expect(results[0].testDate.day, equals(15));
      expect(results[0].testDate.month, equals(11));

      expect(results[1].subjectName, equals('Physics'));
      expect(results[1].topics, equals('Force and Laws of Motion'));
    });

    test('extracts dates with month names e.g. 15 Nov 2026', () {
      const ocr = '''
      10 Dec 2026 - English Literature
      12 Dec 2026 - History & Civics
      ''';

      final results = TestRoutineParser.parseOcrText(ocr);
      expect(results.length, equals(2));
      expect(results[0].testDate.month, equals(12));
      expect(results[0].subjectName, equals('English Literature'));
    });
  });
}
