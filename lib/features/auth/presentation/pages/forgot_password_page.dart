// 文件：forgotpassword页面
//
// 页面：负责 UI 展示与用户操作。
// 路径：`lib/features/auth/presentation/pages/forgot_password_page.dart`。
//
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/app_urls.dart';
import '../../application/auth_controller.dart';
import '../widgets/otp_countdown_controller.dart';

/// 类 `ForgotPasswordPage`：实现 Forgot Password Page 相关逻辑。
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

/// 私有类 `_ForgotPasswordPageState`：Forgot Password Page State。
class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;
  bool _sending = false;
  String? _errorMsg;
  final _cooldown = OtpCountdownController();

  // 初始化：注册首帧回调、预加载列表数据。

  @override
  void initState() {
    super.initState();
    _loadCooldown();
  }

  // 释放监听器与控制器资源。

  @override
  void dispose() {
    _cooldown.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _isCoolingDown => _cooldown.isActive;

  Future<void> _loadCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final deadline = prefs.getInt('pwd_reset_cooldown_until') ?? 0;
    final remaining = deadline - DateTime.now().millisecondsSinceEpoch;
    if (remaining > 0) {
      _startCooldown((remaining / 1000).ceil());
    }
  }

  Future<void> _saveCooldown(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    final deadline = DateTime.now().millisecondsSinceEpoch + seconds * 1000;
    await prefs.setInt('pwd_reset_cooldown_until', deadline);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isCoolingDown) return;

    setState(() {
      _sending = true;
      _errorMsg = null;
    });

    final error = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(_emailController.text);

    if (!mounted) return;

    setState(() => _sending = false);

    if (error != null) {
      setState(() {
        _errorMsg = error;
        _startCooldown(10);
        _saveCooldown(10);
      });
    } else {
      setState(() => _sent = true);
    }
  }

  void _startCooldown(int seconds) {
    _cooldown.start(
      seconds: seconds,
      mounted: () => mounted,
      onTick: (_) => setState(() {}),
      onComplete: () {
        if (mounted) setState(() => _errorMsg = null);
      },
    );
  }

  void _clearCooldown() {
    _cooldown.cancel();
    setState(() => _errorMsg = null);
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('pwd_reset_cooldown_until');
    });
  }

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('忘记密码')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_reset, size: 56,
                      color: AppColors.gold),
                  const SizedBox(height: 20),
                  Text('重置密码', style: textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    '输入注册邮箱，我们将发送重置链接',
                    style: textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  if (_sent) ...[
                    _SuccessCard(
                      email: _emailController.text.trim(),
                      redirectUrl: AppUrls.passwordResetRedirect,
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: '邮箱',
                        hintText: '请输入注册邮箱',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入邮箱';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                            .hasMatch(value.trim())) {
                          return '邮箱格式不正确';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isCoolingDown
                              ? AppColors.gold.withValues(alpha: 0.06)
                              : AppColors.cinnabar.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCoolingDown
                                ? AppColors.gold.withValues(alpha: 0.2)
                                : AppColors.cinnabar.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _isCoolingDown
                                  ? Icons.timer_outlined
                                  : Icons.error_outline,
                              color: _isCoolingDown
                                  ? AppColors.gold
                                  : AppColors.cinnabar,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMsg!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: _isCoolingDown
                                      ? AppColors.ink
                                      : AppColors.cinnabar,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isCoolingDown) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _clearCooldown,
                          child: Text(
                            '已等待足够长时间？点此重置计时器',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.gold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                    if (_errorMsg == null) const SizedBox(height: 0),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: (_sending || _isCoolingDown) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                      ),
                      child: _sending
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      strokeCap: StrokeCap.round),
                                ),
                                SizedBox(width: 10),
                                Text('发送中...'),
                              ],
                            )
                          : _isCoolingDown
                              ? Text('${_cooldown.remaining} 秒后可重试')
                              : const Text('发送重置邮件'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 私有类 `_SuccessCard`：Success Card。
class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    required this.email,
    required this.redirectUrl,
  });

  final String email;
  final String redirectUrl;

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.mark_email_read_outlined,
              color: AppColors.gold, size: 40),
          const SizedBox(height: 12),
          Text('重置密码邮件已发送至', style: textTheme.bodySmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(email, style: textTheme.titleMedium?.copyWith(
              color: AppColors.gold), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text('请检查收件箱（以及垃圾邮件），点击邮件中的链接重置密码',
              style: textTheme.bodySmall, textAlign: TextAlign.center),
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.rice,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('开发提示',
                      style: textTheme.labelSmall?.copyWith(
                          color: AppColors.gold, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    '请在 Supabase → Authentication → Redirect URLs 添加本次跳转地址（含 /** 通配）：',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      height: 1.45,
                      color: AppColors.deepGray,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(redirectUrl,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: AppColors.deepGray,
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('返回登录'),
          ),
        ],
      ),
    );
  }
}
