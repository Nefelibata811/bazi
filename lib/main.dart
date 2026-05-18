import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'app/app.dart';
import 'features/auth/infrastructure/supabase_auth_callback.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://iczcdybxotqzwatyvqdm.supabase.co',
    anonKey: 'sb_publishable_C1tZZqL3i-HYl3D-a8-6uA_DyzgVgV6',
    authOptions: FlutterAuthClientOptions(
      // Web 密码重置邮件需 implicit：PKCE 的 code_verifier 在申请邮件的浏览器里，
      // 从邮箱新标签打开链接时无法换票，会误进登录页。
      authFlowType:
          kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
    ),
  );

  if (kIsWeb) {
    await SupabaseAuthCallback.handle();
  }

  runApp(const BaziApp());
}
