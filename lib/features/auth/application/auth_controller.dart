import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../domain/entities/user.dart';
import '../../../domain/services/auth_repository.dart';
import '../../../infrastructure/database/supabase_auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

@immutable
class AuthState {
  const AuthState({
    this.user,
    this.loading = true,
    this.error,
    this.needsEmailConfirmation = false,
    this.isSubmitting = false,
    this.needsPasswordReset = false,
  });

  final User? user;
  final bool loading;
  final String? error;
  final bool needsEmailConfirmation;
  final bool isSubmitting;
  final bool needsPasswordReset;

  bool get isLoggedIn => user != null && !needsEmailConfirmation && !needsPasswordReset;

  String get displayName => user?.nickname ?? user?.email ?? '用户';
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authRepository) : super(const AuthState()) {
    _listenAuthChanges();
    _restoreSession();
  }

  final AuthRepository _authRepository;

  void _listenAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          state = state.copyWith(needsPasswordReset: true, loading: false);
        }
      }
      if (data.event == AuthChangeEvent.signedOut) {
        if (mounted) {
          state = state.copyWith(needsPasswordReset: false, loading: false, clearUser: true);
        }
      }
    });
  }

  Future<void> _restoreSession() async {
    final needsResetFromUrl = _pendingPasswordRecovery;
    _pendingPasswordRecovery = false;

    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser == null) {
      if (mounted) {
        state = state.copyWith(loading: false, needsPasswordReset: needsResetFromUrl);
      }
      return;
    }

    final user = await _authRepository.currentUser();
    if (mounted) {
      final needsReset = needsResetFromUrl || state.needsPasswordReset;
      state = state.copyWith(user: user, loading: false, needsPasswordReset: needsReset);
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AuthState(loading: true);

    try {
      final user = await _authRepository.login(
        email: email.trim(),
        password: password,
      );

      if (user == null) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          state = const AuthState(error: '邮箱或密码错误');
        } else {
          state = const AuthState(error: '登录异常，请重试');
        }
        return false;
      }

      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = const AuthState(error: '网络异常，请检查网络后重试');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? nickname,
  }) async {
    state = const AuthState(loading: true);

    if (email.trim().isEmpty || password.isEmpty) {
      state = const AuthState(error: '邮箱和密码不能为空');
      return false;
    }
    if (password.length < 6) {
      state = const AuthState(error: '密码长度至少 6 位');
      return false;
    }

    try {
      final user = await _authRepository.register(
        email: email.trim(),
        password: password,
        nickname: nickname,
      );

      if (user == null) {
        state = const AuthState(error: '注册失败，该邮箱可能已被注册');
        return false;
      }

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        state = AuthState(
          user: user,
          needsEmailConfirmation: true,
        );
        return false;
      }

      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = const AuthState(error: '网络异常，请检查网络后重试');
      return false;
    }
  }

  Future<bool> updateProfile({
    String? nickname,
    String? avatarUrl,
  }) async {
    final user = state.user;
    if (user == null) return false;

    state = state.copyWith(isSubmitting: true);

    try {
      final updatedUser = await _authRepository.updateProfile(
        userId: user.id,
        nickname: nickname,
        avatarUrl: avatarUrl,
      );

      if (updatedUser == null) {
        state = state.copyWith(error: '更新失败，请重试', isSubmitting: false);
        return false;
      }

      state = state.copyWith(user: updatedUser, isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: '网络异常', isSubmitting: false);
      return false;
    }
  }

  Future<String?> uploadAvatar(Uint8List bytes, String fileName) async {
    final user = state.user;
    if (user == null) return null;

    return _authRepository.uploadAvatar(user.id, bytes, fileName);
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = const AuthState(loading: false);
  }

  void clearError() {
    if (mounted) {
      state = state.copyWith(error: null);
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return '请输入邮箱';
    if (!_isValidEmailFormat(trimmed)) return '邮箱格式不正确';

    try {
      await _authRepository.sendPasswordResetEmail(trimmed);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  bool _isValidEmailFormat(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<bool> resetPassword(String newPassword) async {
    if (newPassword.length < 6) return false;
    state = state.copyWith(isSubmitting: true);
    try {
      await _authRepository.resetPassword(newPassword);
      if (mounted) {
        state = state.copyWith(isSubmitting: false, needsPasswordReset: false);
      }
      return true;
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isSubmitting: false, error: '修改密码失败，请重试');
      }
      return false;
    }
  }
}

extension AuthStateCopy on AuthState {
  AuthState copyWith({
    User? user,
    bool? loading,
    String? error,
    bool? needsEmailConfirmation,
    bool? isSubmitting,
    bool? needsPasswordReset,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      needsEmailConfirmation: needsEmailConfirmation ?? this.needsEmailConfirmation,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      needsPasswordReset: needsPasswordReset ?? this.needsPasswordReset,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

bool _pendingPasswordRecovery = false;

void markPendingPasswordRecovery() {
  _pendingPasswordRecovery = true;
}
