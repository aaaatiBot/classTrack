import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/error_handler.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../students/presentation/students_controller.dart';
import '../domain/note_model.dart';
import 'notes_controller.dart';

class NotesScreen extends ConsumerWidget {
  final bool isAdmin;

  const NotesScreen({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final userIsAdmin = isAdmin || authState.isAdmin;
    final notesAsync = ref.watch(notesListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(userIsAdmin ? 'Study Notes (Admin)' : 'Study Materials'),
      ),
      body: Column(
        children: [
          // Filter bar
          _buildFilterBar(ref),

          // Notes list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(notesListProvider),
              child: notesAsync.when(
                data: (notes) {
                  if (notes.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open_rounded,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No study notes uploaded yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  userIsAdmin
                                      ? 'Tap "+ Upload Notes" to share PDFs or images with students.'
                                      : 'Your teacher has not uploaded study materials for this subject yet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _NoteCard(note: note, isAdmin: userIsAdmin);
                    },
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
      floatingActionButton: userIsAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showUploadDialog(context, ref),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload Notes'),
            )
          : null,
    );
  }

  Widget _buildFilterBar(WidgetRef ref) {
    final batchesAsync = ref.watch(classBatchesProvider);
    final selectedBatch = ref.watch(notesBatchFilterProvider);

    return batchesAsync.when(
      data: (batches) {
        if (batches.length <= 1) return const SizedBox.shrink();
        return SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: batches.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final batch = batches[index];
              return FilterChip(
                selected: selectedBatch == batch,
                label: Text(batch),
                onSelected: (_) {
                  ref.read(notesBatchFilterProvider.notifier).state = batch;
                },
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showUploadDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _UploadNoteSheet(),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final NoteModel note;
  final bool isAdmin;

  const _NoteCard({required this.note, required this.isAdmin});

  Future<void> _openNote(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(notesRepositoryProvider);
      final signedUrl = await repo.getSignedUrl(note.filePath);
      final uri = Uri.parse(signedUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file URL')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getFriendlyErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _deleteNote(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note?'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
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
      final repo = ref.read(notesRepositoryProvider);
      await repo.deleteNote(note.id, note.filePath);
      ref.invalidate(notesListProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: note.isPdf
              ? Colors.red.withValues(alpha: 0.15)
              : Colors.blue.withValues(alpha: 0.15),
          foregroundColor: note.isPdf ? Colors.red : Colors.blue,
          child: Icon(
            note.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
          ),
        ),
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    note.subjectName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (note.classBatch != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '• ${note.classBatch}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  DateFormat('d MMM yyyy').format(note.uploadedOn),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Download / View',
              onPressed: () => _openNote(context, ref),
            ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                tooltip: 'Delete',
                onPressed: () => _deleteNote(context, ref),
              ),
          ],
        ),
        onTap: () => _openNote(context, ref),
      ),
    );
  }
}

class _UploadNoteSheet extends ConsumerStatefulWidget {
  const _UploadNoteSheet();

  @override
  ConsumerState<_UploadNoteSheet> createState() => _UploadNoteSheetState();
}

class _UploadNoteSheetState extends ConsumerState<_UploadNoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _titleController = TextEditingController();
  final _batchController = TextEditingController();

  String? _pickedFileName;
  List<int>? _pickedFileBytes;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        setState(() {
          _pickedFileName = file.name;
          _pickedFileBytes = file.bytes;
          if (_titleController.text.isEmpty) {
            _titleController.text = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
          }
        });
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      imageQuality: 80, // Compress image to stay within free plan storage
    );

    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() {
        _pickedFileName = photo.name;
        _pickedFileBytes = bytes;
        if (_titleController.text.isEmpty) {
          _titleController.text = 'Photo Note ${DateFormat('d MMM').format(DateTime.now())}';
        }
      });
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFileBytes == null || _pickedFileName == null) {
      setState(() => _error = 'Please select a PDF file or photo to upload');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(notesRepositoryProvider);
      await repo.uploadNote(
        subjectName: _subjectController.text.trim(),
        title: _titleController.text.trim(),
        fileName: _pickedFileName!,
        fileBytes: Uint8List.fromList(_pickedFileBytes!),
        classBatch: _batchController.text.trim(),
      );

      ref.invalidate(notesListProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = ErrorHandler.getFriendlyErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upload Study Material',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // File Selection Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file_rounded),
                      label: const Text('Pick PDF / Image'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt_rounded),
                    tooltip: 'Take photo of notes',
                  ),
                ],
              ),
              if (_pickedFileName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _pickedFileName!,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Note Title *',
                  hintText: 'e.g., Chapter 3 Formulas & Summary',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter note title'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  hintText: 'e.g., Chemistry',
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter subject name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _batchController,
                decoration: const InputDecoration(
                  labelText: 'Class / Batch (Optional)',
                  hintText: 'e.g., Class 10 - Batch A',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: _isLoading ? null : _handleUpload,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Upload Note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
