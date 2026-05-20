/// User-facing messages for DeepSeek / AI chat API errors.
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
  return '未配置 DeepSeek API 密钥。请复制 secrets.example.env 为 secrets.local.env，'
      '填写 DEEPSEEK_API_KEY 后执行 scripts/run_web.ps1 启动。';
}
