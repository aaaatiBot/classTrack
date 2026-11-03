import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/error_handler.dart';
import '../data/syllabus_ai_service.dart';
import 'syllabus_controller.dart';

class SyllabusReviewScreen extends ConsumerStatefulWidget {
  final List<ParsedSubjectDraft> initialDrafts;
  final String studentId;

  const SyllabusReviewScreen({
    super.key,
    required this.initialDrafts,
    required this.studentId,
  });

  @override
  ConsumerState<SyllabusReviewScreen> createState() => _SyllabusReviewScreenState();
}

class _SyllabusReviewScreenState extends ConsumerState<SyllabusReviewScreen> {
  late List<ParsedSubjectDraft> _drafts;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _drafts = widget.initialDrafts;
  }

  void _renameSubject(int subjectIndex) {
    final controller = TextEditingController(text: _drafts[subjectIndex].name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Subject Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() => _drafts[subjectIndex].name = newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addSubject() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Missing Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Subject Name',
            hintText: 'e.g., Biology',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _drafts.add(ParsedSubjectDraft(name: name, chapters: []));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addChapter(int subjectIndex) {
    final titleController = TextEditingController();
    int term = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Chapter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Chapter Title',
                  hintText: 'e.g., Photosynthesis',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Term', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('Term 1')),
                  ButtonSegment(value: 2, label: Text('Term 2')),
                  ButtonSegment(value: 3, label: Text('Term 3')),
                ],
                selected: {term},
                onSelectionChanged: (set) => setDlgState(() => term = set.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  setState(() {
                    _drafts[subjectIndex].chapters.add(
                          ParsedChapterDraft(title: title, term: term),
                        );
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editChapter(int subjectIndex, int chapterIndex) {
    final chapter = _drafts[subjectIndex].chapters[chapterIndex];
    final titleController = TextEditingController(text: chapter.title);
    int term = chapter.term;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Edit Chapter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              const Text('Academic Term', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('Term 1')),
                  ButtonSegment(value: 2, label: Text('Term 2')),
                  ButtonSegment(value: 3, label: Text('Term 3')),
                ],
                selected: {term},
                onSelectionChanged: (set) => setDlgState(() => term = set.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _drafts[subjectIndex].chapters.removeAt(chapterIndex);
                });
                Navigator.pop(ctx);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  setState(() {
                    chapter.title = title;
                    chapter.term = term;
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndConfirm() async {
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(syllabusRepositoryProvider);
      // Fetch existing subjects to merge and avoid duplicates (FR-4.5)
      final existingSubjects = await repo.getStudentSyllabus(widget.studentId);
      final Map<String, String> existingMap = {
        for (final s in existingSubjects) s.name.trim().toLowerCase(): s.id,
      };

      for (final draftSubject in _drafts) {
        final key = draftSubject.name.trim().toLowerCase();
        String subjectId;

        if (existingMap.containsKey(key)) {
          // Merge with existing subject
          subjectId = existingMap[key]!;
        } else {
          // Create new subject
          final created = await repo.addSubject(
            studentId: widget.studentId,
            name: draftSubject.name.trim(),
          );
          subjectId = created.id;
          existingMap[key] = subjectId;
        }

        // Add chapters to subject
        for (final draftChapter in draftSubject.chapters) {
          await repo.addChapter(
            subjectId: subjectId,
            title: draftChapter.title.trim(),
            term: draftChapter.term,
          );
        }
      }

      ref.invalidate(studentSyllabusProvider(widget.studentId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Syllabus imported and saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    int totalChapters = 0;
    for (final s in _drafts) {
      totalChapters += s.chapters.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Extracted Syllabus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Subject',
            onPressed: _addSubject,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: colorScheme.primaryContainer.withValues(alpha: 0.4),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Review and edit items below. You can rename, change terms, or delete chapters before saving.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _drafts.isEmpty
                ? Center(
                    child: Text(
                      'No subjects extracted. Tap + to add items manually.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _drafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, sIdx) {
                      final subject = _drafts[sIdx];
                      return Card(
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  subject.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => _renameSubject(sIdx),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.red, size: 18),
                                onPressed: () {
                                  setState(() => _drafts.removeAt(sIdx));
                                },
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${subject.chapters.length} chapters',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          children: [
                            ...subject.chapters.asMap().entries.map((entry) {
                              final cIdx = entry.key;
                              final chapter = entry.value;

                              return ListTile(
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'T${chapter.term}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                title: Text(chapter.title),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _editChapter(sIdx, cIdx),
                                ),
                              );
                            }),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextButton.icon(
                                onPressed: () => _addChapter(sIdx),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add Missing Chapter'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _saveAndConfirm,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(_isSaving
                ? 'Saving...'
                : 'Confirm & Save ($totalChapters chapters)'),
          ),
        ),
      ),
    );
  }
}
