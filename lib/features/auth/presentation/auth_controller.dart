import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../data/auth_repository.dart';
import '../domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  try {
    return AuthRepository(Supabase.instance.client);
  } catch (_) {
    return null;
  }
});

class AuthState {
  final bool isLoading;
  final UserProfile? userProfile;
  final String? errorMessage;
  final bool isConfigured;

  const AuthState({
    this.isLoading = false,
    this.userProfile,
    this.errorMessage,
    this.isConfigured = true,
  });

  bool get isAuthenticated => userProfile != null;
  bool get isAdmin => userProfile?.isAdmin ?? false;
  bool get isStudent => userProfile?.isStudent ?? false;

  AuthState copyWith({
    bool? isLoading,
    UserProfile? userProfile,
    String? errorMessage,
    bool? isConfigured,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      userProfile: clearUser ? null : (userProfile ?? this.userProfile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthController(this._ref) : super(AuthState(isConfigured: SupabaseConfig.isConfigured)) {
    _init();
  }

  Future<void> _init() async {
    if (!SupabaseConfig.isConfigured) {
      state = state.copyWith(isConfigured: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    final repo = _ref.read(authRepositoryProvider);
    if (repo == null) {
      state = state.copyWith(isLoading: false, isConfigured: false);
      return;
    }

    try {
      final profile = await repo.getCurrentUserProfile();
      state = state.copyWith(
        isLoading: false,
        userProfile: profile,
        isConfigured: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        isConfigured: true,
      );
    }
  }

  Future<void> refreshProfile() async {
    final repo = _ref.read(authRepositoryProvider);
    if (repo == null) return;
    try {
      final profile = await repo.getCurrentUserProfile();
      state = state.copyWith(userProfile: profile);
    } catch (_) {}
  }

  Future<bool> signIn({
    required String username,
    required String password,
  }) async {
    final repo = _ref.read(authRepositoryProvider);
    if (repo == null) {
      state = state.copyWith(
        errorMessage: 'Supabase is not configured yet. Please configure your project URL and Anon Key.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profile = await repo.signIn(
        username: username,
        password: password,
      );
      state = state.copyWith(
        isLoading: false,
        userProfile: profile,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    final repo = _ref.read(authRepositoryProvider);
    if (repo != null) {
      await repo.signOut();
    }
    state = state.copyWith(
      clearUser: true,
      clearError: true,
      isLoading: false,
    );
  }

  void onConfigUpdated() {
    state = state.copyWith(isConfigured: SupabaseConfig.isConfigured);
    _init();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
