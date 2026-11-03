import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/user_profile.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  static const String domain = 'classtrack.app';

  /// Converts a username to the internal Supabase auth email format
  static String formatEmailFromUsername(String username) {
    final cleaned = username.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return '$cleaned@$domain';
  }

  /// Extracts the username from an internal email
  static String extractUsername(String email) {
    if (email.endsWith('@$domain')) {
      return email.substring(0, email.length - ('@$domain').length);
    }
    return email;
  }

  User? get currentAuthUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  /// Signs in using username and password
  Future<UserProfile> signIn({
    required String username,
    required String password,
  }) async {
    final email = formatEmailFromUsername(username);

    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Login failed: user not found.');
    }

    final profile = await fetchProfile(user.id);
    if (!profile.active) {
      await signOut();
      throw const AuthException('This account has been deactivated. Please contact your administrator.');
    }

    await LocalStorageService.saveCachedProfile(profile);
    return profile;
  }

  /// Fetches the profile from the `profiles` table
  Future<UserProfile> fetchProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      throw const AuthException('Profile record not found for this account.');
    }

    return UserProfile.fromMap(response);
  }

  /// Loads current profile: attempts network fetch first, falls back to local cache if offline
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = currentAuthUser;
    if (user == null) {
      return null;
    }

    try {
      final profile = await fetchProfile(user.id);
      await LocalStorageService.saveCachedProfile(profile);
      return profile;
    } catch (_) {
      // Offline fallback: load cached profile
      return await LocalStorageService.getCachedProfile();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Silent error on network failure during sign out
    }
    await LocalStorageService.clearCachedProfile();
  }
}
