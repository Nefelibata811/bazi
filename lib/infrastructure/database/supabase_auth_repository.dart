import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../domain/entities/user.dart';
import '../../domain/services/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> _loadProfile(String userId) async {
    try {
      return await _client
          .from('profiles')
          .select('nickname, avatar_url, phone')
          .eq('id', userId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<User> _userFromAuthUser(
    dynamic supabaseUser, {
    String? nickname,
    String? avatarUrl,
    String? phone,
  }) async {
    final profile = await _loadProfile(supabaseUser.id);
    return User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      createdAt: DateTime.parse(supabaseUser.createdAt),
      nickname: nickname ?? profile?['nickname'] as String?,
      avatarUrl: avatarUrl ?? profile?['avatar_url'] as String?,
      phone: phone ??
          supabaseUser.phone ??
          profile?['phone'] as String?,
    );
  }

  Future<void> _syncProfilePhone(String userId, String phoneE164) async {
    try {
      await _client.from('profiles').upsert({
        'id': userId,
        'phone': phoneE164,
      });
    } catch (_) {}
  }

  @override
  Future<User?> register({
    required String email,
    required String password,
    String? nickname,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: nickname != null ? {'nickname': nickname} : null,
      );

      final supabaseUser = response.user;
      if (supabaseUser == null) return null;

      if (response.session != null &&
          nickname != null &&
          nickname.isNotEmpty) {
        try {
          await _client.from('profiles').upsert({
            'id': supabaseUser.id,
            'nickname': nickname,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }

      return await _userFromAuthUser(supabaseUser, nickname: nickname);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final supabaseUser = response.user;
      if (supabaseUser == null) return null;

      return await _userFromAuthUser(supabaseUser);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> sendPhoneLoginOtp(String phoneE164) async {
    await _client.auth.signInWithOtp(phone: phoneE164);
  }

  @override
  Future<User?> verifyPhoneLoginOtp({
    required String phoneE164,
    required String otp,
  }) async {
    final response = await _client.auth.verifyOTP(
      phone: phoneE164,
      token: otp.trim(),
      type: OtpType.sms,
    );
    final supabaseUser = response.user;
    if (supabaseUser == null) return null;

    await _syncProfilePhone(supabaseUser.id, phoneE164);
    return await _userFromAuthUser(supabaseUser, phone: phoneE164);
  }

  @override
  Future<void> sendBindPhoneOtp(String phoneE164) async {
    await _client.auth.updateUser(UserAttributes(phone: phoneE164));
  }

  @override
  Future<User?> verifyBindPhoneOtp({
    required String phoneE164,
    required String otp,
  }) async {
    final response = await _client.auth.verifyOTP(
      phone: phoneE164,
      token: otp.trim(),
      type: OtpType.sms,
    );
    final supabaseUser = response.user;
    if (supabaseUser == null) return null;

    await _syncProfilePhone(supabaseUser.id, phoneE164);
    return await _userFromAuthUser(supabaseUser, phone: phoneE164);
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  @override
  Future<User?> currentUser() async {
    final supabaseUser = _client.auth.currentUser;
    if (supabaseUser == null) return null;
    return await _userFromAuthUser(supabaseUser);
  }

  @override
  Future<User?> updateProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
    String? phone,
  }) async {
    try {
      final data = <String, dynamic>{'id': userId};
      if (nickname != null) data['nickname'] = nickname;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      if (phone != null) data['phone'] = phone;

      await _client.from('profiles').upsert(data);

      return currentUser();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> uploadAvatar(
      String userId, Uint8List bytes, String fileName) async {
    try {
      final extension = fileName.split('.').last;
      final objectName = '$userId/avatar.$extension';

      await _client.storage.from('avatars').uploadBinary(
            objectName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return _client.storage.from('avatars').getPublicUrl(objectName);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email, {String? redirectTo}) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  @override
  Future<void> resetPassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
