import 'dart:typed_data';

import '../../domain/entities/user.dart';
import '../../domain/services/auth_repository.dart';

/// Placeholder until [Supabase.initialize] completes; avoids touching the client early.
class InactiveAuthRepository implements AuthRepository {
  const InactiveAuthRepository();

  @override
  User? userFromActiveSession() => null;

  @override
  Future<User?> login({
    required String email,
    required String password,
  }) async =>
      null;

  @override
  Future<User?> register({
    required String email,
    required String password,
    String? nickname,
  }) async =>
      null;

  @override
  Future<void> sendPhoneLoginOtp(String phoneE164) async {}

  @override
  Future<User?> verifyPhoneLoginOtp({
    required String phoneE164,
    required String otp,
  }) async =>
      null;

  @override
  Future<void> sendBindPhoneOtp(String phoneE164) async {}

  @override
  Future<User?> verifyBindPhoneOtp({
    required String phoneE164,
    required String otp,
  }) async =>
      null;

  @override
  Future<void> logout() async {}

  @override
  Future<User?> currentUser() async => null;

  @override
  Future<User?> updateProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
    String? phone,
  }) async =>
      null;

  @override
  Future<String?> uploadAvatar(
    String userId,
    Uint8List bytes,
    String fileName,
  ) async =>
      null;

  @override
  Future<void> sendPasswordResetEmail(String email, {String? redirectTo}) async {}

  @override
  Future<void> resetPassword(String newPassword) async {}
}
