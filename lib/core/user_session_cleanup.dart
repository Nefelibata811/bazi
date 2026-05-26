import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app.dart';
import '../features/ai_chat/application/chat_controller.dart';
import '../features/history/application/save_bazi_record.dart';

/// 登出或切换账号时清理 AI 看盘内存状态与本地「上次选盘」标记，避免串号。
Future<void> clearUserScopedSession(Ref ref) async {
  ref.read(chatControllerProvider.notifier).clearSelection();
  ref.read(chatClearSignal.notifier).state++;
  ref.read(mainTabIndexProvider.notifier).state = 0;

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(lastSelectedRecordPrefsKey);
    await prefs.setBool('pending_ai_auto_start', false);
    await prefs.setInt('app_tab_index', 0);
  } catch (_) {}
}
