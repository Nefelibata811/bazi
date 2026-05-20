import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../app/theme/app_colors.dart';
import '../../application/auth_controller.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool get _hasRecoverySession =>
      Supabase.instance.client.auth.currentSession != null;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(_newPasswordController.text);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('密码已重置，请重新登录'),
            ],
          ),
          backgroundColor: AppColors.gold,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('重置密码'),
        automaticallyImplyLeading: false,
      ),
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
                  Text('设置新密码', style: textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    _hasRecoverySession
                        ? '请输入您的新密码'
                        : '链接已失效或未正确打开，请重新申请重置邮件',
                    style: textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '新密码',
                      hintText: '请输入新密码',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    enabled: !state.isSubmitting,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入新密码';
                      }
                      if (value.length < 6) {
                        return '密码长度至少 6 位';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: '确认密码',
                      hintText: '请再次输入新密码',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    enabled: !state.isSubmitting,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请确认新密码';
                      }
                      if (value != _newPasswordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.cinnabar,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (!_hasRecoverySession) ...[
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/login'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                      ),
                      child: const Text('返回登录'),
                    ),
                  ] else
                  ElevatedButton(
                    onPressed: state.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    child: state.isSubmitting
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
                              Text('重置中...'),
                            ],
                          )
                        : const Text('重置密码'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
