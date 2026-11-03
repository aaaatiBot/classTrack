import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import 'auth_controller.dart';

class SupabaseConfigDialog extends ConsumerStatefulWidget {
  const SupabaseConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SupabaseConfigDialog(),
    );
  }

  @override
  ConsumerState<SupabaseConfigDialog> createState() => _SupabaseConfigDialogState();
}

class _SupabaseConfigDialogState extends ConsumerState<SupabaseConfigDialog> {
  late final TextEditingController _urlController;
  late final TextEditingController _keyController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: SupabaseConfig.currentUrl);
    _keyController = TextEditingController(text: SupabaseConfig.currentAnonKey);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final url = _urlController.text.trim();
    final key = _keyController.text.trim();

    if (url.isEmpty || !url.startsWith('https://')) {
      setState(() => _error = 'Please enter a valid Supabase URL starting with https://');
      return;
    }
    if (key.isEmpty) {
      setState(() => _error = 'Please enter your Supabase public anon key.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await SupabaseConfig.saveConfig(url, key);

      // Initialize or reinitialize Supabase client
      try {
        await Supabase.initialize(
          url: url,
          publishableKey: key,
        );
      } catch (_) {
        // If already initialized in this process, ignore
      }

      ref.read(authControllerProvider.notifier).onConfigUpdated();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supabase credentials saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Connection failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cloud_sync_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          const Text('Connect Supabase', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your Supabase Project URL and public anon key from Project Settings > API.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Project URL',
                hintText: 'https://xyzcompany.supabase.co',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Public Anon Key',
                hintText: 'eyJhbGciOi...',
                prefixIcon: Icon(Icons.key),
              ),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (SupabaseConfig.isConfigured)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        FilledButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save & Connect'),
        ),
      ],
    );
  }
}
