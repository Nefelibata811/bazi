// 文件：对话录入bar
//
// UI 组件：可复用的界面片段。
// 路径：`lib/features/ai_chat/presentation/widgets/chat_input_bar.dart`。
//
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/app_strings.dart';

/// 类 `ChatInputBar`：实现 Chat Input Bar 相关逻辑。
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSend,
    required this.onAddRecord,
    required this.onCancel,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onAddRecord;
  final VoidCallback onCancel;

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAddRecord,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.add, size: 20, color: AppColors.gold.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              enabled: !isLoading,
              textInputAction: TextInputAction.send,
              onFieldSubmitted: isLoading ? null : (_) => onSend(),
              decoration: InputDecoration(
                hintText: '输入你的问题...',
                filled: true,
                fillColor: AppColors.rice,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: isLoading ? AppStrings.actionCancelAnalysis : '发送',
            child: GestureDetector(
              onTap: isLoading ? onCancel : onSend,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isLoading ? AppColors.cinnabar : AppColors.gold,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isLoading
                    ? const Icon(Icons.stop_rounded, color: Colors.white, size: 18)
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
