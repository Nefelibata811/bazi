import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../core/api_config.dart';
import '../core/app_secrets.dart';
import '../core/debug_log.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/infrastructure/supabase_auth_callback.dart';
import 'app.dart';
import 'theme/app_theme.dart';

/// Supabase 是否已完成初始化（登录页可先展示，后台再连）。
final supabaseReadyProvider = StateProvider<bool>((ref) => false);

final supabaseInitErrorProvider = StateProvider<String?>((ref) => null);

/// 先展示登录/主界面，Supabase 在后台连接，避免首屏白等 6–7 秒。
class BootstrapApp extends ConsumerStatefulWidget {
  const BootstrapApp({super.key});

  @override
  ConsumerState<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends ConsumerState<BootstrapApp> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode && ApiConfig.deepseekApiKey.isEmpty) {
      logDebug(
        'DEEPSEEK_API_KEY is empty. Stop flutter run, then start via '
        'bazi/scripts/run_web.ps1 or VS Code "bazi Web (Chrome)" (not hot reload).',
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initSupabase());
    });
  }

  Future<void> _initSupabase() async {
    try {
      final url = AppSecrets.supabaseUrl;
      if (url.contains('x.supabase.co')) {
        throw StateError(
          '当前为测试用 Supabase 地址，请停止调试后执行 bazi/scripts/run_web.ps1 重新启动',
        );
      }
      final anonKey = AppSecrets.supabaseAnonKey;
      if (anonKey.isEmpty) {
        throw StateError(
          '缺少 SUPABASE_ANON_KEY，请使用 --dart-define=SUPABASE_ANON_KEY=...',
        );
      }
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: FlutterAuthClientOptions(
          authFlowType:
              kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
        ),
      );
      if (kIsWeb) {
        unawaited(SupabaseAuthCallback.handle());
      }
      if (!mounted) return;
      ref.read(supabaseReadyProvider.notifier).state = true;
      ref.read(authControllerProvider.notifier).onSupabaseReady();
    } catch (e, st) {
      logDebug('Supabase init failed: $e\n$st');
      if (mounted) {
        ref.read(supabaseInitErrorProvider.notifier).state = e.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initError = ref.watch(supabaseInitErrorProvider);
    if (initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: _InitErrorPage(message: initError),
      );
    }

    return const BaziApp();
  }
}

class _InitErrorPage extends StatelessWidget {
  const _InitErrorPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '无法连接服务，请检查网络后重启应用。\n\n$message',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
