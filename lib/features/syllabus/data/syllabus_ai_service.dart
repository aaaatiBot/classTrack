import 'package:supabase_flutter/supabase_flutter.dart';

class ParsedChapterDraft {
  String title;
  int term;

  ParsedChapterDraft({
    required this.title,
    required this.term,
  });
}

class ParsedSubjectDraft {
  String name;
  List<ParsedChapterDraft> chapters;

  ParsedSubjectDraft({
    required this.name,
    required this.chapters,
  });
}

class SyllabusAiService {
  final SupabaseClient _client;

  SyllabusAiService(this._client);

  /// Sends extracted text to 'parse-syllabus' Edge Function and returns structured drafts
  Future<List<ParsedSubjectDraft>> parseSyllabusText(String text) async {
    final response = await _client.functions.invoke(
      'parse-syllabus',
      body: {'text': text},
    );

    if (response.status != 200) {
      final errorMsg = response.data?['error'] ?? 'Parsing failed (${response.status})';
      throw Exception(errorMsg);
    }

    final data = response.data;
    if (data['success'] != true || data['data'] == null) {
      throw Exception(data['error'] ?? 'Could not structure syllabus.');
    }

    final jsonContent = data['data'];
    final List<dynamic> terms = jsonContent['terms'] as List? ?? [];
    final Map<String, List<ParsedChapterDraft>> subjectMap = {};

    for (final termObj in terms) {
      final int termNum = (termObj['term'] as num?)?.toInt() ?? 1;
      final List<dynamic> subjects = termObj['subjects'] as List? ?? [];

      for (final s in subjects) {
        final String sName = (s['name'] as String?)?.trim() ?? 'General';
        final List<dynamic> chapters = s['chapters'] as List? ?? [];

        subjectMap.putIfAbsent(sName, () => []);

        for (final c in chapters) {
          final String title = c.toString().trim();
          if (title.isNotEmpty) {
            subjectMap[sName]!.add(
              ParsedChapterDraft(title: title, term: termNum),
            );
          }
        }
      }
    }

    return subjectMap.entries
        .map((e) => ParsedSubjectDraft(name: e.key, chapters: e.value))
        .toList();
  }
}
