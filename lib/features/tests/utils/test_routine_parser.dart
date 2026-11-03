class ParsedTestDraft {
  DateTime testDate;
  String subjectName;
  String? topics;

  ParsedTestDraft({
    required this.testDate,
    required this.subjectName,
    this.topics,
  });
}

class TestRoutineParser {
  /// Heuristically extracts test dates and subjects from OCR text lines
  static List<ParsedTestDraft> parseOcrText(String ocrText) {
    final List<ParsedTestDraft> items = [];
    final lines = ocrText.split('\n');

    // Date regex patterns
    // 1. DD/MM/YYYY or DD-MM-YYYY
    final datePattern1 = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})');
    // 2. DD Mon YYYY (e.g. 15 Nov or 15 November 2026)
    final datePattern2 = RegExp(
      r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*(\d{4})?',
      caseSensitive: false,
    );

    final monthMap = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.length < 5) continue;

      DateTime? parsedDate;
      String remainingText = trimmed;

      // Try numeric date
      final match1 = datePattern1.firstMatch(trimmed);
      if (match1 != null) {
        int day = int.parse(match1.group(1)!);
        int month = int.parse(match1.group(2)!);
        int year = int.parse(match1.group(3)!);
        if (year < 100) year += 2000;

        try {
          parsedDate = DateTime(year, month, day);
          remainingText = trimmed.replaceFirst(match1.group(0)!, '').trim();
        } catch (_) {}
      }

      // Try named month date
      if (parsedDate == null) {
        final match2 = datePattern2.firstMatch(trimmed);
        if (match2 != null) {
          int day = int.parse(match2.group(1)!);
          String monStr = match2.group(2)!.toLowerCase();
          int month = monthMap[monStr] ?? 1;
          int year = match2.group(3) != null
              ? int.parse(match2.group(3)!)
              : DateTime.now().year;

          try {
            parsedDate = DateTime(year, month, day);
            remainingText = trimmed.replaceFirst(match2.group(0)!, '').trim();
          } catch (_) {}
        }
      }

      if (parsedDate != null && remainingText.isNotEmpty) {
        // Clean remaining text as subject name and topics
        final cleaned = remainingText
            .replaceAll(RegExp(r'^[:\-\|\s]+'), '')
            .trim();

        if (cleaned.length >= 2) {
          String subject = cleaned;
          String? topic;

          if (cleaned.contains('-')) {
            final parts = cleaned.split('-');
            subject = parts[0].trim();
            topic = parts.sublist(1).join('-').trim();
          } else if (cleaned.contains(':')) {
            final parts = cleaned.split(':');
            subject = parts[0].trim();
            topic = parts.sublist(1).join(':').trim();
          }

          items.add(ParsedTestDraft(
            testDate: parsedDate,
            subjectName: subject,
            topics: topic,
          ));
        }
      }
    }

    return items;
  }
}
