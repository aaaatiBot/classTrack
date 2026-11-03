import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../students/presentation/students_controller.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).userProfile;
    final theme = Theme.of(context);
    final studentsAsync = ref.watch(studentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(studentsListProvider),
          ),
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
          // Admin Profile Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.name ?? 'Administrator',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${profile?.username ?? 'admin'} • Teacher & Admin',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Overview Stats Grid
          Text(
            'Quick Operations',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildNavCard(
                context,
                title: 'Students',
                subtitle: 'Manage & Register',
                icon: Icons.people_alt_rounded,
                color: Colors.blue,
                onTap: () => context.go('/admin/students'),
              ),
              _buildNavCard(
                context,
                title: 'Attendance',
                subtitle: 'Daily Register',
                icon: Icons.fact_check_rounded,
                color: Colors.green,
                onTap: () => context.go('/admin/attendance'),
              ),
              _buildNavCard(
                context,
                title: 'Homework & Notes',
                subtitle: 'Upload Materials',
                icon: Icons.assignment_rounded,
                color: Colors.orange,
                onTap: () => context.go('/admin/homework-notes'),
              ),
              _buildNavCard(
                context,
                title: 'Test Scores',
                subtitle: 'Bulk & Single Entry',
                icon: Icons.grade_rounded,
                color: Colors.purple,
                onTap: () => context.go('/admin/test-scores'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Student Roster & Deep Links
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Student Roster',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/admin/students'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          studentsAsync.when(
            data: (students) {
              if (students.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.person_add, size: 40, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text('No students registered yet.'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => context.go('/admin/students'),
                            child: const Text('Add First Student'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: students.take(6).map((student) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(student.name.isNotEmpty ? student.name[0].toUpperCase() : '?'),
                      ),
                      title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Batch: ${student.classBatch ?? 'General'} • @${student.username}'),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (val) {
                          final encName = Uri.encodeComponent(student.name);
                          if (val == 'dashboard') {
                            context.push('/admin/students/${student.id}/dashboard?name=$encName');
                          } else if (val == 'syllabus') {
                            context.push('/admin/students/${student.id}/syllabus?name=$encName');
                          } else if (val == 'results') {
                            context.push('/admin/students/${student.id}/results?name=$encName');
                          } else if (val == 'tests') {
                            context.push('/admin/students/${student.id}/tests?name=$encName');
                          } else if (val == 'scores') {
                            context.push('/admin/students/${student.id}/scores?name=$encName');
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'dashboard',
                            child: Row(
                              children: [
                                Icon(Icons.dashboard_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('View Dashboard'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'syllabus',
                            child: Row(
                              children: [
                                Icon(Icons.book_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('View Syllabus'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'results',
                            child: Row(
                              children: [
                                Icon(Icons.assessment_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('View Results'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'tests',
                            child: Row(
                              children: [
                                Icon(Icons.alarm, size: 18),
                                SizedBox(width: 8),
                                Text('View Routine'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'scores',
                            child: Row(
                              children: [
                                Icon(Icons.grade_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('View Test Scores'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        final encName = Uri.encodeComponent(student.name);
                        context.push('/admin/students/${student.id}/dashboard?name=$encName');
                      },
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(child: Text('Error loading roster: $err')),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
