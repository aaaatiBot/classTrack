import 'package:flutter/material.dart';

class HomeworkScreen extends StatelessWidget {
  final bool isAdmin;
  const HomeworkScreen({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              isAdmin ? 'Manage Daily Homework' : 'Daily Homework',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Will be implemented in Phase 4.'),
          ],
        ),
      ),
    );
  }
}
