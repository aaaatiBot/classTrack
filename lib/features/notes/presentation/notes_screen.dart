import 'package:flutter/material.dart';

class NotesScreen extends StatelessWidget {
  final bool isAdmin;
  const NotesScreen({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Notes'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_shared_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              isAdmin ? 'Upload & Manage Notes' : 'Study Notes',
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
