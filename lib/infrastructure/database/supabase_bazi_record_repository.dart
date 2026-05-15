import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/bazi_record.dart';
import '../../domain/services/bazi_record_repository.dart';

class SupabaseBaziRecordRepository implements BaziRecordRepository {
  final SupabaseClient _client;

  SupabaseBaziRecordRepository(this._client);

  @override
  Future<BaziRecord> save({
    required String userId,
    required String personName,
    required String requestJson,
    required String reportJson,
  }) async {
    final idempotencyKey = _computeIdempotencyKey(userId, requestJson);

    final existing = await _client
        .from('bazi_records')
        .select('id')
        .eq('user_id', userId)
        .eq('idempotency_key', idempotencyKey)
        .maybeSingle();

    if (existing != null) {
      return BaziRecord(
        id: existing['id'] as String,
        userId: userId,
        personName: personName,
        requestJson: requestJson,
        reportJson: reportJson,
        savedAt: DateTime.now(),
      );
    }

    final now = DateTime.now();
    final response = await _client.from('bazi_records').insert({
      'user_id': userId,
      'person_name': personName,
      'request_json': requestJson,
      'report_json': reportJson,
      'idempotency_key': idempotencyKey,
      'saved_at': now.toIso8601String(),
    }).select().single();

    return BaziRecord(
      id: response['id'] as String,
      userId: userId,
      personName: personName,
      requestJson: requestJson,
      reportJson: reportJson,
      savedAt: now,
    );
  }

  String _computeIdempotencyKey(String userId, String requestJson) {
    final hash = sha256.convert(utf8.encode('$userId|$requestJson'));
    return hash.toString();
  }

  @override
  Future<List<BaziRecord>> listByUser(String userId) async {
    final rows = await _client
        .from('bazi_records')
        .select()
        .eq('user_id', userId)
        .order('saved_at', ascending: false);

    return rows.map((row) => BaziRecord(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      personName: row['person_name'] as String? ?? '',
      requestJson: row['request_json'] as String? ?? '',
      reportJson: row['report_json'] as String? ?? '',
      savedAt: DateTime.parse(row['saved_at'] as String),
    )).toList();
  }

  @override
  Future<List<String>> listPersonNames(String userId) async {
    final rows = await _client
        .from('bazi_records')
        .select('person_name')
        .eq('user_id', userId)
        .order('saved_at', ascending: false);

    final seen = <String>{};
    final names = <String>[];
    for (final row in rows) {
      final name = row['person_name'] as String? ?? '';
      if (seen.add(name)) {
        names.add(name);
      }
    }
    return names;
  }

  @override
  Future<List<BaziRecord>> listByPerson(String userId, String personName) async {
    final rows = await _client
        .from('bazi_records')
        .select()
        .eq('user_id', userId)
        .eq('person_name', personName)
        .order('saved_at', ascending: false);

    return rows.map((row) => BaziRecord(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      personName: row['person_name'] as String? ?? '',
      requestJson: row['request_json'] as String? ?? '',
      reportJson: row['report_json'] as String? ?? '',
      savedAt: DateTime.parse(row['saved_at'] as String),
    )).toList();
  }

  @override
  Future<void> delete(String recordId) async {
    await _client.from('bazi_records').delete().eq('id', recordId);
  }

  @override
  Future<void> deleteByPerson(String userId, String personName) async {
    await _client
        .from('bazi_records')
        .delete()
        .eq('user_id', userId)
        .eq('person_name', personName);
  }
}
