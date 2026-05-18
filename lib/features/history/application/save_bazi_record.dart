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
import 'bazi_records_list_controller.dart';

final baziRecordRepositoryProvider = Provider<SupabaseBaziRecordRepository>((ref) {
  return SupabaseBaziRecordRepository(Supabase.instance.client);
});

const _lastRecordKey = 'last_selected_record';

/// Saves report to Supabase. Returns null if not logged in or save failed.
Future<BaziRecord?> saveBaziReport(
  WidgetRef ref, {
  required BaziReport report,
  required String personName,
}) async {
  final user = ref.read(authControllerProvider).user;
  if (user == null) return null;

  final name = personName.isNotEmpty ? personName : '未命名';
  final requestJson = BaziRecordEncoder.encodeRequest(report, name);
  final reportJson = BaziRecordEncoder.encodeReport(report);

  try {
    final record = await ref.read(baziRecordRepositoryProvider).save(
          userId: user.id,
          personName: name,
          requestJson: requestJson,
          reportJson: reportJson,
        );
    ref.read(baziRecordsListProvider.notifier).upsertRecord(record);
    await persistLastSelectedRecord(record);
    return record;
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
