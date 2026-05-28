// 文件：个人资料页面
//
// 页面：负责 UI 展示与用户操作。
// 路径：`lib/features/auth/presentation/pages/profile_page.dart`。
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/phone_utils.dart';
import '../../application/auth_controller.dart';
import '../widgets/otp_countdown_controller.dart';

/// 类 `ProfilePage`：实现 Profile Page 相关逻辑。
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

/// 私有类 `_ProfilePageState`：Profile Page State。
class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nicknameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  bool _hasNameChanges = false;
  bool _hasAvatarChanges = false;
  bool _showAvatarInput = false;
  final _bindPhoneController = TextEditingController();
  final _bindOtpController = TextEditingController();
  bool _showBindPhone = false;
  bool _bindOtpSent = false;
  bool _sendingBindOtp = false;
  final _bindOtpCountdown = OtpCountdownController();

  // 初始化：注册首帧回调、预加载列表数据。

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nicknameController.text = user?.nickname ?? '';
    _avatarUrlController.text = user?.avatarUrl ?? '';
  }

  // 释放监听器与控制器资源。

  @override
  void dispose() {
    _bindOtpCountdown.dispose();
    _nicknameController.dispose();
    _avatarUrlController.dispose();
    _bindPhoneController.dispose();
    _bindOtpController.dispose();
    super.dispose();
  }

  Future<void> _sendBindOtp() async {
    final phone = _bindPhoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入手机号')),
      );
      return;
    }

    setState(() => _sendingBindOtp = true);
    final err = await ref
        .read(authControllerProvider.notifier)
        .sendBindPhoneOtp(phone);
    if (!mounted) return;
    setState(() => _sendingBindOtp = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }

    setState(() => _bindOtpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('验证码已发送')),
    );

    _bindOtpCountdown.start(
      seconds: 60,
      mounted: () => mounted,
      onTick: (_) => setState(() {}),
    );
  }

  Future<void> _verifyBindPhone() async {
    final success = await ref.read(authControllerProvider.notifier).verifyBindPhone(
          _bindPhoneController.text.trim(),
          _bindOtpController.text,
        );

    if (!mounted) return;
    if (success) {
      setState(() {
        _showBindPhone = false;
        _bindOtpSent = false;
        _bindPhoneController.clear();
        _bindOtpController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('手机号绑定成功')),
      );
    } else {
      final err = ref.read(authControllerProvider).error;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
    }
  }

  Future<void> _saveNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(nickname: nickname);

    if (mounted) {
      if (success) {
        setState(() => _hasNameChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('昵称更新成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新失败，请重试')),
        );
      }
    }
  }

  Future<void> _saveAvatarUrl() async {
    final url = _avatarUrlController.text.trim();
    if (url.isEmpty) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(avatarUrl: url);

    if (mounted) {
      if (success) {
        setState(() {
          _hasAvatarChanges = false;
          _showAvatarInput = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像更新成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新失败，请重试')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('退出', style: TextStyle(color: AppColors.cinnabar)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (_) => false);
    }
  }

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final user = state.user;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人信息'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: user?.avatarUrl != null &&
                              user!.avatarUrl!.isNotEmpty
                          ? Image.network(
                              user.avatarUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _defaultAvatar(textTheme),
                            )
                          : _defaultAvatar(textTheme),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!_showAvatarInput)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _showAvatarInput = true);
                        _avatarUrlController.text = user?.avatarUrl ?? '';
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(
                        '更换头像',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.deepGray,
                        ),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 280,
                      child: TextFormField(
                        controller: _avatarUrlController,
                        decoration: const InputDecoration(
                          labelText: '头像URL',
                          hintText: '请输入图片链接地址',
                          isDense: true,
                          suffixIcon: Icon(Icons.link, size: 18),
                        ),
                        onChanged: (_) {
                          if (!_hasAvatarChanges) {
                            setState(() => _hasAvatarChanges = true);
                          }
                        },
                      ),
                    ),
                    if (_hasAvatarChanges) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showAvatarInput = false;
                                _hasAvatarChanges = false;
                                _avatarUrlController.text =
                                    user?.avatarUrl ?? '';
                              });
                            },
                            child: const Text('取消'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed:
                                state.isSubmitting ? null : _saveAvatarUrl,
                            child: Text(state.isSubmitting ? '保存中...' : '保存头像'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('基本信息', style: textTheme.titleMedium),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 20, color: AppColors.deepGray),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            user?.email ?? '',
                            style: textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.phone_android_outlined,
                              size: 20, color: AppColors.deepGray),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.phone != null && user!.phone!.isNotEmpty
                                    ? PhoneUtils.mask(user.phone)
                                    : '未绑定手机号',
                                style: textTheme.bodyMedium,
                              ),
                              if (!_showBindPhone)
                                TextButton(
                                  onPressed: () => setState(() {
                                    _showBindPhone = true;
                                    _bindPhoneController.clear();
                                    _bindOtpController.clear();
                                    _bindOtpSent = false;
                                  }),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    user?.phone != null &&
                                            user!.phone!.isNotEmpty
                                        ? '更换手机号'
                                        : '绑定手机号',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.gold,
                                    ),
                                  ),
                                )
                              else ...[
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _bindPhoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: '手机号',
                                    hintText: '11 位中国大陆手机号',
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _bindOtpController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: '验证码',
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: state.isSubmitting ||
                                              _sendingBindOtp ||
                                              _bindOtpCountdown.isActive
                                          ? null
                                          : _sendBindOtp,
                                      child: _sendingBindOtp
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              _bindOtpCountdown.isActive
                                                  ? '${_bindOtpCountdown.remaining}s'
                                                  : '获取验证码',
                                              style: textTheme.bodySmall,
                                            ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () => setState(() {
                                        _showBindPhone = false;
                                        _bindOtpSent = false;
                                      }),
                                      child: const Text('取消'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: state.isSubmitting
                                          ? null
                                          : _verifyBindPhone,
                                      child: Text(
                                        state.isSubmitting
                                            ? '绑定中...'
                                            : '确认绑定',
                                      ),
                                    ),
                                  ],
                                ),
                                if (_bindOtpSent)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '验证码已发送至手机',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.deepGray,
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: Icon(Icons.person_outline,
                              size: 20, color: AppColors.deepGray),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _nicknameController,
                            decoration: const InputDecoration(
                              labelText: '昵称',
                              hintText: '给自己取一个名字',
                            ),
                            onChanged: (_) {
                              if (!_hasNameChanges) {
                                setState(() => _hasNameChanges = true);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_hasNameChanges) ...[
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: state.isSubmitting ? null : _saveNickname,
                        child: Text(state.isSubmitting ? '保存中...' : '保存昵称'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('账号操作', style: textTheme.titleMedium),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('退出登录'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.cinnabar,
                          side: const BorderSide(color: AppColors.cinnabar),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar(TextTheme textTheme) {
    return Container(
      color: AppColors.cinnabar.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: 48,
        color: AppColors.cinnabar.withValues(alpha: 0.4),
      ),
    );
  }
}
