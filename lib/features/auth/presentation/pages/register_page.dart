import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../application/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).user;
      if (user != null && user.email.isNotEmpty && _emailController.text.isEmpty) {
        _emailController.text = user.email;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authControllerProvider.notifier).clearError();

    await ref.read(authControllerProvider.notifier).register(
          email: _emailController.text,
          password: _passwordController.text,
          nickname: _nicknameController.text.trim().isEmpty
              ? null
              : _nicknameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final busy = state.loading || state.isSubmitting;
    final textTheme = Theme.of(context).textTheme;
    final error = state.error;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '创建账号',
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '注册后即可保存您的排盘记录',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.deepGray,
                    ),
                  ),
                  const SizedBox(height: 36),
                  if (!state.needsEmailConfirmation) ...[
                  TextFormField(
                    controller: _nicknameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '昵称（选填）',
                      hintText: '给自己取一个名字',
                    ),
                    enabled: !busy,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '邮箱',
                      hintText: '请输入邮箱',
                    ),
                    enabled: !busy,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入邮箱';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: '密码',
                      hintText: '请设置密码（至少 6 位）',
                    ),
                    enabled: !busy,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      if (value.length < 6) {
                        return '密码长度至少 6 位';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  ],
                  if (state.needsEmailConfirmation) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.mark_email_read_outlined,
                              color: AppColors.gold, size: 36),
                          const SizedBox(height: 10),
                          Text(
                            '注册成功！',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '验证邮件已发送至 ${state.user?.email ?? _emailController.text.trim()}，\n请点击邮件中的链接完成验证后再登录。',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.deepGray,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.cinnabar,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (!state.needsEmailConfirmation) ...[
                    ElevatedButton(
                      onPressed: busy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                      ),
                      child: busy
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('注册中...'),
                              ],
                            )
                          : const Text('注册'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: state.loading
                          ? null
                          : () {
                              Navigator.of(context)
                                  .pushReplacementNamed('/login');
                            },
                      child: Text(
                        '已有账号？去登录',
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).clearError();
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: Text(
                        '已完成验证？去登录',
                        style: textTheme.bodySmall,
                      ),
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
