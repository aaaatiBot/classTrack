import 'package:flutter/material.dart';
import '../../notes/presentation/notes_screen.dart';
import 'homework_screen.dart';

class HomeworkAndNotesScreen extends StatelessWidget {
  final bool isAdmin;

  const HomeworkAndNotesScreen({super.key, this.isAdmin = true});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: const TabBarView(
          children: [
            HomeworkScreen(isAdmin: true),
            NotesScreen(isAdmin: true),
          ],
        ),
        bottomSheet: Container(
          color: Theme.of(context).colorScheme.surface,
          child: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.assignment_outlined), text: 'Homework'),
              Tab(icon: Icon(Icons.folder_shared_outlined), text: 'Notes'),
            ],
          ),
        ),
      ),
    );
  }
}
