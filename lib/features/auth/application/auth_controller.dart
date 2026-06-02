// 文件：认证控制器
//
// 控制器：管理状态并协调数据层。
// 路径：`lib/features/auth/application/auth_controller.dart`。
//
// 认证状态机：登录/注册/登出、Session 恢复、手机绑定（Supabase）。
// Supabase 就绪后由 BootstrapApp 调用 onSupabaseReady。

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../core/app_urls.dart';
import '../../../core/auth_messages.dart';
import '../../../core/phone_utils.dart';
import '../../../core/user_session_cleanup.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/services/auth_repository.dart';
import '../../../app/bootstrap_app.dart';
import '../../../infrastructure/database/inactive_auth_repository.dart';
import '../../../infrastructure/database/supabase_auth_repository.dart';
import '../infrastructure/supabase_auth_callback.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!ref.watch(supabaseReadyProvider) ||
      !Supabase.instance.isInitialized) {
    return const InactiveAuthRepository();
  }
  return SupabaseAuthRepository(Supabase.instance.client);
});

/// Aligns with [AuthState.isLoggedIn]: requires an active session, not just currentUser.
bool isSupabaseSessionActive() {
  return Supabase.instance.client.auth.currentSession != null;
}

@immutable
/// 类 `AuthState`：实现 Auth State 相关逻辑。
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
  factory AuthState.unauthenticated({
    String? error,
    bool isSubmitting = false,
  }) {
    return AuthState(
      error: error,
      loading: false,
      isSubmitting: isSubmitting,
    );
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

/// 类 `AuthController`：实现 Auth Controller 相关逻辑。
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState(loading: false));

  final Ref _ref;

  AuthRepository get _authRepository => _ref.read(authRepositoryProvider);
  Timer? _loadingFailsafe;
  StreamSubscription? _authSubscription;
  bool _supabaseAttached = false;
  String? _sessionUserId;

  Future<void> _onAuthUserChanged(String? newUserId) async {
    final previous = _sessionUserId;
    if (previous != null && previous != newUserId) {
      await clearUserScopedSession(_ref, previousUserId: previous);
    }
    _sessionUserId = newUserId;
  }

  /// Supabase 在后台初始化完成后由 [BootstrapApp] 调用。
  void onSupabaseReady() {
    if (_supabaseAttached) return;
    _supabaseAttached = true;
    _listenAuthChanges();
    unawaited(_restoreSession());
  }

  bool get _supabaseReady => Supabase.instance.isInitialized;

  void _listenAuthChanges() {
    _authSubscription =
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
          await _onAuthUserChanged(user.id);
          if (!mounted) return;
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
          _loadingFailsafe?.cancel();
          await _onAuthUserChanged(null);
          if (!mounted) return;
          state = AuthState.unauthenticated();
        }
      }
    });
  }

  Future<void> _restoreSession() async {
    if (!_supabaseReady) return;

    final needsResetFromCallback = consumePendingPasswordRecovery();

    final sessionUser = _authRepository.userFromActiveSession();
    if (sessionUser == null) {
      _loadingFailsafe?.cancel();
      if (mounted) {
        state = state.copyWith(
          loading: false,
          needsPasswordReset: needsResetFromCallback,
        );
      }
      return;
    }

    if (mounted) {
      state = state.copyWith(loading: true);
    }
    _loadingFailsafe?.cancel();
    _loadingFailsafe = Timer(const Duration(seconds: 3), () {
      if (!mounted || !state.loading) return;
      state = state.copyWith(loading: false);
    });

    final hasSession = Supabase.instance.client.auth.currentSession != null;
    final needsEmailConfirm = !hasSession;

    final needsReset = needsResetFromCallback ||
        state.needsPasswordReset ||
        peekPendingPasswordRecovery();
    if (needsReset) consumePendingPasswordRecovery();

    _loadingFailsafe?.cancel();
    if (mounted) {
      await _onAuthUserChanged(sessionUser.id);
      if (!mounted) return;
      state = state.copyWith(
        user: sessionUser,
        loading: false,
        needsPasswordReset: needsReset,
        needsEmailConfirmation: needsEmailConfirm && !needsReset,
      );
      if (needsReset && kIsWeb) {
        SupabaseAuthCallback.cleanUrlAfterRecoveryHandled();
      }
    }

    unawaited(_enrichProfileFromServer());
  }

  Future<void> _enrichProfileFromServer() async {
    final user = await _authRepository.currentUser();
    if (!mounted || user == null) return;
    if (state.user?.id != user.id) return;
    state = state.copyWith(user: user);
  }

  // 释放监听器与控制器资源。

  @override
  void dispose() {
    _loadingFailsafe?.cancel();
    _authSubscription?.cancel();
    super.dispose();
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

  String _authMessage(Object e, String fallback) =>
      authExceptionMessage(e, fallback: fallback);

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
        state = AuthState.unauthenticated(
          error: '验证码错误或已过期',
          isSubmitting: false,
        );
        return false;
      }
      await _onAuthUserChanged(user.id);
      if (mounted) {
        state = AuthState.authenticated(user);
      }
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(
        error: _authMessage(e, '验证失败，请重试'),
        isSubmitting: false,
      );
      return false;
    } finally {
      if (mounted && state.isSubmitting) {
        state = state.copyWith(isSubmitting: false);
      }
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
    if (!_supabaseReady) {
      state = AuthState.unauthenticated(error: '正在连接服务器，请稍候再试');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final user = await _authRepository.login(
        email: email.trim(),
        password: password,
      );

      if (user == null) {
        state = AuthState.unauthenticated(
          error: '登录失败，请重试',
          isSubmitting: false,
        );
        return false;
      }

      await _onAuthUserChanged(user.id);
      if (mounted) {
        state = AuthState.authenticated(user);
      }
      unawaited(_enrichProfileFromServer());
      return true;
    } on AuthException catch (e) {
      if (mounted) {
        state = AuthState.unauthenticated(
          error: loginErrorMessage(e),
          isSubmitting: false,
        );
      }
      return false;
    } catch (e) {
      debugPrint('login failed: $e');
      if (mounted) {
        state = AuthState.unauthenticated(
          error: '网络异常，请检查网络后重试',
          isSubmitting: false,
        );
      }
      return false;
    } finally {
      if (mounted && state.isSubmitting) {
        state = state.copyWith(isSubmitting: false);
      }
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? nickname,
  }) async {
    if (!_supabaseReady) {
      state = AuthState.unauthenticated(error: '正在连接服务器，请稍候再试');
      return false;
    }

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
        await _onAuthUserChanged(user.id);
        if (mounted) {
          state = AuthState.authenticated(
            user,
            needsEmailConfirmation: true,
          );
        }
        return false;
      }

      await _onAuthUserChanged(user.id);
      if (mounted) {
        state = AuthState.authenticated(user);
      }
      return true;
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(error: registerErrorMessage(e));
      return false;
    } catch (e) {
      debugPrint('register failed: $e');
      state = AuthState.unauthenticated(error: '网络异常，请检查网络后重试');
      return false;
    } finally {
      if (mounted) {
        state = state.copyWith(isSubmitting: false);
      }
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
    _loadingFailsafe?.cancel();
    await _onAuthUserChanged(null);
    state = AuthState.unauthenticated();
    try {
      await _authRepository.logout();
    } catch (e) {
      debugPrint('logout failed: $e');
    }
    if (mounted) {
      state = AuthState.unauthenticated();
    }
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
    } on AuthException catch (e) {
      return passwordResetErrorMessage(e);
    } catch (e) {
      return _authMessage(e, '发送失败，请稍后重试');
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

/// 扩展 `AuthStateCopy`：为类型增加 Auth State Copy 方法。
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
  final controller = AuthController(ref);
  ref.listen<bool>(supabaseReadyProvider, (previous, next) {
    if (next) controller.onSupabaseReady();
  });
  if (ref.read(supabaseReadyProvider) && Supabase.instance.isInitialized) {
    controller.onSupabaseReady();
  }
  return controller;
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
