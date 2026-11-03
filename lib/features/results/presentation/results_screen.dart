import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/error_handler.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/result_model.dart';
import '../utils/report_card_parser.dart';
import 'results_controller.dart';

class ResultsScreen extends ConsumerWidget {
  final String? studentIdOverride;
  final String? studentName;

  const ResultsScreen({
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
    final resultsAsync = ref.watch(studentResultsListProvider(studentId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(studentName != null ? "$studentName's Results" : 'My Results'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(studentResultsListProvider(studentId)),
        child: resultsAsync.when(
          data: (results) {
            if (results.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            size: 64,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No past results saved yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isReadOnly
                                ? 'No report cards recorded for this student.'
                                : 'Scan your report card or enter marks manually below.',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          if (!isReadOnly) ...[
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => _scanReportCard(context, ref, studentId),
                              icon: const Icon(Icons.document_scanner_rounded),
                              label: const Text('Scan Report Card'),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () => _openReviewSheet(
                                context,
                                ref,
                                studentId: studentId,
                                initialEntries: [],
                              ),
                              icon: const Icon(Icons.edit_note_rounded),
                              label: const Text('Enter Manually'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Chart of marks over time (FR-7.5)
                if (results.length > 1) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Percentage Trend',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            child: _buildTrendChart(results, colorScheme),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Results list
                Text(
                  'Saved Exam Results',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),

                ...results.map((result) {
                  final pct = result.overallPercentage;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                        child: Text(
                          'T${result.term}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        result.examName?.isNotEmpty == true
                            ? result.examName!
                            : 'Term ${result.term} Examination',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Year ${result.year} • Overall: ${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isReadOnly
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              onPressed: () async {
                                final repo = ref.read(resultsRepositoryProvider);
                                await repo.deleteResult(result.id);
                                ref.invalidate(studentResultsListProvider(studentId));
                              },
                            ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(3),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(2),
                            },
                            children: [
                              const TableRow(
                                children: [
                                  Text('Subject', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Marks', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('%', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const TableRow(children: [Divider(), Divider(), Divider()]),
                              ...result.entries.map(
                                (e) => TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Text(e.subject),
                                    ),
                                    Text('${e.marks.toStringAsFixed(0)} / ${e.maxMarks.toStringAsFixed(0)}'),
                                    Text('${e.percentage.toStringAsFixed(1)}%'),
                                  ],
                                ),
                              ),
                            ],
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
      floatingActionButton: isReadOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _scanReportCard(context, ref, studentId),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Scan Report Card'),
            ),
    );
  }

  Widget _buildTrendChart(List<ExamResult> results, ColorScheme colorScheme) {
    final spots = <FlSpot>[];
    for (int i = 0; i < results.length; i++) {
      spots.add(FlSpot(i.toDouble(), results[i].overallPercentage));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx >= 0 && idx < results.length) {
                  return Text('T${results[idx].term} ${results[idx].year}',
                      style: const TextStyle(fontSize: 10));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Future<void> _scanReportCard(
    BuildContext context,
    WidgetRef ref,
    String studentId,
  ) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
    );

    if (photo == null || !context.mounted) return;

    // Show on-device OCR progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Scanning report card with on-device OCR...'),
          ],
        ),
      ),
    );

    try {
      final inputImage = InputImage.fromFile(File(photo.path));
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized = await recognizer.processImage(inputImage);
      await recognizer.close();

      final entries = ReportCardParser.parseOcrText(recognized.text);

      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog
        _openReviewSheet(
          context,
          ref,
          studentId: studentId,
          initialEntries: entries,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR failed: $e. You can enter marks manually.'),
            action: SnackBarAction(
              label: 'Manual',
              onPressed: () => _openReviewSheet(
                context,
                ref,
                studentId: studentId,
                initialEntries: [],
              ),
            ),
          ),
        );
      }
    }
  }

  void _openReviewSheet(
    BuildContext context,
    WidgetRef ref, {
    required String studentId,
    required List<ResultEntry> initialEntries,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EditResultSheet(
        studentId: studentId,
        initialEntries: initialEntries,
      ),
    );
  }
}

class _EditResultSheet extends ConsumerStatefulWidget {
  final String studentId;
  final List<ResultEntry> initialEntries;

  const _EditResultSheet({
    required this.studentId,
    required this.initialEntries,
  });

  @override
  ConsumerState<_EditResultSheet> createState() => _EditResultSheetState();
}

class _EditResultSheetState extends ConsumerState<_EditResultSheet> {
  int _selectedTerm = 1;
  int _selectedYear = DateTime.now().year;
  final _examNameController = TextEditingController(text: 'Term Examination');
  late List<ResultEntry> _entries;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _entries = List.from(widget.initialEntries);
    if (_entries.isEmpty) {
      _entries.add(ResultEntry(subject: 'Mathematics', marks: 80, maxMarks: 100));
    }
  }

  @override
  void dispose() {
    _examNameController.dispose();
    super.dispose();
  }

  void _addEntry() {
    setState(() {
      _entries.add(ResultEntry(subject: '', marks: 0, maxMarks: 100));
    });
  }

  Future<void> _handleSave() async {
    final validEntries = _entries
        .where((e) => e.subject.trim().isNotEmpty)
        .toList();

    if (validEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one subject with marks.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(resultsRepositoryProvider);
      final newResult = ExamResult(
        id: '',
        studentId: widget.studentId,
        term: _selectedTerm,
        year: _selectedYear,
        examName: _examNameController.text.trim(),
        entries: validEntries,
        createdAt: DateTime.now(),
      );

      await repo.saveResult(newResult);
      ref.invalidate(studentResultsListProvider(widget.studentId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report card marks saved to your account!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Review Exam Results',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Term Picker (1st, 2nd, 3rd)
            const Text('Academic Term', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1st Term')),
                ButtonSegment(value: 2, label: Text('2nd Term')),
                ButtonSegment(value: 3, label: Text('3rd Term')),
              ],
              selected: {_selectedTerm},
              onSelectionChanged: (set) => setState(() => _selectedTerm = set.first),
            ),
            const SizedBox(height: 12),

            // Year & Exam Name
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: [
                      for (int y = DateTime.now().year; y >= DateTime.now().year - 5; y--)
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedYear = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _examNameController,
                    decoration: const InputDecoration(labelText: 'Exam Title'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subjects & Marks Rows
            const Text('Subject Marks', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            ..._entries.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        initialValue: item.subject,
                        decoration: const InputDecoration(
                          hintText: 'Subject',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) => item.subject = val,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: item.marks > 0 ? item.marks.toStringAsFixed(0) : '',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Marks',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) => item.marks = double.tryParse(val) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('/', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: item.maxMarks.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Max',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) => item.maxMarks = double.tryParse(val) ?? 100,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                      onPressed: () => setState(() => _entries.removeAt(idx)),
                    ),
                  ],
                ),
              );
            }),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addEntry,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Subject Row'),
              ),
            ),
            const SizedBox(height: 16),

            FilledButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Results'),
            ),
          ],
        ),
      ),
    );
  }
}
