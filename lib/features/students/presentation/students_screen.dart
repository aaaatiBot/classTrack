import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/domain/user_profile.dart';
import '../../../core/utils/error_handler.dart';
import 'students_controller.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  void _showAddStudentSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _AddStudentSheet(),
    );
  }

  void _showEditStudentDialog(BuildContext context, WidgetRef ref, UserProfile student) {
    showDialog(
      context: context,
      builder: (ctx) => _EditStudentDialog(student: student),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsListProvider);
    final batchesAsync = ref.watch(classBatchesProvider);
    final filter = ref.watch(studentsFilterProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or username...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: filter.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => ref
                            .read(studentsFilterProvider.notifier)
                            .setSearchQuery(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
              onChanged: (val) =>
                  ref.read(studentsFilterProvider.notifier).setSearchQuery(val),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Class/Batch Filter Chips
          batchesAsync.when(
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
                    final isSelected = filter.selectedBatch == batch;
                    return FilterChip(
                      selected: isSelected,
                      label: Text(batch),
                      onSelected: (_) {
                        ref
                            .read(studentsFilterProvider.notifier)
                            .setSelectedBatch(batch);
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Students List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(studentsListProvider);
                ref.invalidate(classBatchesProvider);
              },
              child: studentsAsync.when(
                data: (students) {
                  if (students.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  filter.searchQuery.isNotEmpty
                                      ? 'No students match "${filter.searchQuery}"'
                                      : 'No students added yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the "+" button below to add your first student.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                  ),
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
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: student.active
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            foregroundColor: student.active
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            child: Text(
                              student.name.isNotEmpty
                                  ? student.name.substring(0, 1).toUpperCase()
                                  : 'S',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  student.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    decoration: student.active
                                        ? null
                                        : TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              if (!student.active)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Inactive',
                                    style: TextStyle(
                                      color: colorScheme.onErrorContainer,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '@${student.username} • Batch: ${student.classBatch ?? "General"}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded),
                            onSelected: (val) {
                              if (val == 'syllabus') {
                                context.push(
                                  '/admin/students/${student.id}/syllabus?name=${Uri.encodeComponent(student.name)}',
                                );
                              } else if (val == 'results') {
                                context.push(
                                  '/admin/students/${student.id}/results?name=${Uri.encodeComponent(student.name)}',
                                );
                              } else if (val == 'edit') {
                                _showEditStudentDialog(context, ref, student);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'syllabus',
                                child: Row(
                                  children: [
                                    Icon(Icons.auto_stories_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('View Syllabus'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'results',
                                child: Row(
                                  children: [
                                    Icon(Icons.workspace_premium_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('View Results'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit Student'),
                                  ],
                                ),
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
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: colorScheme.error),
                        const SizedBox(height: 12),
                        Text(
                          ErrorHandler.getFriendlyErrorMessage(err),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.error),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () => ref.invalidate(studentsListProvider),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentSheet(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Student'),
      ),
    );
  }
}

class _AddStudentSheet extends ConsumerStatefulWidget {
  const _AddStudentSheet();

  @override
  ConsumerState<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends ConsumerState<_AddStudentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(studentsRepositoryProvider);
      await repo.createStudent(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        classBatch: _classController.text.trim(),
      );

      ref.invalidate(studentsListProvider);
      ref.invalidate(classBatchesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student created successfully!'),
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
                    'Add New Student',
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Full Name *',
                  hintText: 'e.g., Rohit Sharma',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter student name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _classController,
                decoration: const InputDecoration(
                  labelText: 'Class / Batch',
                  hintText: 'e.g., Class 10 - Batch A',
                  prefixIcon: Icon(Icons.class_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username *',
                  hintText: 'e.g., rohit12',
                  prefixIcon: Icon(Icons.person_outline),
                  suffixText: '@classtrack.app',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a username';
                  }
                  if (val.contains('@') || val.contains(' ')) {
                    return 'Username cannot contain spaces or @';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Initial Password *',
                  hintText: 'At least 6 characters',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (val) => val == null || val.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _handleCreate,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Student'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditStudentDialog extends ConsumerStatefulWidget {
  final UserProfile student;

  const _EditStudentDialog({required this.student});

  @override
  ConsumerState<_EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends ConsumerState<_EditStudentDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _classController;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _classController = TextEditingController(text: widget.student.classBatch ?? '');
    _isActive = widget.student.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(studentsRepositoryProvider);
      await repo.updateStudent(
        id: widget.student.id,
        name: _nameController.text.trim(),
        classBatch: _classController.text.trim(),
        active: _isActive,
      );

      ref.invalidate(studentsListProvider);
      ref.invalidate(classBatchesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student details updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text(
          'Are you sure you want to delete ${widget.student.name}? This will remove all their records.',
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

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(studentsRepositoryProvider);
      await repo.deleteStudent(widget.student.id);

      ref.invalidate(studentsListProvider);
      ref.invalidate(classBatchesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student deleted')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getFriendlyErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.student.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _classController,
              decoration: const InputDecoration(labelText: 'Class / Batch'),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Account Active'),
              subtitle: Text(
                _isActive
                    ? 'Student can log in and view dashboard'
                    : 'Account deactivated',
                style: const TextStyle(fontSize: 12),
              ),
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _handleDelete,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
