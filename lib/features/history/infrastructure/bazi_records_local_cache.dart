import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/bazi_record.dart';

/// Persists the user's bazi record list for instant offline / weak-network load.
class BaziRecordsLocalCache {
  static String _key(String userId) => 'bazi_records_cache_$userId';

  static Future<List<BaziRecord>> load(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null) return [];
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = decoded['records'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .map((e) => BaziRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('命盘列表缓存读取失败: $e');
      return [];
    }
  }

  static Future<void> save(String userId, List<BaziRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId),
        jsonEncode({
          'updatedAt': DateTime.now().toIso8601String(),
          'records': records.map((r) => r.toJson()).toList(),
        }),
      );
    } catch (e) {
      debugPrint('命盘列表缓存写入失败: $e');
    }
  }

  static Future<void> clear(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId));
    } catch (_) {}
  }
}
