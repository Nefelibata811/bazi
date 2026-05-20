import 'package:bazi_app/core/auth_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

void main() {
  group('loginErrorMessage', () {
    test('invalid credentials → 邮箱或密码错误', () {
      expect(
        loginErrorMessage(
          const AuthException('Invalid login credentials'),
        ),
        '邮箱或密码错误',
      );
    });

    test('email not confirmed → 验证提示', () {
      expect(
        loginErrorMessage(
          const AuthException('Email not confirmed'),
        ),
        contains('验证'),
      );
    });

    test('too many requests → 频率限制', () {
      expect(
        loginErrorMessage(
          const AuthException('Too many requests'),
        ),
        contains('稍后再试'),
      );
    });
  });

  group('registerErrorMessage', () {
    test('already registered → 直接登录', () {
      expect(
        registerErrorMessage(
          const AuthException('User already registered'),
        ),
        contains('登录'),
      );
    });
  });

  group('passwordResetErrorMessage', () {
    test('too many requests → 发送过于频繁', () {
      expect(
        passwordResetErrorMessage(
          const AuthException('Too many requests'),
        ),
        contains('频繁'),
      );
    });
  });
}
