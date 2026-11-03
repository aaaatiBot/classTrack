import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/error_handler.dart';
import '../../syllabus/utils/document_text_extractor.dart';
import '../domain/test_routine_model.dart';
import '../utils/test_routine_parser.dart';
import 'tests_controller.dart';

class TestsScreen extends ConsumerStatefulWidget {
  final String? studentIdOverride;
  final String? studentName;

  const TestsScreen({
    super.key,
    this.studentIdOverride,
    this.studentName,
  });

  @override
  ConsumerState<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends ConsumerState<TestsScreen> {
  final DateFormat _dateFormat = DateFormat('EEE, dd MMM yyyy');
  final ImagePicker _picker = ImagePicker();

  String _getDaysRemainingBadge(DateTime testDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(testDate.year, testDate.month, testDate.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) {
      return 'Completed';
    } else if (diff == 0) {
      return 'Today!';
    } else if (diff == 1) {
      return 'Tomorrow';
    } else {
      return 'In $diff days';
    }
  }

  Color _getBadgeColor(BuildContext context, DateTime testDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(testDate.year, testDate.month, testDate.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) {
      return Colors.grey;
    } else if (diff == 0) {
      return Colors.red;
    } else if (diff == 1) {
      return Colors.orange;
    } else if (diff <= 3) {
      return Colors.amber.shade800;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  Future<void> _handleScanRoutine() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo of Routine'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(source: source);
    if (picked == null || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Scanning routine sheet with OCR...')),
    );

    try {
      final text = await DocumentTextExtractor.extractTextFromFile(File(picked.path));
      if (!mounted) return;

      if (text.trim().isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No text recognized from the image.')),
        );
        return;
      }

      final parsed = TestRoutineParser.parseOcrText(text);
      if (parsed.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Could not detect routine dates or subjects. Please enter manually.')),
        );
        return;
      }

      await _showReviewScannedRoutineSheet(parsed);
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    }
  }

  Future<void> _showReviewScannedRoutineSheet(List<ParsedTestDraft> items) async {
    final controller = ref.read(testsControllerProvider(widget.studentIdOverride).notifier);
    final editableItems = List<ParsedTestDraft>.from(items);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.document_scanner, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Scanned Routine Preview',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Text(
                    'Review and adjust detected tests before adding them to your schedule. Reminders will be set automatically.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const Divider(height: 24),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: editableItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = editableItems[index];
                        return Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item.subjectName,
                                        decoration: const InputDecoration(
                                          labelText: 'Subject',
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (val) {
                                          item.subjectName = val;
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () {
                                        setSheetState(() {
                                          editableItems.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.calendar_today, size: 16),
                                        label: Text(_dateFormat.format(item.testDate)),
                                        onPressed: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: item.testDate,
                                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                            lastDate: DateTime.now().add(const Duration(days: 365)),
                                          );
                                          if (picked != null) {
                                            setSheetState(() {
                                              item.testDate = picked;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: item.topics ?? '',
                                  decoration: const InputDecoration(
                                    labelText: 'Portion / Topics (Optional)',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (val) {
                                    item.topics = val.trim().isEmpty ? null : val.trim();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text('Save ${editableItems.length} Tests to Routine'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: editableItems.isEmpty
                        ? null
                        : () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            Navigator.pop(ctx);
                            final routineItems = editableItems
                                .map((e) => TestRoutineItem(
                                      id: '',
                                      studentId: '',
                                      testDate: e.testDate,
                                      subjectName: e.subjectName,
                                      topics: e.topics,
                                      createdAt: DateTime.now(),
                                    ))
                                .toList();

                            final success = await controller.addMultipleTests(routineItems);
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Saved routine with automated reminder notifications!'
                                        : 'Failed to save scanned routine.',
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddOrEditDialog([TestRoutineItem? existing]) async {
    final controller = ref.read(testsControllerProvider(widget.studentIdOverride).notifier);
    final subjectController = TextEditingController(text: existing?.subjectName ?? '');
    final topicsController = TextEditingController(text: existing?.topics ?? '');
    DateTime selectedDate = existing?.testDate ?? DateTime.now().add(const Duration(days: 1));
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Test Routine' : 'Edit Test Routine'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject Name',
                          prefixIcon: Icon(Icons.book),
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Enter subject name' : null,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_month),
                        title: const Text('Test Date'),
                        subtitle: Text(_dateFormat.format(selectedDate)),
                        trailing: const Icon(Icons.edit_calendar),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: topicsController,
                        decoration: const InputDecoration(
                          labelText: 'Topics / Chapters / Portion',
                          prefixIcon: Icon(Icons.topic),
                          hintText: 'e.g. Chapter 1 to 3',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    if (existing == null) {
                      await controller.addTest(
                        testDate: selectedDate,
                        subjectName: subjectController.text,
                        topics: topicsController.text.trim().isEmpty ? null : topicsController.text,
                      );
                    } else {
                      await controller.updateTest(
                        testId: existing.id,
                        oldNotificationId: existing.notificationId,
                        testDate: selectedDate,
                        subjectName: subjectController.text,
                        topics: topicsController.text.trim().isEmpty ? null : topicsController.text,
                      );
                    }
                  },
                  child: Text(existing == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(TestRoutineItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Test?'),
        content: Text(
          'Delete upcoming ${item.subjectName} test on ${_dateFormat.format(item.testDate)}?\n\nThis will also cancel its scheduled notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(testsControllerProvider(widget.studentIdOverride).notifier)
          .deleteTest(item.id, item.notificationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(testsControllerProvider(widget.studentIdOverride));
    final isReadOnly = widget.studentIdOverride != null;

    final upcomingTests = state.tests.where((t) => t.isUpcoming).toList();
    final pastTests = state.tests.where((t) => !t.isUpcoming).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName != null ? '${widget.studentName} - Routine' : 'Test Routine & Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(testsControllerProvider(widget.studentIdOverride).notifier).loadTests();
            },
          ),
        ],
      ),
      floatingActionButton: isReadOnly
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'scan_routine_btn',
                  onPressed: _handleScanRoutine,
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('Scan Routine'),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'add_routine_btn',
                  onPressed: () => _showAddOrEditDialog(),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(ErrorHandler.friendlyMessage(state.errorMessage!)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(testsControllerProvider(widget.studentIdOverride).notifier)
                            .loadTests(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.tests.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 72,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Tests Scheduled',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Scan your school test routine sheet using camera or add upcoming tests manually.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            if (!isReadOnly)
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.document_scanner),
                                    label: const Text('Scan Routine Sheet'),
                                    onPressed: _handleScanRoutine,
                                  ),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Test Manually'),
                                    onPressed: () => _showAddOrEditDialog(),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (upcomingTests.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.alarm, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Upcoming Tests (${upcomingTests.length})',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...upcomingTests.map((t) => _buildTestCard(t, isPast: false, isReadOnly: isReadOnly)),
                          const SizedBox(height: 24),
                        ],
                        if (pastTests.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.history, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Past Tests (${pastTests.length})',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...pastTests.map((t) => _buildTestCard(t, isPast: true, isReadOnly: isReadOnly)),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
    );
  }

  Widget _buildTestCard(TestRoutineItem item, {required bool isPast, required bool isReadOnly}) {
    final badgeText = _getDaysRemainingBadge(item.testDate);
    final badgeColor = _getBadgeColor(context, item.testDate);

    return Opacity(
      opacity: isPast ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isPast ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isPast ? Colors.grey.shade300 : badgeColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subjectName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            decoration: isPast ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              _dateFormat.format(item.testDate),
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: badgeColor),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.topics != null && item.topics!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.topic_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.topics!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (!isReadOnly) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      onPressed: () => _showAddOrEditDialog(item),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      onPressed: () => _confirmDelete(item),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
