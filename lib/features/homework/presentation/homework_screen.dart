import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/error_handler.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../students/presentation/students_controller.dart';
import 'homework_controller.dart';

class HomeworkScreen extends ConsumerWidget {
  final bool isAdmin;

  const HomeworkScreen({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final userIsAdmin = isAdmin || authState.isAdmin;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(userIsAdmin ? 'Manage Homework' : 'Daily Homework'),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Today's Homework", icon: Icon(Icons.today_rounded)),
              Tab(text: 'History', icon: Icon(Icons.history_rounded)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Batch filter chip bar
            _buildBatchFilterBar(ref),
            const Expanded(
              child: TabBarView(
                children: [
                  _HomeworkListView(isTodayOnly: true),
                  _HomeworkListView(isTodayOnly: false),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: userIsAdmin
            ? FloatingActionButton.extended(
                onPressed: () => _showAddHomeworkDialog(context, ref),
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Post Homework'),
              )
            : null,
      ),
    );
  }

  Widget _buildBatchFilterBar(WidgetRef ref) {
    final batchesAsync = ref.watch(classBatchesProvider);
    final selectedBatch = ref.watch(homeworkBatchFilterProvider);

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
                  ref.read(homeworkBatchFilterProvider.notifier).state = batch;
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

  void _showAddHomeworkDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final subjectController = TextEditingController();
    final descController = TextEditingController();
    final batchController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Post New Homework'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Assignment Date'),
                    subtitle: Text(DateFormat('EEEE, d MMMM yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject *',
                      hintText: 'e.g., Mathematics',
                      prefixIcon: Icon(Icons.menu_book_rounded),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter subject name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description / Task *',
                      hintText: 'e.g., Solve exercise 4.2 questions 1 to 10',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter homework description'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: batchController,
                    decoration: const InputDecoration(
                      labelText: 'Class / Batch (Optional)',
                      hintText: 'e.g., Class 10 - Batch A',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
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
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final repo = ref.read(homeworkRepositoryProvider);
                await repo.addHomework(
                  date: selectedDate,
                  subjectName: subjectController.text.trim(),
                  description: descController.text.trim(),
                  classBatch: batchController.text.trim(),
                );
                ref.invalidate(todayHomeworkProvider);
                ref.invalidate(allHomeworkProvider);
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeworkListView extends ConsumerWidget {
  final bool isTodayOnly;

  const _HomeworkListView({required this.isTodayOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hwAsync = ref.watch(isTodayOnly ? todayHomeworkProvider : allHomeworkProvider);
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.isAdmin;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(todayHomeworkProvider);
        ref.invalidate(allHomeworkProvider);
      },
      child: hwAsync.when(
        data: (homeworks) {
          if (homeworks.isEmpty) {
            return ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isTodayOnly
                              ? 'No homework assigned for today!'
                              : 'No homework history found.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enjoy your free time or review past study notes.',
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
            itemCount: homeworks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final hw = homeworks[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              hw.subjectName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('d MMM yyyy').format(hw.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        hw.description,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (hw.classBatch != null && hw.classBatch!.isNotEmpty) ...[
                            Icon(Icons.groups_rounded,
                                size: 16, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              hw.classBatch!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                          ] else
                            const Spacer(),
                          if (isAdmin)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.red, size: 20),
                              tooltip: 'Delete',
                              onPressed: () async {
                                final repo = ref.read(homeworkRepositoryProvider);
                                await repo.deleteHomework(hw.id);
                                ref.invalidate(todayHomeworkProvider);
                                ref.invalidate(allHomeworkProvider);
                              },
                            ),
                        ],
                      ),
                    ],
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
    );
  }
}
