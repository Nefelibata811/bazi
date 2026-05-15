import 'dart:typed_data';

import '../../domain/entities/user.dart';
import '../../domain/services/auth_repository.dart';
import 'database_service.dart';

class SqliteAuthRepository implements AuthRepository {
  User? _currentUser;

  @override
  Future<User?> register({
    required String email,
    required String password,
    String? nickname,
  }) async {
    final db = await DatabaseService.instance;

    final rows = await db.query(
      'local_users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (rows.isNotEmpty) return null;

    final now = DateTime.now().toIso8601String();
    final uid =
        'local_${rows.length + 1}_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('local_users', {
      'id': uid,
      'email': email,
      'nickname': nickname,
      'created_at': now,
    });

    final user = User(
      id: uid,
      email: email,
      createdAt: DateTime.parse(now),
      nickname: nickname,
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final db = await DatabaseService.instance;

    final rows = await db.query(
      'local_users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final user = User(
      id: row['id'] as String,
      email: row['email'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      nickname: row['nickname'] as String?,
    );

    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<User?> currentUser() async {
    return _currentUser;
  }

  @override
  Future<User?> updateProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
  }) async {
    final db = await DatabaseService.instance;
    final data = <String, dynamic>{};
    if (nickname != null) data['nickname'] = nickname;
    if (data.isNotEmpty) {
      await db.update(
        'local_users',
        data,
        where: 'id = ?',
        whereArgs: [userId],
      );
    }
    if (_currentUser != null && _currentUser!.id == userId) {
      _currentUser = _currentUser!.copyWith(
        nickname: nickname ?? _currentUser!.nickname,
        avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
      );
    }
    return _currentUser;
  }

  @override
  Future<String?> uploadAvatar(
      String userId, Uint8List bytes, String fileName) async {
    return null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> resetPassword(String newPassword) async {}
}
