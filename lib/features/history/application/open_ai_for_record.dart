import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app.dart';
import '../../../domain/entities/bazi_record.dart';
import 'bazi_records_list_controller.dart';
import 'save_bazi_record.dart';

/// 用已保存的命盘打开 AI 看盘（不再写入云端）。
Future<void> openAiForRecord(
  BuildContext context,
  WidgetRef ref, {
  required BaziRecord record,
}) async {
  ref.read(baziRecordsListProvider.notifier).upsertRecord(record);
  await persistLastSelectedRecord(record);

  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('app_tab_index', 1);
  await prefs.setBool('pending_ai_auto_start', true);

  ref.read(aiChatRefreshSignal.notifier).state++;

  if (context.mounted) {
    await navigateToHomeTab(context, ref, tabIndex: 1);
  }
}
