import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../core/app_urls.dart';
import '../../../core/phone_utils.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/services/auth_repository.dart';
import '../../../infrastructure/database/supabase_auth_repository.dart';
import '../infrastructure/supabase_auth_callback.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

/// Aligns with [AuthState.isLoggedIn]: requires an active session, not just currentUser.
bool isSupabaseSessionActive() {
  return Supabase.instance.client.auth.currentSession != null;
}

@immutable
class AuthState {
  const AuthState({
    this.user,
    this.loading = false,
    this.error,
    this.needsEmailConfirmation = false,
    this.isSubmitting = false,
    this.needsPasswordReset = false,
  });

  /// 已登录（非启动恢复中的 loading 状态）
  factory AuthState.authenticated(User user, {bool needsEmailConfirmation = false}) {
    return AuthState(
      user: user,
      loading: false,
      needsEmailConfirmation: needsEmailConfirmation,
    );
  }

  /// 未登录并带错误提示
  factory AuthState.unauthenticated({String? error}) {
    return AuthState(error: error, loading: false);
  }

  final User? user;
  final bool loading;
  final String? error;
  final bool needsEmailConfirmation;
  final bool isSubmitting;
  final bool needsPasswordReset;

  bool get isLoggedIn => user != null && !needsEmailConfirmation && !needsPasswordReset;

  String get displayName {
    final u = user;
    if (u == null) return '用户';
    if (u.nickname != null && u.nickname!.isNotEmpty) return u.nickname!;
    if (u.email.isNotEmpty) return u.email;
    if (u.phone != null && u.phone!.isNotEmpty) {
      return PhoneUtils.mask(u.phone);
    }
    return '用户';
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authRepository) : super(const AuthState(loading: true)) {
    _listenAuthChanges();
    _restoreSession();
  }

  final AuthRepository _authRepository;

  void _listenAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        markPendingPasswordRecovery();
        final user = await _authRepository.currentUser();
        if (mounted) {
          state = state.copyWith(
            user: user,
            needsPasswordReset: true,
            loading: false,
          );
        }
      }
      if (data.event == AuthChangeEvent.signedIn) {
        final user = await _authRepository.currentUser();
        if (mounted && user != null && !state.needsPasswordReset) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            state = AuthState.authenticated(user);
          } else {
            state = AuthState.authenticated(
              user,
              needsEmailConfirmation: true,
            );
          }
        }
      }
      if (data.event == AuthChangeEvent.signedOut) {
        if (mounted) {
          state = state.copyWith(
            needsPasswordReset: false,
            loading: false,
            clearUser: true,
          );
        }
      }
    });
  }

  Future<void> _restoreSession() async {
    if (kIsWeb) {
      await SupabaseAuthCallback.handle();
    }

    final needsResetFromCallback = consumePendingPasswordRecovery();

    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser == null) {
      if (mounted) {
        state = state.copyWith(
          loading: false,
          needsPasswordReset: needsResetFromCallback,
        );
      }
      return;
    }

    final user = await _authRepository.currentUser();
    if (mounted) {
      final needsReset = needsResetFromCallback ||
          state.needsPasswordReset ||
          peekPendingPasswordRecovery();
      if (needsReset) consumePendingPasswordRecovery();
      state = state.copyWith(
        user: user,
        loading: false,
        needsPasswordReset: needsReset,
      );
      if (needsReset && kIsWeb) {
        SupabaseAuthCallback.cleanUrlAfterRecoveryHandled();
      }
    }
  }

  /// Called when recovery is detected after the first frame (e.g. late auth event).
  void enterPasswordRecoveryMode() {
    if (!mounted) return;
    state = state.copyWith(
      needsPasswordReset: true,
      loading: false,
    );
  }

  String? _phoneError(String input) {
    if (PhoneUtils.toE164(input) == null) {
      return '请输入有效的中国大陆手机号';
    }
    return null;
  }

  String _authMessage(Object e, String fallback) {
    if (e is AuthException && e.message.isNotEmpty) return e.message;
    return fallback;
  }

  Future<String?> sendPhoneLoginOtp(String phoneInput) async {
    final err = _phoneError(phoneInput);
    if (err != null) return err;

    try {
      await _authRepository.sendPhoneLoginOtp(PhoneUtils.toE164(phoneInput)!);
      return null;
    } catch (e) {
      return _authMessage(e, '验证码发送失败，请稍后重试');
    }
  }

  Future<bool> verifyPhoneLogin(String phoneInput, String otp) async {
    final e164 = PhoneUtils.toE164(phoneInput);
    if (e164 == null) {
      state = AuthState.unauthenticated(error: '手机号格式不正确');
      return false;
    }
    final code = otp.trim();
    if (code.length < 4) {
      state = AuthState.unauthenticated(error: '请输入短信验证码');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final user = await _authRepository.verifyPhoneLoginOtp(
        phoneE164: e164,
        otp: code,
      );
      if (user == null) {
        state = AuthState.unauthenticated(error: '验证码错误或已过期');
        return false;
      }
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(error: _authMessage(e, '验证失败，请重试'));
      return false;
    }
  }

  Future<String?> sendBindPhoneOtp(String phoneInput) async {
    if (state.user == null) return '请先登录';
    final err = _phoneError(phoneInput);
    if (err != null) return err;

    try {
      await _authRepository.sendBindPhoneOtp(PhoneUtils.toE164(phoneInput)!);
      return null;
    } catch (e) {
      return _authMessage(e, '验证码发送失败，请稍后重试');
    }
  }

  Future<bool> verifyBindPhone(String phoneInput, String otp) async {
    final e164 = PhoneUtils.toE164(phoneInput);
    if (e164 == null) {
      state = state.copyWith(error: '手机号格式不正确');
      return false;
    }
    final code = otp.trim();
    if (code.length < 4) {
      state = state.copyWith(error: '请输入短信验证码');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final user = await _authRepository.verifyBindPhoneOtp(
        phoneE164: e164,
        otp: code,
      );
      if (user == null) {
        state = state.copyWith(
          error: '验证码错误或已过期',
          isSubmitting: false,
        );
        return false;
      }
      state = state.copyWith(user: user, isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: _authMessage(e, '绑定失败，请重试'),
        isSubmitting: false,
      );
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final user = await _authRepository.login(
        email: email.trim(),
        password: password,
      );

      if (user == null) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          state = AuthState.unauthenticated(error: '邮箱或密码错误');
        } else {
          state = AuthState.unauthenticated(error: '登录异常，请重试');
        }
        return false;
      }

      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(error: '网络异常，请检查网络后重试');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? nickname,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    if (email.trim().isEmpty || password.isEmpty) {
      state = AuthState.unauthenticated(error: '邮箱和密码不能为空');
      return false;
    }
    if (password.length < 6) {
      state = AuthState.unauthenticated(error: '密码长度至少 6 位');
      return false;
    }

    try {
      final user = await _authRepository.register(
        email: email.trim(),
        password: password,
        nickname: nickname,
      );

      if (user == null) {
        state = AuthState.unauthenticated(error: '注册失败，该邮箱可能已被注册');
        return false;
      }

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        state = AuthState.authenticated(
          user,
          needsEmailConfirmation: true,
        );
        return false;
      }

      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(error: '网络异常，请检查网络后重试');
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
    state = const AuthState();
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
      await _authRepository.sendPasswordResetEmail(
        trimmed,
        redirectTo: AppUrls.passwordResetRedirect,
      );
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
      if (kIsWeb) {
        SupabaseAuthCallback.clearRecoveryArtifacts();
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

bool peekPendingPasswordRecovery() => _pendingPasswordRecovery;

bool consumePendingPasswordRecovery() {
  final value = _pendingPasswordRecovery;
  _pendingPasswordRecovery = false;
  return value;
}
