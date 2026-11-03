import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/error_handler.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../students/presentation/students_controller.dart';
import '../domain/test_score_model.dart';
import 'test_scores_controller.dart';

class TestScoresScreen extends ConsumerStatefulWidget {
  final String? studentIdOverride;
  final String? studentName;

  const TestScoresScreen({
    super.key,
    this.studentIdOverride,
    this.studentName,
  });

  @override
  ConsumerState<TestScoresScreen> createState() => _TestScoresScreenState();
}

class _TestScoresScreenState extends ConsumerState<TestScoresScreen> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  Color _getScoreColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green;
    } else if (percentage >= 50) {
      return Colors.amber.shade800;
    } else {
      return Colors.red;
    }
  }

  Future<void> _showAddSingleScoreDialog() async {
    final authState = ref.read(authControllerProvider);
    final studentsAsync = ref.read(studentsListProvider);
    final List<UserProfile> students = studentsAsync.value ?? [];
    final controller = ref.read(testScoresControllerProvider(widget.studentIdOverride).notifier);

    final formKey = GlobalKey<FormState>();
    String? selectedStudentId = widget.studentIdOverride ??
        (students.isNotEmpty ? students.first.id : null);
    final subjectController = TextEditingController();
    final titleController = TextEditingController();
    final marksController = TextEditingController();
    final maxMarksController = TextEditingController(text: '20');
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Test Score'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.studentIdOverride == null) ...[
                        DropdownButtonFormField<String>(
                          initialValue: selectedStudentId,
                          decoration: const InputDecoration(
                            labelText: 'Student',
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: students
                              .map((s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text('${s.name} (${s.classBatch ?? 'General'})'),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedStudentId = val;
                            });
                          },
                          validator: (val) => val == null ? 'Select student' : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject Name',
                          prefixIcon: Icon(Icons.book),
                          hintText: 'e.g. Mathematics',
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Enter subject name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Test Title',
                          prefixIcon: Icon(Icons.edit_note),
                          hintText: 'e.g. Unit Test 1',
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Enter test title' : null,
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
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: marksController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Marks Scored',
                                prefixIcon: Icon(Icons.score),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter marks';
                                final num = double.tryParse(val);
                                if (num == null || num < 0) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: maxMarksController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Max Marks',
                                prefixIcon: Icon(Icons.star),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter max';
                                final num = double.tryParse(val);
                                if (num == null || num <= 0) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                        ],
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
                    if (!formKey.currentState!.validate() || selectedStudentId == null) return;
                    Navigator.pop(ctx);
                    await controller.addScore(
                      studentId: selectedStudentId!,
                      subjectName: subjectController.text,
                      title: titleController.text,
                      testDate: selectedDate,
                      marks: double.parse(marksController.text),
                      maxMarks: double.parse(maxMarksController.text),
                      enteredBy: authState.userProfile?.id,
                    );
                  },
                  child: const Text('Add Score'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showBulkBatchEntryDialog() async {
    final authState = ref.read(authControllerProvider);
    final studentsAsync = ref.read(studentsListProvider);
    final List<UserProfile> students = studentsAsync.value ?? [];
    final controller = ref.read(testScoresControllerProvider(widget.studentIdOverride).notifier);

    // Get unique batches
    final batches = students
        .map((s) => s.classBatch ?? 'General')
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (batches.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students found to enter batch scores.')),
      );
      return;
    }

    String selectedBatch = batches.first;
    final subjectController = TextEditingController();
    final titleController = TextEditingController(text: 'Class Test 1');
    final maxMarksController = TextEditingController(text: '20');
    DateTime selectedDate = DateTime.now();

    final marksControllers = <String, TextEditingController>{};
    for (final s in students) {
      marksControllers[s.id] = TextEditingController();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final batchStudents = students
                .where((s) => (s.classBatch ?? 'General') == selectedBatch && s.active)
                .toList();

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
                      const Icon(Icons.groups, color: Colors.indigo),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Bulk Score Entry by Batch',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedBatch,
                          decoration: const InputDecoration(
                            labelText: 'Batch',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: batches
                              .map((b) => DropdownMenuItem(value: b, child: Text('Batch $b')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                selectedBatch = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Test Title',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: maxMarksController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max Marks',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Date: ${_dateFormat.format(selectedDate)}'),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            setSheetState(() => selectedDate = picked);
                          }
                        },
                        child: const Text('Change Date'),
                      ),
                    ],
                  ),
                  const Divider(),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: batchStudents.isEmpty
                        ? const Center(child: Text('No active students in this batch.'))
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: batchStudents.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final student = batchStudents[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      child: Text(
                                        student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            student.username,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 90,
                                      child: TextFormField(
                                        controller: marksControllers[student.id],
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textAlign: TextAlign.center,
                                        decoration: const InputDecoration(
                                          hintText: 'Marks',
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Submit Batch Scores'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final subject = subjectController.text.trim();
                      final title = titleController.text.trim();
                      final maxMarks = double.tryParse(maxMarksController.text) ?? 20.0;

                      if (subject.isEmpty || title.isEmpty) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Please enter Subject and Test Title.')),
                        );
                        return;
                      }

                      final List<Map<String, dynamic>> records = [];
                      for (final s in batchStudents) {
                        final valText = marksControllers[s.id]?.text.trim() ?? '';
                        if (valText.isNotEmpty) {
                          final marks = double.tryParse(valText);
                          if (marks != null) {
                            records.add({
                              'student_id': s.id,
                              'subject_name': subject,
                              'title': title,
                              'test_date':
                                  "${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                              'marks': marks,
                              'max_marks': maxMarks,
                              if (authState.userProfile?.id != null)
                                'entered_by': authState.userProfile!.id,
                            });
                          }
                        }
                      }

                      if (records.isEmpty) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Please enter marks for at least one student.')),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      final success = await controller.bulkAddScores(records);
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Saved scores for ${records.length} students!'
                                : 'Failed to save scores.',
                          ),
                        ),
                      );
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

  Future<void> _showEditScoreDialog(TestScoreItem item) async {
    final controller = ref.read(testScoresControllerProvider(widget.studentIdOverride).notifier);
    final subjectController = TextEditingController(text: item.subjectName);
    final titleController = TextEditingController(text: item.title);
    final marksController = TextEditingController(text: item.marks.toString());
    final maxMarksController = TextEditingController(text: item.maxMarks.toString());
    DateTime selectedDate = item.testDate;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Test Score'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: subjectController,
                        decoration: const InputDecoration(labelText: 'Subject Name'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter subject' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Test Title'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter title' : null,
                      ),
                      const SizedBox(height: 8),
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
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: marksController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Marks'),
                              validator: (val) => double.tryParse(val ?? '') == null ? 'Invalid' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: maxMarksController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Max Marks'),
                              validator: (val) => double.tryParse(val ?? '') == null ? 'Invalid' : null,
                            ),
                          ),
                        ],
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
                    await controller.updateScore(
                      id: item.id,
                      subjectName: subjectController.text,
                      title: titleController.text,
                      testDate: selectedDate,
                      marks: double.parse(marksController.text),
                      maxMarks: double.parse(maxMarksController.text),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(TestScoreItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Test Score?'),
        content: Text('Delete ${item.title} (${item.subjectName}) with score ${item.marks}/${item.maxMarks}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(testScoresControllerProvider(widget.studentIdOverride).notifier).deleteScore(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.userProfile?.isAdmin ?? false;
    final state = ref.watch(testScoresControllerProvider(widget.studentIdOverride));

    // Get unique subjects for filtering
    final subjects = {'All', ...state.scores.map((s) => s.subjectName)}.toList();

    // Calculate averages
    final totalMarks = state.scores.fold(0.0, (sum, s) => sum + s.marks);
    final totalMax = state.scores.fold(0.0, (sum, s) => sum + s.maxMarks);
    final overallPct = totalMax > 0 ? (totalMarks / totalMax) * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName != null ? '${widget.studentName} - Scores' : 'Class Test Scores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(testScoresControllerProvider(widget.studentIdOverride).notifier).loadScores();
            },
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'bulk_score_btn',
                  onPressed: _showBulkBatchEntryDialog,
                  icon: const Icon(Icons.groups),
                  label: const Text('Bulk Batch Entry'),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'add_score_btn',
                  onPressed: _showAddSingleScoreDialog,
                  child: const Icon(Icons.add),
                ),
              ],
            )
          : null,
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
                            .read(testScoresControllerProvider(widget.studentIdOverride).notifier)
                            .loadScores(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.scores.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.grade_outlined,
                              size: 72,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Test Scores Recorded',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAdmin
                                  ? 'Enter test scores individually or use Bulk Batch Entry.'
                                  : 'Your teacher has not uploaded any test scores yet.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            if (isAdmin)
                              Wrap(
                                spacing: 12,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.groups),
                                    label: const Text('Bulk Batch Entry'),
                                    onPressed: _showBulkBatchEntryDialog,
                                  ),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Score'),
                                    onPressed: _showAddSingleScoreDialog,
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
                        // Overall Average Card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: _getScoreColor(overallPct).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _getScoreColor(overallPct), width: 2),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${overallPct.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: _getScoreColor(overallPct),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Average Test Performance',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total ${state.scores.length} test${state.scores.length > 1 ? 's' : ''} recorded',
                                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Filter Chips
                        if (subjects.length > 2) ...[
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: subjects.map((sub) {
                                final isSelected = state.selectedSubject == sub;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(sub),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      ref
                                          .read(testScoresControllerProvider(widget.studentIdOverride).notifier)
                                          .filterSubject(sub);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Test Scores List
                        ...state.scores.map((score) => _buildScoreCard(score, isAdmin)),
                        const SizedBox(height: 80),
                      ],
                    ),
    );
  }

  Widget _buildScoreCard(TestScoreItem score, bool isAdmin) {
    final color = _getScoreColor(score.percentage);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        score.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              score.subjectName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _dateFormat.format(score.testDate),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${score.marks.toStringAsFixed(score.marks.truncateToDouble() == score.marks ? 0 : 1)} / ${score.maxMarks.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color),
                      ),
                      child: Text(
                        '${score.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isAdmin) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    onPressed: () => _showEditScoreDialog(score),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    onPressed: () => _confirmDelete(score),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
