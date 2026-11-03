import '../domain/result_model.dart';

class ReportCardParser {
  /// Heuristically extracts subject names and scored marks using regex patterns
  static List<ResultEntry> parseOcrText(String ocrText) {
    final List<ResultEntry> results = [];
    final lines = ocrText.split('\n');

    // Patterns matching formats like:
    // 1. "Mathematics: 85/100" or "Maths 85 / 100"
    // 2. "Science - 92 out of 100" or "Science: 92"
    // 3. "English   78.5"
    final patternFraction = RegExp(
      r'([a-zA-Z\s]{3,30})[:\s\-]+(\d{1,3}(?:\.\d+)?)\s*[\/|\\]\s*(\d{2,3})',
      caseSensitive: false,
    );

    final patternOutOf = RegExp(
      r'([a-zA-Z\s]{3,30})[:\s\-]+(\d{1,3}(?:\.\d+)?)\s+(?:out\s+of|of)\s+(\d{2,3})',
      caseSensitive: false,
    );

    final patternSimple = RegExp(
      r'([a-zA-Z\s]{3,30})[:\s\-]+(\d{1,3}(?:\.\d+)?)\b',
      caseSensitive: false,
    );

    final commonNonSubjects = {
      'total',
      'grade',
      'remarks',
      'result',
      'percentage',
      'name',
      'roll',
      'class',
      'date',
      'term',
      'school',
      'signature',
      'student',
      'academic',
      'session',
    };

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.length < 4) continue;

      // 1. Try fraction pattern (e.g. Maths 85/100)
      final matchFraction = patternFraction.firstMatch(trimmed);
      if (matchFraction != null) {
        final subject = matchFraction.group(1)!.trim();
        final marks = double.tryParse(matchFraction.group(2)!) ?? 0.0;
        final maxMarks = double.tryParse(matchFraction.group(3)!) ?? 100.0;

        if (!_isIgnoredWord(subject, commonNonSubjects)) {
          results.add(ResultEntry(subject: _cleanSubjectName(subject), marks: marks, maxMarks: maxMarks));
          continue;
        }
      }

      // 2. Try "out of" pattern
      final matchOutOf = patternOutOf.firstMatch(trimmed);
      if (matchOutOf != null) {
        final subject = matchOutOf.group(1)!.trim();
        final marks = double.tryParse(matchOutOf.group(2)!) ?? 0.0;
        final maxMarks = double.tryParse(matchOutOf.group(3)!) ?? 100.0;

        if (!_isIgnoredWord(subject, commonNonSubjects)) {
          results.add(ResultEntry(subject: _cleanSubjectName(subject), marks: marks, maxMarks: maxMarks));
          continue;
        }
      }

      // 3. Try simple pattern (e.g. Physics: 75)
      final matchSimple = patternSimple.firstMatch(trimmed);
      if (matchSimple != null) {
        final subject = matchSimple.group(1)!.trim();
        final marks = double.tryParse(matchSimple.group(2)!) ?? 0.0;

        if (!_isIgnoredWord(subject, commonNonSubjects) && marks <= 100) {
          results.add(ResultEntry(subject: _cleanSubjectName(subject), marks: marks, maxMarks: 100.0));
        }
      }
    }

    return results;
  }

  /// Detects term number (1, 2, or 3) from text heuristics
  static int detectTerm(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('3rd') ||
        lower.contains('third') ||
        lower.contains('term 3') ||
        lower.contains('term3') ||
        lower.contains('exam 3')) {
      return 3;
    }
    if (lower.contains('2nd') ||
        lower.contains('second') ||
        lower.contains('term 2') ||
        lower.contains('term2') ||
        lower.contains('exam 2')) {
      return 2;
    }
    final match = RegExp(r'\b([1-3])(?:st|nd|rd)?\b').firstMatch(lower);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 1;
    }
    return 1;
  }

  static bool _isIgnoredWord(String text, Set<String> ignored) {
    final lower = text.toLowerCase().trim();
    return ignored.any((word) => lower.contains(word));
  }

  static String _cleanSubjectName(String name) {
    return name
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
        .trim();
  }
}
