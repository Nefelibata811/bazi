// 文件：认证文案
//
// 路径：`lib/core/auth_messages.dart`。
//
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

/// Maps Supabase [AuthException] to user-facing Chinese messages.
String authExceptionMessage(
  Object error, {
  required String fallback,
}) {
  if (error is AuthException && error.message.isNotEmpty) {
    return error.message;
  }
  return fallback;
}

String loginErrorMessage(AuthException e) {
  final msg = e.message.toLowerCase();
  if (msg.contains('invalid login credentials') ||
      msg.contains('invalid credentials')) {
    return '邮箱或密码错误';
  }
  if (msg.contains('email not confirmed')) {
    return '邮箱尚未验证，请先到注册邮箱完成验证';
  }
  if (msg.contains('too many requests')) {
    return '尝试次数过多，请稍后再试';
  }
  if (e.message.isNotEmpty) return e.message;
  return '登录失败，请重试';
}

String registerErrorMessage(AuthException e) {
  final msg = e.message.toLowerCase();
  if (msg.contains('already registered') ||
      msg.contains('user already registered') ||
      msg.contains('already exists')) {
    return '该邮箱已被注册，请直接登录';
  }
  if (msg.contains('password') && msg.contains('weak')) {
    return '密码强度不足，请使用更复杂的密码';
  }
  if (msg.contains('invalid email')) {
    return '邮箱格式不正确';
  }
  if (msg.contains('too many requests')) {
    return '尝试次数过多，请稍后再试';
  }
  if (e.message.isNotEmpty) return e.message;
  return '注册失败，请重试';
}

String passwordResetErrorMessage(AuthException e) {
  final msg = e.message.toLowerCase();
  if (msg.contains('too many requests')) {
    return '发送过于频繁，请稍后再试';
  }
  if (msg.contains('invalid email')) {
    return '邮箱格式不正确';
  }
  if (e.message.isNotEmpty) return e.message;
  return '发送失败，请稍后重试';
}
