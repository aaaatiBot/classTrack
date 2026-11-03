import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const StudentShell({
    super.key,
    required this.navigationShell,
  });

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.fact_check_outlined),
                  ),
                  title: const Text('My Attendance Calendar'),
                  subtitle: const Text('View your monthly attendance record'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/student/attendance');
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.folder_shared_outlined),
                  ),
                  title: const Text('Class Notes & Materials'),
                  subtitle: const Text('Download teacher uploaded notes & PDFs'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/student/notes');
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex > 4 ? 0 : navigationShell.currentIndex,
        onDestinationSelected: (index) {
          if (index == 5) {
            _showMoreMenu(context);
          } else {
            _onDestinationSelected(index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Syllabus',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Homework',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium_rounded),
            label: 'Results',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Tests',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
