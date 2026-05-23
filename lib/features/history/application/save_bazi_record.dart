import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/bazi_record.dart';
import '../../../domain/entities/bazi_report.dart';
import '../../../infrastructure/database/supabase_bazi_record_repository.dart';
import '../../auth/application/auth_controller.dart';
import '../infrastructure/bazi_record_encoder.dart';
import '../infrastructure/person_identity.dart';
import 'bazi_records_list_controller.dart';

final baziRecordRepositoryProvider = Provider<SupabaseBaziRecordRepository>((ref) {
  return SupabaseBaziRecordRepository(Supabase.instance.client);
});

const _lastRecordKey = 'last_selected_record';

class SaveBaziOutcome {
  const SaveBaziOutcome({
    required this.record,
    required this.isNew,
  });

  final BaziRecord record;
  final bool isNew;
}

/// 在列表/内存中查找已保存的同一命盘。
BaziRecord? findSavedRecord(
  WidgetRef ref, {
  required BaziReport report,
  required String personName,
}) {
  final key = PersonIdentity.fromSave(
    personName: personName,
    request: report.request,
  ).groupKey;
  for (final r in ref.read(baziRecordsListProvider).records) {
    if (PersonIdentity.fromRecord(r).groupKey == key) {
      return r;
    }
  }
  return null;
}

/// 仅首次保存；同一命主+出生已存在则返回已有记录且不修改云端数据。
Future<SaveBaziOutcome?> saveBaziReport(
  WidgetRef ref, {
  required BaziReport report,
  required String personName,
}) async {
  final user = ref.read(authControllerProvider).user;
  if (user == null) return null;

  final name = PersonIdentity.normalizeName(personName);
  final requestJson = BaziRecordEncoder.encodeRequest(report, name);
  final reportJson = BaziRecordEncoder.encodeReport(report);

  try {
    final repo = ref.read(baziRecordRepositoryProvider);
    final existing = await repo.findByIdentity(
      userId: user.id,
      personName: name,
      requestJson: requestJson,
    );
    if (existing != null) {
      ref.read(baziRecordsListProvider.notifier).upsertRecord(existing);
      await persistLastSelectedRecord(existing);
      return SaveBaziOutcome(record: existing, isNew: false);
    }

    final record = await repo.save(
      userId: user.id,
      personName: name,
      requestJson: requestJson,
      reportJson: reportJson,
    );
    ref.read(baziRecordsListProvider.notifier).upsertRecord(record);
    await persistLastSelectedRecord(record);
    return SaveBaziOutcome(record: record, isNew: true);
  } catch (e, st) {
    debugPrint('saveBaziReport failed: $e\n$st');
    return null;
  }
}

Future<void> persistLastSelectedRecord(BaziRecord record) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastRecordKey,
      jsonEncode({
        'id': record.id,
        'personName': record.personName,
        'requestJson': record.requestJson,
        'reportJson': record.reportJson,
      }),
    );
  } catch (_) {}
}
