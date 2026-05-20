import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/bootstrap_app.dart';
import '../../../../app/theme/app_colors.dart';
import '../../application/auth_controller.dart';
import '../widgets/otp_countdown_controller.dart';
import 'forgot_password_page.dart';

enum _LoginMode { email, phone }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  _LoginMode _mode = _LoginMode.email;
  bool _otpSent = false;
  bool _sendingOtp = false;
  final _otpCountdown = OtpCountdownController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
      }
    });
    await prefs.remove('saved_password');
  }

  @override
  void dispose() {
    _otpCountdown.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startOtpCountdown() {
    setState(() => _otpSent = true);
    _otpCountdown.start(
      seconds: 60,
      mounted: () => mounted,
      onTick: (_) => setState(() {}),
    );
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入手机号')),
      );
      return;
    }

    ref.read(authControllerProvider.notifier).clearError();
    setState(() => _sendingOtp = true);

    final err = await ref
        .read(authControllerProvider.notifier)
        .sendPhoneLoginOtp(phone);

    if (!mounted) return;
    setState(() => _sendingOtp = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }

    _startOtpCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('验证码已发送')),
    );
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authControllerProvider.notifier).clearError();

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text, _passwordController.text);

    if (success && mounted) {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.remove('saved_password');
      } else {
        await prefs.setBool('remember_me', false);
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
      }
    }
  }

  Future<void> _submitPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入手机号')),
      );
      return;
    }
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入验证码')),
      );
      return;
    }

    ref.read(authControllerProvider.notifier).clearError();

    await ref.read(authControllerProvider.notifier).verifyPhoneLogin(
          phone,
          _otpController.text,
        );
  }

  Widget _modeSwitcher(TextTheme textTheme, bool disabled) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: disabled
                ? null
                : () => setState(() => _mode = _LoginMode.email),
            style: OutlinedButton.styleFrom(
              backgroundColor: _mode == _LoginMode.email
                  ? AppColors.gold.withValues(alpha: 0.12)
                  : null,
              side: BorderSide(
                color: _mode == _LoginMode.email
                    ? AppColors.gold
                    : AppColors.deepGray.withValues(alpha: 0.3),
              ),
            ),
            child: Text('邮箱登录', style: textTheme.bodySmall),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: disabled
                ? null
                : () => setState(() => _mode = _LoginMode.phone),
            style: OutlinedButton.styleFrom(
              backgroundColor: _mode == _LoginMode.phone
                  ? AppColors.gold.withValues(alpha: 0.12)
                  : null,
              side: BorderSide(
                color: _mode == _LoginMode.phone
                    ? AppColors.gold
                    : AppColors.deepGray.withValues(alpha: 0.3),
              ),
            ),
            child: Text('手机验证码', style: textTheme.bodySmall),
          ),
        ),
      ],
    );
  }

  Widget _emailForm(bool loading, bool connecting, TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: '邮箱',
            hintText: '请输入邮箱',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          enabled: !loading,
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
            hintText: '请输入密码',
            prefixIcon: Icon(Icons.lock_outlined),
          ),
          enabled: !loading,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入密码';
            }
            if (value.length < 6) {
              return '密码长度至少 6 位';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submitEmail(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v),
                activeThumbColor: AppColors.gold,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Text('记住密码', style: textTheme.bodySmall),
            ),
            const Spacer(),
            TextButton(
              onPressed: loading
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ForgotPasswordPage(),
                        ),
                      );
                    },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '忘记密码？',
                style: textTheme.bodySmall?.copyWith(color: AppColors.gold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: loading || connecting ? null : _submitEmail,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
          ),
          child: loading
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
                    Text('登录中...'),
                  ],
                )
              : const Text('登录'),
        ),
      ],
    );
  }

  Widget _phoneForm(bool loading, bool connecting, TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: '手机号',
            hintText: '请输入 11 位手机号',
            prefixIcon: Icon(Icons.phone_android_outlined),
          ),
          enabled: !loading && !_sendingOtp,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '验证码',
                  hintText: '短信验证码',
                  prefixIcon: Icon(Icons.sms_outlined),
                ),
                enabled: !loading,
                onFieldSubmitted: (_) => _submitPhone(),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: loading || _sendingOtp || _otpCountdown.isActive
                    ? null
                    : _sendOtp,
                child: _sendingOtp
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _otpCountdown.isActive
                            ? '${_otpCountdown.remaining}s'
                            : '获取验证码',
                        style: textTheme.bodySmall,
                      ),
              ),
            ),
          ],
        ),
        if (_otpSent && !_otpCountdown.isActive) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: loading || _sendingOtp ? null : _sendOtp,
              child: Text(
                '重新发送',
                style: textTheme.bodySmall?.copyWith(color: AppColors.gold),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: loading || connecting ? null : _submitPhone,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
          ),
          child: loading
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
                    Text('验证中...'),
                  ],
                )
              : const Text('登录 / 注册'),
        ),
        const SizedBox(height: 8),
        Text(
          '未注册的手机号验证后将自动创建账号',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.deepGray.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final supabaseReady = ref.watch(supabaseReadyProvider);
    final initError = ref.watch(supabaseInitErrorProvider);
    final textTheme = Theme.of(context).textTheme;
    final error = state.error ?? initError;
    final loading = state.loading || state.isSubmitting;
    final connecting = !supabaseReady && initError == null;

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
                  Text('八  字', style: textTheme.displaySmall),
                  const SizedBox(height: 4),
                  Text(
                    'B A Z I',
                    style: textTheme.bodySmall?.copyWith(
                      letterSpacing: 6,
                      color: AppColors.deepGray,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _modeSwitcher(textTheme, loading),
                  const SizedBox(height: 24),
                  if (_mode == _LoginMode.email)
                    _emailForm(loading, connecting, textTheme)
                  else
                    _phoneForm(loading, connecting, textTheme),
                  if (connecting) ...[
                    const SizedBox(height: 12),
                    Text(
                      '正在连接服务器…',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.deepGray,
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
                  if (_mode == _LoginMode.email) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () {
                              Navigator.of(context)
                                  .pushReplacementNamed('/register');
                            },
                      child: Text(
                        '还没有账号？立即注册',
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
