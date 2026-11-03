import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../results/domain/result_model.dart';
import '../../results/presentation/results_controller.dart';
import '../../syllabus/domain/syllabus_models.dart';
import '../../syllabus/presentation/syllabus_controller.dart';
import '../../test_scores/domain/test_score_model.dart';
import '../../test_scores/presentation/test_scores_controller.dart';
import '../../tests/domain/test_routine_model.dart';
import '../../tests/presentation/tests_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String? studentIdOverride;
  final String? studentName;

  const DashboardScreen({
    super.key,
    this.studentIdOverride,
    this.studentName,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int? _selectedTerm; // null = All, 1 = Term 1, 2 = Term 2, 3 = Term 3
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  String _effectiveStudentId(WidgetRef ref) {
    if (widget.studentIdOverride != null) return widget.studentIdOverride!;
    return ref.watch(authControllerProvider).userProfile?.id ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final studentId = _effectiveStudentId(ref);
    final authProfile = ref.watch(authControllerProvider).userProfile;
    final isReadOnly = widget.studentIdOverride != null;

    if (studentId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Providers
    final syllabusAsync = ref.watch(studentSyllabusProvider(studentId));
    final testsState = ref.watch(testsControllerProvider(studentId));
    final testScoresState = ref.watch(testScoresControllerProvider(studentId));
    final resultsAsync = ref.watch(studentResultsListProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.studentName != null ? '${widget.studentName} - Analytics' : 'My Dashboard',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(studentSyllabusProvider(studentId));
              ref.invalidate(studentResultsListProvider(studentId));
              ref.read(testsControllerProvider(studentId).notifier).loadTests();
              ref.read(testScoresControllerProvider(studentId).notifier).loadScores();
            },
          ),
          if (!isReadOnly)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign Out',
              onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          _buildStudentHeader(authProfile, isReadOnly),
          const SizedBox(height: 16),

          // Next Upcoming Test Card (FR-10.6)
          _buildNextUpcomingTestCard(testsState.tests),
          const SizedBox(height: 16),

          // Syllabus Completion Ring Card with Term Filter (FR-10.1)
          syllabusAsync.when(
            data: (subjects) => _buildSyllabusProgressSection(subjects),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading syllabus: $err'),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Subjects Left to Study (FR-10.2)
          syllabusAsync.when(
            data: (subjects) => _buildSubjectsLeftToStudyCard(subjects),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Class Test Scores & Trend (FR-10.3)
          _buildClassTestScoresSection(testScoresState.scores),
          const SizedBox(height: 16),

          // Term-wise Results & Improvement Indicator (FR-10.4, FR-10.5)
          resultsAsync.when(
            data: (results) => _buildTermWiseResultsSection(results),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 1. Header Card
  // --------------------------------------------------------------------------
  Widget _buildStudentHeader(dynamic authProfile, bool isReadOnly) {
    final theme = Theme.of(context);
    final displayName = widget.studentName ?? authProfile?.name ?? 'Student';
    final batchText = authProfile?.classBatch != null ? 'Batch ${authProfile.classBatch}' : 'ClassTrack';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.school, color: theme.colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isReadOnly ? 'Viewing in Read-Only Mode' : '$batchText • Performance Overview',
                    style: TextStyle(
                      fontSize: 13,
                      color: isReadOnly ? Colors.amber.shade900 : Colors.grey,
                      fontWeight: isReadOnly ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 2. Next Upcoming Test (FR-10.6)
  // --------------------------------------------------------------------------
  Widget _buildNextUpcomingTestCard(List<TestRoutineItem> tests) {
    final upcoming = tests.where((t) => t.isUpcoming).toList()
      ..sort((a, b) => a.testDate.compareTo(b.testDate));

    if (upcoming.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.event_available, color: Colors.green),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No upcoming tests scheduled! Enjoy your study time.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final nextTest = upcoming.first;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(nextTest.testDate.year, nextTest.testDate.month, nextTest.testDate.day);
    final diff = target.difference(today).inDays;

    final badgeText = diff == 0 ? 'Today!' : diff == 1 ? 'Tomorrow' : 'In $diff days';
    final badgeColor = diff <= 1 ? Colors.red : Colors.blue;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.alarm, color: badgeColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Test: ${nextTest.subjectName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateFormat.format(nextTest.testDate),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (nextTest.topics != null && nextTest.topics!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Portion: ${nextTest.topics}',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeColor),
              ),
              child: Text(
                badgeText,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 3. Syllabus Completion Ring with Term Filter (FR-10.1)
  // --------------------------------------------------------------------------
  Widget _buildSyllabusProgressSection(List<Subject> subjects) {
    int totalChapters = 0;
    int completedChapters = 0;

    for (final s in subjects) {
      final chapters = s.chaptersForTerm(_selectedTerm);
      totalChapters += chapters.length;
      completedChapters += chapters.where((c) => c.isComplete).length;
    }

    final double percentage =
        totalChapters > 0 ? (completedChapters / totalChapters) * 100 : 0.0;
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Syllabus Completion',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                // Term Filter Dropdown
                DropdownButton<int?>(
                  value: _selectedTerm,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Terms')),
                    DropdownMenuItem(value: 1, child: Text('1st Term')),
                    DropdownMenuItem(value: 2, child: Text('2nd Term')),
                    DropdownMenuItem(value: 3, child: Text('3rd Term')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedTerm = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (totalChapters == 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No chapters mapped for this term selection.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              Row(
                children: [
                  // Donut Ring Chart via fl_chart
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            startDegreeOffset: -90,
                            sections: [
                              PieChartSectionData(
                                value: completedChapters.toDouble(),
                                color: theme.colorScheme.primary,
                                radius: 14,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: (totalChapters - completedChapters).toDouble(),
                                color: theme.colorScheme.surfaceContainerHighest,
                                radius: 14,
                                showTitle: false,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Text(
                              'Done',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completedChapters of $totalChapters Chapters',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${totalChapters - completedChapters} chapters left to complete',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: totalChapters > 0 ? completedChapters / totalChapters : 0,
                            minHeight: 8,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 4. Subjects Left to Study (FR-10.2)
  // --------------------------------------------------------------------------
  Widget _buildSubjectsLeftToStudyCard(List<Subject> subjects) {
    // Rank subjects by incomplete chapters remaining
    final subjectRanks = subjects.map((sub) {
      final chapters = sub.chaptersForTerm(_selectedTerm);
      final total = chapters.length;
      final completed = chapters.where((c) => c.isComplete).length;
      final remaining = total - completed;
      final pct = total > 0 ? (completed / total) : 0.0;
      return {
        'name': sub.name,
        'total': total,
        'completed': completed,
        'remaining': remaining,
        'pct': pct,
      };
    }).where((item) => (item['total'] as int) > 0).toList();

    subjectRanks.sort((a, b) => (b['remaining'] as int).compareTo(a['remaining'] as int));

    if (subjectRanks.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Subjects Left to Study',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  'Sorted by Remaining',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...subjectRanks.take(4).map((item) {
              final name = item['name'] as String;
              final remaining = item['remaining'] as int;
              final total = item['total'] as int;
              final completed = item['completed'] as int;
              final pct = item['pct'] as double;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          remaining == 0 ? 'All $total done! 🎉' : '$completed/$total done ($remaining left)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: remaining == 0 ? Colors.green : Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          remaining == 0 ? Colors.green : Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 5. Class Test Scores Trend (FR-10.3)
  // --------------------------------------------------------------------------
  Widget _buildClassTestScoresSection(List<TestScoreItem> scores) {
    if (scores.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.query_stats, color: Colors.purple, size: 36),
              SizedBox(height: 8),
              Text(
                'Class Test Trends',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'No class test scores recorded yet.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Chronological order for chart
    final sortedScores = List<TestScoreItem>.from(scores)
      ..sort((a, b) => a.testDate.compareTo(b.testDate));

    final totalMarks = scores.fold(0.0, (sum, s) => sum + s.marks);
    final totalMax = scores.fold(0.0, (sum, s) => sum + s.maxMarks);
    final overallPct = totalMax > 0 ? (totalMarks / totalMax) * 100 : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Class Test Scores Trend',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Avg: ${overallPct.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 25,
                        getTitlesWidget: (val, _) => Text(
                          '${val.toInt()}%',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < sortedScores.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                sortedScores[idx].subjectName.length > 4
                                    ? sortedScores[idx].subjectName.substring(0, 3)
                                    : sortedScores[idx].subjectName,
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: sortedScores
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.percentage))
                          .toList(),
                      isCurved: true,
                      color: Colors.purple,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.purple.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 6. Term-wise Results & Improvement Indicator (FR-10.4, FR-10.5)
  // --------------------------------------------------------------------------
  Widget _buildTermWiseResultsSection(List<ExamResult> results) {
    if (results.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.bar_chart, color: Colors.indigo, size: 36),
              SizedBox(height: 8),
              Text(
                'Term-wise Report Card Results',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Scan your school report cards in the Results tab to view term comparison and improvement analysis.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final sortedResults = List<ExamResult>.from(results)
      ..sort((a, b) {
        final yearCmp = a.year.compareTo(b.year);
        if (yearCmp != 0) return yearCmp;
        return a.term.compareTo(b.term);
      });

    // Calculate improvement vs previous term (FR-10.5)
    double? improvementDiff;
    if (sortedResults.length >= 2) {
      final latest = sortedResults.last.overallPercentage;
      final previous = sortedResults[sortedResults.length - 2].overallPercentage;
      improvementDiff = latest - previous;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Term-wise Performance',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (improvementDiff != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (improvementDiff >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          improvementDiff >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14,
                          color: improvementDiff >= 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${improvementDiff >= 0 ? '+' : ''}${improvementDiff.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: improvementDiff >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 25,
                        getTitlesWidget: (val, _) => Text(
                          '${val.toInt()}%',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < sortedResults.length) {
                            final res = sortedResults[idx];
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                res.examName != null && res.examName!.isNotEmpty
                                    ? res.examName!
                                    : 'T${res.term}',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: sortedResults.asMap().entries.map((e) {
                    final isLatest = e.key == sortedResults.length - 1;
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.overallPercentage,
                          color: isLatest ? Colors.indigo : Colors.indigo.shade200,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
