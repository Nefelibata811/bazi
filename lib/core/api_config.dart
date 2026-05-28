// 文件：APIconfig
//
// 路径：`lib/core/api_config.dart`。
//
// 编译期 API 配置：DeepSeek 等，密钥来自 --dart-define（见 scripts/sync_dart_defines.ps1）。

import 'app_secrets.dart';

/// 类 `ApiConfig`：实现 Api Config 相关逻辑。
class ApiConfig {
  ApiConfig._();

  static String get deepseekApiKey => AppSecrets.deepseekApiKey;
  static String get deepseekBaseUrl => AppSecrets.deepseekBaseUrl;
  static const deepseekModel = 'deepseek-chat';
  static const temperature = 0.7;
  static const maxTokens = 4096;
  static const timeoutSeconds = 60;
}
