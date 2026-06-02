// 文件：列表加载失败重试
//
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// 网络/云端列表加载失败时的占位与重试按钮。
class ListLoadError extends StatelessWidget {
  const ListLoadError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.deepGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
