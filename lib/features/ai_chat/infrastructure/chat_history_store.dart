import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/services/chat_repository.dart';

/// Persists AI chat messages per bazi record id.
abstract class ChatHistoryStore {
  Future<List<ChatMessage>> load(String recordId);

  Future<void> save(String recordId, List<ChatMessage> messages);

  Future<void> delete(String recordId);

  /// True when a completed assistant reply exists (not just a pending user turn).
  Future<bool> hasHistory(String recordId);
}

class SharedPreferencesChatHistoryStore implements ChatHistoryStore {
  SharedPreferencesChatHistoryStore({
    Future<SharedPreferences> Function()? getPreferences,
  }) : _getPreferences = getPreferences ?? SharedPreferences.getInstance;

  static const prefix = 'chat_history_';

  final Future<SharedPreferences> Function() _getPreferences;

  @override
  Future<List<ChatMessage>> load(String recordId) async {
    try {
      final prefs = await _getPreferences();
      final raw = prefs.getString('$prefix$recordId');
      if (raw == null) return [];
      return _parseMessages(jsonDecode(raw));
    } catch (e) {
      debugPrint('加载聊天记录失败: $e');
      return [];
    }
  }

  @override
  Future<void> save(String recordId, List<ChatMessage> messages) async {
    if (messages.isEmpty) {
      await delete(recordId);
      return;
    }
    try {
      final prefs = await _getPreferences();
      await prefs.setString(
        '$prefix$recordId',
        jsonEncode({
          'updatedAt': DateTime.now().toIso8601String(),
          'messages': messages.map((m) => m.toJson()).toList(),
        }),
      );
    } catch (e) {
      debugPrint('保存聊天记录失败: $e');
    }
  }

  @override
  Future<void> delete(String recordId) async {
    try {
      final prefs = await _getPreferences();
      await prefs.remove('$prefix$recordId');
    } catch (e) {
      debugPrint('删除聊天记录失败: $e');
    }
  }

  @override
  Future<bool> hasHistory(String recordId) async {
    final messages = await load(recordId);
    return messages.any(
      (m) => m.role == 'assistant' && m.content.trim().isNotEmpty,
    );
  }

  List<ChatMessage> _parseMessages(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (decoded is Map<String, dynamic>) {
      final list = decoded['messages'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

/// Local cache + Supabase cloud sync (logged-in users).
class HybridChatHistoryStore implements ChatHistoryStore {
  HybridChatHistoryStore({
    required ChatHistoryStore local,
    required ChatHistoryStore cloud,
    required bool Function() isLoggedIn,
  })  : _local = local,
        _cloud = cloud,
        _isLoggedIn = isLoggedIn;

  final ChatHistoryStore _local;
  final ChatHistoryStore _cloud;
  final bool Function() _isLoggedIn;

  @override
  Future<void> delete(String recordId) async {
    await _local.delete(recordId);
    if (!_isLoggedIn()) return;
    try {
      await _cloud.delete(recordId);
    } catch (e) {
      debugPrint('云端删除失败（本地已清除）: $e');
    }
  }

  @override
  Future<bool> hasHistory(String recordId) async {
    if (_isLoggedIn()) {
      try {
        if (await _cloud.hasHistory(recordId)) return true;
      } catch (e) {
        debugPrint('云端检查历史失败，回退本地: $e');
      }
    }
    return _local.hasHistory(recordId);
  }

  @override
  Future<List<ChatMessage>> load(String recordId) async {
    if (_isLoggedIn()) {
      try {
        final cloudMessages = await _cloud.load(recordId);
        if (cloudMessages.isNotEmpty) {
          await _local.save(recordId, cloudMessages);
          return cloudMessages;
        }

        final localMessages = await _local.load(recordId);
        if (localMessages.any(
          (m) => m.role == 'assistant' && m.content.trim().isNotEmpty,
        )) {
          await _cloud.save(recordId, localMessages);
        }
        return localMessages;
      } catch (e) {
        debugPrint('云端加载失败，回退本地: $e');
      }
    }
    return _local.load(recordId);
  }

  @override
  Future<void> save(String recordId, List<ChatMessage> messages) async {
    await _local.save(recordId, messages);
    if (!_isLoggedIn()) return;
    try {
      await _cloud.save(recordId, messages);
    } catch (e) {
      debugPrint('云端保存失败（已写入本地缓存）: $e');
    }
  }
}

/// In-memory store for unit tests.
class InMemoryChatHistoryStore implements ChatHistoryStore {
  final _data = <String, List<ChatMessage>>{};

  @override
  Future<void> delete(String recordId) async {
    _data.remove(recordId);
  }

  @override
  Future<bool> hasHistory(String recordId) async {
    final messages = _data[recordId] ?? [];
    return messages.any(
      (m) => m.role == 'assistant' && m.content.trim().isNotEmpty,
    );
  }

  @override
  Future<List<ChatMessage>> load(String recordId) async {
    return List.of(_data[recordId] ?? []);
  }

  @override
  Future<void> save(String recordId, List<ChatMessage> messages) async {
    if (messages.isEmpty) {
      _data.remove(recordId);
    } else {
      _data[recordId] = List.of(messages);
    }
  }
}
