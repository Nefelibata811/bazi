import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../domain/entities/user.dart';
import '../../domain/services/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

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

      final user = User(
        id: supabaseUser.id,
        email: supabaseUser.email ?? email,
        createdAt: DateTime.now(),
        nickname: nickname,
      );

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

      return user;
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

      String? nickname;
      String? avatarUrl;
      try {
        final profile = await _client
            .from('profiles')
            .select('nickname, avatar_url')
            .eq('id', supabaseUser.id)
            .maybeSingle();
        if (profile != null) {
          nickname = profile['nickname'] as String?;
          avatarUrl = profile['avatar_url'] as String?;
        }
      } catch (_) {}

      return User(
        id: supabaseUser.id,
        email: supabaseUser.email ?? email,
        createdAt: DateTime.parse(supabaseUser.createdAt),
        nickname: nickname,
        avatarUrl: avatarUrl,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  @override
  Future<User?> currentUser() async {
    final supabaseUser = _client.auth.currentUser;
    if (supabaseUser == null) return null;

    String? nickname;
    String? avatarUrl;
    try {
      final profile = await _client
          .from('profiles')
          .select('nickname, avatar_url')
          .eq('id', supabaseUser.id)
          .maybeSingle();
      if (profile != null) {
        nickname = profile['nickname'] as String?;
        avatarUrl = profile['avatar_url'] as String?;
      }
    } catch (_) {}

    return User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      createdAt: DateTime.parse(supabaseUser.createdAt),
      nickname: nickname,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<User?> updateProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{'id': userId};
      if (nickname != null) data['nickname'] = nickname;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

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

      await _client.storage.from('avatars').upload(
            objectName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl =
          _client.storage.from('avatars').getPublicUrl(objectName);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<void> resetPassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
