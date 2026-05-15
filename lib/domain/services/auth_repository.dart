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

  Future<void> logout();

  Future<User?> currentUser();

  Future<User?> updateProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
  });

  Future<String?> uploadAvatar(String userId, Uint8List bytes, String fileName);

  Future<void> sendPasswordResetEmail(String email);

  Future<void> resetPassword(String newPassword);
}
