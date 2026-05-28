// 文件：Supabase八字记录仓库
//
// 路径：`lib/infrastructure/database/supabase_bazi_record_repository.dart`。
//
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/bazi_record.dart';
import '../../domain/services/bazi_record_repository.dart';
import '../../features/history/infrastructure/person_identity.dart';

/// 类 `SupabaseBaziRecordRepository`：实现 Supabase Bazi Record Repository 相关逻辑。
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
    final normalizedName = PersonIdentity.normalizeName(personName);
    final birth = PersonIdentity.birthFingerprintFromRequestJson(requestJson);
    final idempotencyKey = _computeIdempotencyKey(
      userId,
      normalizedName,
      requestJson,
    );

    final existing = await _client
        .from('bazi_records')
        .select()
        .eq('user_id', userId)
        .eq('idempotency_key', idempotencyKey)
        .maybeSingle();

    final now = DateTime.now().toIso8601String();

    final keepId = await _resolveKeepRecordId(
      userId: userId,
      normalizedName: normalizedName,
      birth: birth,
      idempotencyRow: existing,
    );

    if (keepId != null) {
      final response = await _client
          .from('bazi_records')
          .select()
          .eq('id', keepId)
          .single();
      return _mapRow(response);
    }

    late final Map<String, dynamic> row;
    try {
      row = await _client.from('bazi_records').insert({
        'user_id': userId,
        'person_name': normalizedName,
        'request_json': requestJson,
        'report_json': reportJson,
        'idempotency_key': idempotencyKey,
        'saved_at': now,
      }).select().single();
    } on PostgrestException catch (e) {
      // 并发保存同一命盘时可能触发幂等唯一约束，回读已有行即可。
      if (e.code == '23505') {
        final existing = await _client
            .from('bazi_records')
            .select()
            .eq('user_id', userId)
            .eq('idempotency_key', idempotencyKey)
            .maybeSingle();
        if (existing != null) {
          return _mapRow(existing);
        }
      }
      rethrow;
    }

    await _deleteDuplicateSiblings(
      userId: userId,
      normalizedName: normalizedName,
      birth: birth,
      keepId: row['id'] as String,
    );
    return _mapRow(row);
  }

  @override
  Future<BaziRecord?> findByIdentity({
    required String userId,
    required String personName,
    required String requestJson,
  }) async {
    final normalizedName = PersonIdentity.normalizeName(personName);
    final birth = PersonIdentity.birthFingerprintFromRequestJson(requestJson);
    final siblings = await _findByIdentity(
      userId: userId,
      normalizedName: normalizedName,
      birth: birth,
    );
    if (siblings.isEmpty) return null;
    siblings.sort((a, b) {
      final at = DateTime.parse(a['saved_at'] as String);
      final bt = DateTime.parse(b['saved_at'] as String);
      return bt.compareTo(at);
    });
    return _mapRow(siblings.first);
  }

  BaziRecord _mapRow(Map<String, dynamic> row) {
    return BaziRecord(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      personName: row['person_name'] as String? ?? '',
      requestJson: row['request_json'] as String? ?? '',
      reportJson: row['report_json'] as String? ?? '',
      savedAt: DateTime.parse(row['saved_at'] as String),
    );
  }

  Future<String?> _resolveKeepRecordId({
    required String userId,
    required String normalizedName,
    required String birth,
    required Map<String, dynamic>? idempotencyRow,
  }) async {
    if (idempotencyRow != null) {
      return idempotencyRow['id'] as String;
    }
    final siblings = await _findByIdentity(
      userId: userId,
      normalizedName: normalizedName,
      birth: birth,
    );
    if (siblings.isEmpty) return null;
    siblings.sort((a, b) {
      final at = DateTime.parse(a['saved_at'] as String);
      final bt = DateTime.parse(b['saved_at'] as String);
      return bt.compareTo(at);
    });
    return siblings.first['id'] as String;
  }

  Future<List<Map<String, dynamic>>> _findByIdentity({
    required String userId,
    required String normalizedName,
    required String birth,
  }) async {
    final rows = await _client
        .from('bazi_records')
        .select('id, person_name, request_json, saved_at')
        .eq('user_id', userId);

    return rows.where((row) {
      final name =
          PersonIdentity.normalizeName(row['person_name'] as String? ?? '');
      if (name != normalizedName) return false;
      final fp = PersonIdentity.birthFingerprintFromRequestJson(
        row['request_json'] as String? ?? '',
      );
      return fp == birth;
    }).toList();
  }

  Future<void> _deleteDuplicateSiblings({
    required String userId,
    required String normalizedName,
    required String birth,
    required String keepId,
  }) async {
    final siblings = await _findByIdentity(
      userId: userId,
      normalizedName: normalizedName,
      birth: birth,
    );
    for (final row in siblings) {
      final id = row['id'] as String;
      if (id != keepId) {
        await delete(id);
      }
    }
  }

  String _computeIdempotencyKey(
    String userId,
    String normalizedName,
    String requestJson,
  ) {
    final birth = PersonIdentity.birthFingerprintFromRequestJson(requestJson);
    final hash = sha256.convert(utf8.encode('$userId|$normalizedName|$birth'));
    return hash.toString();
  }

  @override
  Future<List<BaziRecord>> listByUser(String userId) async {
    final rows = await _client
        .from('bazi_records')
        .select()
        .eq('user_id', userId)
        .order('saved_at', ascending: false);

    return PersonIdentity.dedupeRecords(rows.map(_mapRow).toList());
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

    return rows.map(_mapRow).toList();
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

  @override
  Future<void> deleteByPersonIdentity({
    required String userId,
    required String displayName,
    required String birthFingerprint,
  }) async {
    final rows = await _client
        .from('bazi_records')
        .select('id, person_name, request_json')
        .eq('user_id', userId);

    final targetName = PersonIdentity.normalizeName(displayName);
    final ids = <String>[];
    for (final row in rows) {
      final name =
          PersonIdentity.normalizeName(row['person_name'] as String? ?? '');
      if (name != targetName) continue;
      final birth = PersonIdentity.birthFingerprintFromRequestJson(
        row['request_json'] as String? ?? '',
      );
      if (birth == birthFingerprint) {
        ids.add(row['id'] as String);
      }
    }

    for (final id in ids) {
      await delete(id);
    }
  }
}
