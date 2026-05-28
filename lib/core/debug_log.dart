// 文件：debuglog
//
// 路径：`lib/core/debug_log.dart`。
//
import 'package:flutter/foundation.dart';

void logDebug(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
