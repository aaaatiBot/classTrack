import 'package:flutter_test/flutter_test.dart';
import 'package:classtrack/features/results/utils/report_card_parser.dart';

void main() {
  group('ReportCardParser Tests', () {
    test('extracts subject and marks accurately from tabular lines', () {
      const sampleOcr = '''
      ST. XAVIER'S HIGH SCHOOL
      REPORT CARD 2026 - TERM 1
      ---------------------------
      Mathematics     88  / 100
      Physics         76  / 100
      Chemistry       92  / 100
      English         84  / 100
      Computer Science 95 / 100
      ---------------------------
      Total Marks: 435 / 500
      ''';

      final entries = ReportCardParser.parseOcrText(sampleOcr);
      expect(entries.length, greaterThanOrEqualTo(4));

      final math = entries.firstWhere((e) => e.subject.contains('Math'));
      expect(math.marks, equals(88.0));
      expect(math.maxMarks, equals(100.0));
      expect(math.percentage, equals(88.0));

      final cs = entries.firstWhere((e) => e.subject.contains('Computer'));
      expect(cs.marks, equals(95.0));
    });

    test('extracts term number if mentioned', () {
      expect(ReportCardParser.detectTerm('Terminal Exam 2 Result'), equals(2));
      expect(ReportCardParser.detectTerm('Annual 3rd Term Report'), equals(3));
      expect(ReportCardParser.detectTerm('First Term Exam'), equals(1));
    });
  });
}
