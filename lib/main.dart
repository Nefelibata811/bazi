// 应用入口：初始化 Flutter、全局错误捕获，挂载 Riverpod 与 BootstrapApp。
// 业务界面与路由见 app/bootstrap_app.dart → app/app.dart。
// 项目结构说明见 docs/PROJECT_STRUCTURE.md。

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap_app.dart';
import 'core/debug_log.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logDebug('FlutterError: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logDebug('Uncaught: $error\n$stack');
    return true;
  };

  runApp(const ProviderScope(child: BootstrapApp()));
}
