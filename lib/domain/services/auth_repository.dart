// 文件：认证仓库
//
// 路径：`lib/domain/services/auth_repository.dart`。
//
import 'dart:typed_data';

import '../entities/user.dart';

abstract class AuthRepository {
  Future<User?> register({
    required String email,
    required String password,
    String? nickname,
  });

  Future<User?> login({
    required String email,
    required String password,
  });

  /// Sends SMS OTP for sign-in / sign-up (Supabase phone auth).
  Future<void> sendPhoneLoginOtp(String phoneE164);

  /// Verifies SMS OTP and establishes session.
  Future<User?> verifyPhoneLoginOtp({
    required String phoneE164,
    required String otp,
  });

  /// Sends OTP to bind phone on the current logged-in user.
  Future<void> sendBindPhoneOtp(String phoneE164);

  /// Verifies OTP and links phone to the account.
  Future<User?> verifyBindPhoneOtp({
    required String phoneE164,
    required String otp,
  });

  Future<void> logout();

  /// Local session user without a profiles round-trip (fast startup).
  User? userFromActiveSession();

  Future<User?> currentUser();

  Future<User?> updateProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
    String? phone,
  });

  Future<String?> uploadAvatar(String userId, Uint8List bytes, String fileName);

  Future<void> sendPasswordResetEmail(String email, {String? redirectTo});

  Future<void> resetPassword(String newPassword);
}
