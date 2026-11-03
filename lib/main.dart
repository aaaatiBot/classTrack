import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved Supabase credentials from local storage / environment
  await SupabaseConfig.loadConfig();

  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.currentUrl,
        publishableKey: SupabaseConfig.currentAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: ClassTrackApp(),
    ),
  );
}

class ClassTrackApp extends ConsumerWidget {
  const ClassTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ClassTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
