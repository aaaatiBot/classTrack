import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  static String friendlyMessage(dynamic error) => getFriendlyErrorMessage(error);

  static String getFriendlyErrorMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred.';

    final message = error.toString().toLowerCase();

    // Project paused or unreachable
    if (message.contains('socketexception') ||
        message.contains('connection refused') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('503') ||
        message.contains('502') ||
        message.contains('bad gateway')) {
      return 'Cannot reach Supabase servers.\n\nFree Supabase projects automatically pause after 7 days of inactivity. If your project is paused, please visit your Supabase Dashboard to unpause it, then try again.';
    }

    // Invalid credentials
    if (error is AuthException) {
      if (message.contains('invalid login credentials') ||
          message.contains('invalid grant')) {
        return 'Incorrect username or password. Please verify and try again.';
      }
      if (message.contains('email not confirmed')) {
        return 'Account email not confirmed. Ensure "Confirm email" is disabled in your Supabase Auth provider settings.';
      }
      return error.message;
    }

    if (error is PostgrestException) {
      if (message.contains('row-level security') ||
          message.contains('permission denied')) {
        return 'Access denied. You do not have permission to view or modify this record.';
      }
      return error.message;
    }

    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }

    return error.toString();
  }
}
