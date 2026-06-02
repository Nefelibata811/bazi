// 文件：合集列表本地缓存
//
// 弱网/冷启动时先展示上次成功的合集列表，避免长时间空白。
//
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/services/bazi_record_repository.dart';

class CollectionsLocalCache {
  static String _key(String userId) => 'collections_cache_$userId';

  static Future<List<CollectionModel>> load(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null) return [];
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = decoded['collections'] as List<dynamic>?;
      if (list == null) return [];
      return list.map(_fromJson).toList();
    } catch (e) {
      debugPrint('合集列表缓存读取失败: $e');
      return [];
    }
  }

  static Future<void> save(String userId, List<CollectionModel> collections) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId),
        jsonEncode({
          'updatedAt': DateTime.now().toIso8601String(),
          'collections': collections.map(_toJson).toList(),
        }),
      );
    } catch (e) {
      debugPrint('合集列表缓存写入失败: $e');
    }
  }

  static Future<void> clear(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId));
    } catch (_) {}
  }

  static Map<String, dynamic> _toJson(CollectionModel c) => {
        'id': c.id,
        'user_id': c.userId,
        'name': c.name,
        'created_at': c.createdAt.toIso8601String(),
      };

  static CollectionModel _fromJson(dynamic e) {
    final row = e as Map<String, dynamic>;
    return CollectionModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
