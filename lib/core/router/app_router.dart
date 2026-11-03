import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/attendance/presentation/attendance_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/admin_home_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/homework/presentation/homework_and_notes_screen.dart';
import '../../features/homework/presentation/homework_screen.dart';
import '../../features/notes/presentation/notes_screen.dart';
import '../../features/results/presentation/results_screen.dart';
import '../../features/shell/admin_shell.dart';
import '../../features/shell/student_shell.dart';
import '../../features/students/presentation/students_screen.dart';
import '../../features/syllabus/presentation/syllabus_screen.dart';
import '../../features/test_scores/presentation/test_scores_screen.dart';
import '../../features/tests/presentation/tests_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState>(ref.watch(authControllerProvider));
  ref.listen<AuthState>(authControllerProvider, (_, next) {
    authNotifier.value = next;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = authNotifier.value;
      final isLoggingIn = state.uri.path == '/login';

      if (authState.isLoading) {
        return null;
      }

      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      final profile = authState.userProfile!;
      final isAdmin = profile.isAdmin;

      // If user is already on a matching panel, allow it
      if (isAdmin && state.uri.path.startsWith('/admin')) {
        return null;
      }
      if (!isAdmin && state.uri.path.startsWith('/student')) {
        return null;
      }

      // Route based on role
      return isAdmin ? '/admin/home' : '/student/dashboard';
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ------------------------------------------------------------------------
      // ADMIN SHELL ROUTES
      // ------------------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Admin Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/home',
                builder: (context, state) => const AdminHomeScreen(),
              ),
            ],
          ),
          // Branch 1: Students
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/students',
                builder: (context, state) => const StudentsScreen(),
              ),
            ],
          ),
          // Branch 2: Attendance
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/attendance',
                builder: (context, state) => const AttendanceScreen(),
              ),
            ],
          ),
          // Branch 3: Homework & Notes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/homework-notes',
                builder: (context, state) => const HomeworkAndNotesScreen(isAdmin: true),
              ),
            ],
          ),
          // Branch 4: Test Scores
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/test-scores',
                builder: (context, state) => const TestScoresScreen(),
              ),
            ],
          ),
        ],
      ),

      // ------------------------------------------------------------------------
      // STUDENT SHELL ROUTES
      // ------------------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StudentShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Syllabus
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/syllabus',
                builder: (context, state) => const SyllabusScreen(),
              ),
            ],
          ),
          // Branch 2: Homework
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/homework',
                builder: (context, state) => const HomeworkScreen(isAdmin: false),
              ),
            ],
          ),
          // Branch 3: Results
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/results',
                builder: (context, state) => const ResultsScreen(),
              ),
            ],
          ),
          // Branch 4: Tests
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/tests',
                builder: (context, state) => const TestsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Student More Routes (Attendance & Notes)
      GoRoute(
        path: '/student/attendance',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/student/notes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotesScreen(isAdmin: false),
      ),

      // Admin view of a student's syllabus (read-only)
      GoRoute(
        path: '/admin/students/:id/syllabus',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final studentId = state.pathParameters['id']!;
          final studentName = state.uri.queryParameters['name'];
          return SyllabusScreen(
            studentIdOverride: studentId,
            studentName: studentName,
          );
        },
      ),

      // Admin view of a student's past results (read-only)
      GoRoute(
        path: '/admin/students/:id/results',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final studentId = state.pathParameters['id']!;
          final studentName = state.uri.queryParameters['name'];
          return ResultsScreen(
            studentIdOverride: studentId,
            studentName: studentName,
          );
        },
      ),
    ],
  );
});
