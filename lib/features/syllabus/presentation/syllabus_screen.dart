import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../core/utils/error_handler.dart';
import '../data/syllabus_ai_service.dart';
import '../domain/syllabus_models.dart';
import '../utils/document_text_extractor.dart';
import 'syllabus_controller.dart';
import 'syllabus_review_screen.dart';

class SyllabusScreen extends ConsumerWidget {
  final String? studentIdOverride; // When admin views student's syllabus (read-only)
  final String? studentName;

  const SyllabusScreen({
    super.key,
    this.studentIdOverride,
    this.studentName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final currentUserId = authState.userProfile?.id ?? '';
    final studentId = studentIdOverride ?? currentUserId;
    final isReadOnly = studentIdOverride != null || authState.isAdmin;

    final syllabusAsync = ref.watch(studentSyllabusProvider(studentId));
    final selectedTerm = ref.watch(selectedTermFilterProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          studentName != null ? "$studentName's Syllabus" : 'My Syllabus',
        ),
        actions: [
          if (!isReadOnly) ...[
            IconButton(
              icon: const Icon(Icons.document_scanner_rounded),
              tooltip: 'Import Syllabus (PDF / Photo)',
              onPressed: () => _handleImportSyllabus(context, ref, studentId),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add Subject',
              onPressed: () => _showAddSubjectDialog(context, ref, studentId),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Term Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Row(
              children: [
                _buildTermChip(ref, null, 'All Terms', selectedTerm == null),
                const SizedBox(width: 8),
                _buildTermChip(ref, 1, '1st Term', selectedTerm == 1),
                const SizedBox(width: 8),
                _buildTermChip(ref, 2, '2nd Term', selectedTerm == 2),
                const SizedBox(width: 8),
                _buildTermChip(ref, 3, '3rd Term', selectedTerm == 3),
              ],
            ),
          ),

          // Main Syllabus Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(studentSyllabusProvider(studentId)),
              child: syllabusAsync.when(
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_stories_outlined,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No subjects created yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isReadOnly
                                      ? 'This student has not added any syllabus chapters.'
                                      : 'Tap "+ Add Subject" to build your syllabus manually\nor import from PDF/photo in Phase 5.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                                ),
                                if (!isReadOnly) ...[
                                  const SizedBox(height: 20),
                                  FilledButton.icon(
                                    onPressed: () =>
                                        _showAddSubjectDialog(context, ref, studentId),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Add First Subject'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final overallProgress =
                      ref.watch(syllabusProgressProvider(subjects));

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Overall Progress Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedTerm == null
                                        ? 'Overall Syllabus Completion'
                                        : 'Term $selectedTerm Completion',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${overallProgress.percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: overallProgress.totalChapters > 0
                                    ? overallProgress.completedChapters /
                                        overallProgress.totalChapters
                                    : 0,
                                borderRadius: BorderRadius.circular(6),
                                minHeight: 8,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${overallProgress.completedChapters} of ${overallProgress.totalChapters} chapters completed',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // List of Subject ExpansionTiles
                      ...subjects.map((subject) {
                        final chapters = subject.chaptersForTerm(selectedTerm);
                        final completedCount =
                            chapters.where((c) => c.isComplete).length;
                        final double progress = chapters.isNotEmpty
                            ? (completedCount / chapters.length)
                            : 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.primary,
                              child: Text(
                                subject.name.isNotEmpty
                                    ? subject.name[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              subject.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 5,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$completedCount / ${chapters.length} chapters done (${(progress * 100).toStringAsFixed(0)}%)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: isReadOnly
                                ? null
                                : PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded),
                                    onSelected: (val) {
                                      if (val == 'add') {
                                        _showAddChapterDialog(context, ref, subject.id, studentId);
                                      } else if (val == 'rename') {
                                        _showRenameSubjectDialog(context, ref, subject, studentId);
                                      } else if (val == 'delete') {
                                        _handleDeleteSubject(context, ref, subject, studentId);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'add',
                                        child: Row(
                                          children: [
                                            Icon(Icons.add_rounded, size: 18),
                                            SizedBox(width: 8),
                                            Text('Add Chapter'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'rename',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('Rename Subject'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline_rounded,
                                                color: Colors.red, size: 18),
                                            SizedBox(width: 8),
                                            Text('Delete Subject',
                                                style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                            children: [
                              if (chapters.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      selectedTerm == null
                                          ? 'No chapters in this subject yet.'
                                          : 'No chapters tagged for Term $selectedTerm.',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...chapters.map((chapter) {
                                  return ListTile(
                                    leading: Checkbox(
                                      value: chapter.isComplete,
                                      onChanged: isReadOnly
                                          ? null
                                          : (val) {
                                              if (val != null) {
                                                _toggleChapter(ref, chapter.id, val, studentId);
                                              }
                                            },
                                    ),
                                    title: Text(
                                      chapter.title,
                                      style: TextStyle(
                                        decoration: chapter.isComplete
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: chapter.isComplete
                                            ? colorScheme.onSurfaceVariant
                                            : null,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.tertiaryContainer,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Term ${chapter.term}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onTertiaryContainer,
                                            ),
                                          ),
                                        ),
                                        if (chapter.isComplete && chapter.completedOn != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            'Done ${DateFormat('d MMM').format(chapter.completedOn!)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: isReadOnly
                                        ? null
                                        : IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            onPressed: () => _showEditChapterDialog(
                                              context,
                                              ref,
                                              chapter,
                                              studentId,
                                            ),
                                          ),
                                  );
                                }),
                              if (!isReadOnly)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () => _showAddChapterDialog(
                                          context, ref, subject.id, studentId),
                                      icon: const Icon(Icons.add_rounded, size: 18),
                                      label: const Text('Add Chapter'),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text(ErrorHandler.getFriendlyErrorMessage(err)),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isReadOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddSubjectDialog(context, ref, studentId),
              icon: const Icon(Icons.book_rounded),
              label: const Text('Add Subject'),
            ),
    );
  }

  Widget _buildTermChip(WidgetRef ref, int? term, String label, bool isSelected) {
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        ref.read(selectedTermFilterProvider.notifier).state = term;
      },
    );
  }

  Future<void> _toggleChapter(
    WidgetRef ref,
    String chapterId,
    bool isComplete,
    String studentId,
  ) async {
    final repo = ref.read(syllabusRepositoryProvider);
    await repo.toggleChapterCompletion(
      chapterId: chapterId,
      isComplete: isComplete,
    );
    ref.invalidate(studentSyllabusProvider(studentId));
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref, String studentId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Subject Name',
            hintText: 'e.g., Mathematics, Physics, History',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final repo = ref.read(syllabusRepositoryProvider);
              await repo.addSubject(studentId: studentId, name: name);
              ref.invalidate(studentSyllabusProvider(studentId));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRenameSubjectDialog(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
    String studentId,
  ) {
    final controller = TextEditingController(text: subject.name);
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
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final repo = ref.read(syllabusRepositoryProvider);
              await repo.renameSubject(subject.id, name);
              ref.invalidate(studentSyllabusProvider(studentId));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteSubject(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
    String studentId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${subject.name}?'),
        content: const Text(
          'This will permanently delete this subject and all its chapters.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(syllabusRepositoryProvider);
      await repo.deleteSubject(subject.id);
      ref.invalidate(studentSyllabusProvider(studentId));
    }
  }

  void _showAddChapterDialog(
    BuildContext context,
    WidgetRef ref,
    String subjectId,
    String studentId,
  ) {
    final titleController = TextEditingController();
    int selectedTerm = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                  hintText: 'e.g., Chapter 1: Quadratic Equations',
                ),
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
                selected: {selectedTerm},
                onSelectionChanged: (set) => setState(() => selectedTerm = set.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(ctx);
                final repo = ref.read(syllabusRepositoryProvider);
                await repo.addChapter(
                  subjectId: subjectId,
                  title: title,
                  term: selectedTerm,
                );
                ref.invalidate(studentSyllabusProvider(studentId));
              },
              child: const Text('Add Chapter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditChapterDialog(
    BuildContext context,
    WidgetRef ref,
    Chapter chapter,
    String studentId,
  ) {
    final titleController = TextEditingController(text: chapter.title);
    int selectedTerm = chapter.term;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Chapter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Chapter Title'),
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
                selected: {selectedTerm},
                onSelectionChanged: (set) => setState(() => selectedTerm = set.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final repo = ref.read(syllabusRepositoryProvider);
                await repo.deleteChapter(chapter.id);
                ref.invalidate(studentSyllabusProvider(studentId));
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(ctx);
                final repo = ref.read(syllabusRepositoryProvider);
                await repo.updateChapter(
                  chapterId: chapter.id,
                  title: title,
                  term: selectedTerm,
                );
                ref.invalidate(studentSyllabusProvider(studentId));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImportSyllabus(
    BuildContext context,
    WidgetRef ref,
    String studentId,
  ) async {
    // Show picker choice: PDF or Photo
    final source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                title: const Text('Pick PDF Document'),
                subtitle: const Text('Extracts text layer or renders scanned pages'),
                onTap: () => Navigator.pop(ctx, 'pdf'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                title: const Text('Pick Image from Gallery'),
                subtitle: const Text('Runs on-device ML Kit OCR'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.green),
                title: const Text('Take Photo with Camera'),
                subtitle: const Text('Photograph textbook syllabus'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !context.mounted) return;

    File? file;
    if (source == 'pdf') {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (files.isNotEmpty && files.first.path != null) {
        file = File(files.first.path!);
      }
    } else {
      final picker = ImagePicker();
      final img = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 2048,
      );
      if (img != null) {
        file = File(img.path);
      }
    }

    if (file == null || !context.mounted) return;

    // Show Progress Dialog
    String status = 'Extracting text from document...';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final extractedText = await DocumentTextExtractor.extractTextFromFile(file);

      if (extractedText.trim().isEmpty) {
        throw Exception(
          'Could not extract text from this document. Please ensure the image is clear or enter the syllabus manually.',
        );
      }

      final aiService = SyllabusAiService(Supabase.instance.client);
      final drafts = await aiService.parseSyllabusText(extractedText);

      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog

        if (drafts.isEmpty) {
          throw Exception('No subjects or chapters recognized in this document.');
        }

        // Navigate to Editable Review Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SyllabusReviewScreen(
              initialDrafts: drafts,
              studentId: studentId,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('AI Import Unavailable'),
            content: Text(
              '${ErrorHandler.getFriendlyErrorMessage(e)}\n\nWould you like to add subjects and chapters manually?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAddSubjectDialog(context, ref, studentId);
                },
                child: const Text('Add Manually'),
              ),
            ],
          ),
        );
      }
    }
  }
}
