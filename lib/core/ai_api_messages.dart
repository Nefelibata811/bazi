// 文件：AIAPI文案
//
// 路径：`lib/core/ai_api_messages.dart`。
//
String formatAiApiError(Object error) {
  final raw = error.toString();
  final lower = raw.toLowerCase();

  if (lower.contains('authentication') &&
      (lower.contains('api key') || lower.contains('invalid'))) {
    return 'AI 接口密钥无效或未加载。请在项目根目录的 secrets.local.env 中设置 '
        'DEEPSEEK_API_KEY（在 platform.deepseek.com 申请），'
        '然后用 scripts/run_web.ps1 重新启动（热重载不会更新密钥）。';
  }

  if (raw.contains('未配置 DeepSeek API 密钥')) {
    return raw;
  }

  if (lower.contains('timeout') || raw.contains('超时')) {
    return 'AI 响应超时，请稍后重试。';
  }

  return raw.startsWith('Exception: ')
      ? raw.substring('Exception: '.length)
      : raw;
}

String? missingDeepseekApiKeyMessage(String key) {
  if (key.trim().isNotEmpty) return null;
  return '未配置 DeepSeek API 密钥（当前运行未带入编译参数）。'
      '请完全退出 flutter run，在 bazi 目录执行：'
      ' .\\scripts\\run_web.ps1 ；'
      '或用 VS Code 启动「bazi Web (Chrome)」。'
      '热重载无法加载密钥，必须重新运行。';
}
