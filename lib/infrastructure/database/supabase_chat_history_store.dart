import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/services/chat_repository.dart';
import '../../features/ai_chat/infrastructure/chat_history_store.dart';

class SupabaseChatHistoryStore implements ChatHistoryStore {
  SupabaseChatHistoryStore(this._client);

  final SupabaseClient _client;

  @override
  Future<void> delete(String recordId) async {
    if (_client.auth.currentUser == null) return;
    try {
      await _client
          .from('bazi_chat_histories')
          .delete()
          .eq('record_id', recordId);
    } catch (e) {
      debugPrint('云端删除聊天记录失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasHistory(String recordId) async {
    final messages = await load(recordId);
    return messages.any(
      (m) => m.role == 'assistant' && m.content.trim().isNotEmpty,
    );
  }

  @override
  Future<List<ChatMessage>> load(String recordId) async {
    if (_client.auth.currentUser == null) return [];
    try {
      final row = await _client
          .from('bazi_chat_histories')
          .select('messages')
          .eq('record_id', recordId)
          .maybeSingle();

      if (row == null) return [];

      final raw = row['messages'];
      if (raw is! List) return [];

      return raw
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('云端加载聊天记录失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> save(String recordId, List<ChatMessage> messages) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (messages.isEmpty) {
      await delete(recordId);
      return;
    }

    try {
      await _client.from('bazi_chat_histories').upsert({
        'record_id': recordId,
        'user_id': userId,
        'messages': messages.map((m) => m.toJson()).toList(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('云端保存聊天记录失败: $e');
      rethrow;
    }
  }
}
