import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../core/utils/error_handler.dart';
import '../../students/presentation/students_controller.dart';
import 'attendance_controller.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.isAdmin;
    final currentUserId = authState.userProfile?.id ?? '';

    if (isAdmin) {
      return const _AdminAttendanceView();
    } else {
      return _StudentAttendanceView(studentId: currentUserId);
    }
  }
}

// ==============================================================================
// ADMIN VIEW: DAILY ATTENDANCE REGISTER
// ==============================================================================
class _AdminAttendanceView extends ConsumerStatefulWidget {
  const _AdminAttendanceView();

  @override
  ConsumerState<_AdminAttendanceView> createState() => _AdminAttendanceViewState();
}

class _AdminAttendanceViewState extends ConsumerState<_AdminAttendanceView> {
  final Map<String, String> _localStatusMap = {};
  bool _isSaving = false;
  bool _isInitialized = false;

  Future<void> _selectDate(BuildContext context) async {
    final currentDate = ref.read(selectedAttendanceDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != currentDate) {
      ref.read(selectedAttendanceDateProvider.notifier).state = picked;
      setState(() {
        _isInitialized = false;
        _localStatusMap.clear();
      });
    }
  }

  void _shiftDate(int days) {
    final currentDate = ref.read(selectedAttendanceDateProvider);
    ref.read(selectedAttendanceDateProvider.notifier).state =
        currentDate.add(Duration(days: days));
    setState(() {
      _isInitialized = false;
      _localStatusMap.clear();
    });
  }

  void _markAll(String status, List<dynamic> students) {
    setState(() {
      for (final s in students) {
        _localStatusMap[s.id] = status;
      }
    });
  }

  Future<void> _saveAttendance() async {
    if (_localStatusMap.isEmpty) return;

    setState(() => _isSaving = true);
    final date = ref.read(selectedAttendanceDateProvider);

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      await repo.saveAttendance(
        date: date,
        studentStatusMap: _localStatusMap,
      );

      ref.invalidate(dateAttendanceProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance saved for ${DateFormat('EEE, d MMM yyyy').format(date)}',
            ),
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
    final selectedDate = ref.watch(selectedAttendanceDateProvider);
    final studentsAsync = ref.watch(studentsListProvider);
    final attendanceAsync = ref.watch(dateAttendanceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormatted = DateFormat('EEE, d MMMM yyyy').format(selectedDate);

    // Sync remote attendance data into local state when loaded
    attendanceAsync.whenData((remoteMap) {
      if (!_isInitialized) {
        _localStatusMap.addAll(remoteMap);
        _isInitialized = true;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Register'),
      ),
      body: Column(
        children: [
          // Date Selector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous day',
                  onPressed: () => _shiftDate(-1),
                ),
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          dateFormatted,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next day',
                  onPressed: () => _shiftDate(1),
                ),
              ],
            ),
          ),

          // Students List & Marking
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                final activeStudents = students.where((s) => s.active).toList();

                if (activeStudents.isEmpty) {
                  return Center(
                    child: Text(
                      'No active students found.\nAdd students from the Students tab first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                // Default any unselected student to present if empty
                for (final s in activeStudents) {
                  _localStatusMap.putIfAbsent(s.id, () => 'present');
                }

                int presentCount = _localStatusMap.values
                    .where((v) => v == 'present')
                    .length;
                int absentCount = _localStatusMap.values
                    .where((v) => v == 'absent')
                    .length;

                return Column(
                  children: [
                    // Summary and Quick Actions Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Chip(
                            avatar: const Icon(Icons.check_circle_rounded,
                                color: Colors.green, size: 18),
                            label: Text('Present: $presentCount'),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            avatar: const Icon(Icons.cancel_rounded,
                                color: Colors.red, size: 18),
                            label: Text('Absent: $absentCount'),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.done_all_rounded, size: 18),
                            label: const Text('All Present'),
                            onPressed: () =>
                                _markAll('present', activeStudents),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // List of students with Present / Absent toggles
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: activeStudents.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final student = activeStudents[index];
                          final status =
                              _localStatusMap[student.id] ?? 'present';
                          final isPresent = status == 'present';

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isPresent
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : Colors.red.withValues(alpha: 0.15),
                                    foregroundColor:
                                        isPresent ? Colors.green : Colors.red,
                                    child: Icon(
                                      isPresent
                                          ? Icons.check_rounded
                                          : Icons.close_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          'Batch: ${student.classBatch ?? "General"}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(
                                        value: 'present',
                                        label: Text('P'),
                                      ),
                                      ButtonSegment(
                                        value: 'absent',
                                        label: Text('A'),
                                      ),
                                    ],
                                    selected: {status},
                                    onSelectionChanged: (set) {
                                      setState(() {
                                        _localStatusMap[student.id] = set.first;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(ErrorHandler.getFriendlyErrorMessage(err)),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _saveAttendance,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_isSaving ? 'Saving...' : 'Save Attendance'),
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// STUDENT VIEW: PERSONAL ATTENDANCE CALENDAR & PERCENTAGE
// ==============================================================================
class _StudentAttendanceView extends ConsumerWidget {
  final String studentId;

  const _StudentAttendanceView({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(studentAttendanceSummaryProvider(studentId));
    final recordsAsync = ref.watch(studentAttendanceRecordsProvider(studentId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentAttendanceSummaryProvider(studentId));
          ref.invalidate(studentAttendanceRecordsProvider(studentId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Card with percentage
            summaryAsync.when(
              data: (summary) {
                final pct = summary.percentage;
                final isGood = pct >= 75.0;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: CircularProgressIndicator(
                                    value: summary.totalClasses > 0
                                        ? summary.presentCount /
                                            summary.totalClasses
                                        : 0,
                                    strokeWidth: 7,
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    color: isGood ? Colors.green : Colors.orange,
                                  ),
                                ),
                                Text(
                                  '${pct.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Attendance Rate',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isGood
                                        ? 'Great job! Your attendance is healthy.'
                                        : 'Attendance is below recommended 75%.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetric('Total Classes', '${summary.totalClasses}'),
                            _buildMetric('Attended', '${summary.presentCount}',
                                color: Colors.green),
                            _buildMetric('Missed', '${summary.absentCount}',
                                color: Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            Text(
              'Past Attendance Records',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Past Attendance Records List
            recordsAsync.when(
              data: (records) {
                if (records.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No attendance records recorded yet.',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final isPresent = record.isPresent;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPresent
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.15),
                          foregroundColor:
                              isPresent ? Colors.green : Colors.red,
                          child: Icon(
                            isPresent
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          DateFormat('EEEE, d MMMM yyyy').format(record.date),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPresent
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPresent ? 'Present' : 'Absent',
                            style: TextStyle(
                              color: isPresent ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(ErrorHandler.getFriendlyErrorMessage(err)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
