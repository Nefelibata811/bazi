import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/app_strings.dart';
import '../../application/chat_controller.dart';
import 'formatted_ai_text.dart';

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({
    super.key,
    required this.state,
    required this.scrollController,
    required this.onSuggestionTap,
    required this.onDeleteMessage,
    this.sessionKey = '',
  });

  final ChatState state;
  final ScrollController scrollController;
  final ValueChanged<String> onSuggestionTap;
  final ValueChanged<int> onDeleteMessage;

  /// 切换命盘时重置「仅显示最近消息」窗口。
  final String sessionKey;

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  static const _initialTailCount = 4;
  static const _loadMoreBatch = 8;

  int _visibleFromIndex = 0;
  bool _pinnedToBottom = true;
  bool _isPrependingEarlier = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    _applyTailWindow(jumpToBottom: true);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.sessionKey != oldWidget.sessionKey) {
      _applyTailWindow(jumpToBottom: true);
      return;
    }

    final oldLen = oldWidget.state.messages.length;
    final newLen = widget.state.messages.length;
    if (oldLen == 0 && newLen > 0) {
      _applyTailWindow(jumpToBottom: true);
      return;
    }

    if (newLen > oldLen) {
      if (_pinnedToBottom) {
        _scrollToBottom(animate: true);
      }
      return;
    }
  }

  void _applyTailWindow({required bool jumpToBottom}) {
    final len = widget.state.messages.length;
    _visibleFromIndex =
        len <= _initialTailCount ? 0 : len - _initialTailCount;
    _pinnedToBottom = true;
    if (jumpToBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animate: false, jump: true);
      });
    }
  }

  void _onScroll() {
    final controller = widget.scrollController;
    if (!controller.hasClients) return;

    final pos = controller.position;
    if (!pos.hasPixels) return;

    _pinnedToBottom = pos.maxScrollExtent - pos.pixels < 72;

    // 内容不足一屏时不要误触「加载更早」；仅在滚到顶部附近时加载。
    if (_visibleFromIndex == 0) return;
    if (pos.maxScrollExtent < 64) return;
    if (pos.pixels > 72) return;
    if (_isPrependingEarlier) return;

    _prependEarlierMessages();
  }

  void _prependEarlierMessages({int? batch}) {
    final next = math.max(
      0,
      _visibleFromIndex - (batch ?? _loadMoreBatch),
    );
    if (next == _visibleFromIndex) return;
    if (_isPrependingEarlier) return;

    _isPrependingEarlier = true;
    final controller = widget.scrollController;
    final oldMax =
        controller.hasClients ? controller.position.maxScrollExtent : 0.0;
    final oldOffset = controller.hasClients ? controller.position.pixels : 0.0;

    setState(() => _visibleFromIndex = next);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        _jumpToClamped(
          oldOffset + (controller.position.maxScrollExtent - oldMax),
        );
      }
      _isPrependingEarlier = false;
    });
  }

  void _loadAllEarlier() => _prependEarlierMessages(batch: _visibleFromIndex);

  void _jumpToClamped(double offset) {
    final controller = widget.scrollController;
    if (!controller.hasClients) return;
    final max = controller.position.maxScrollExtent;
    controller.jumpTo(offset.clamp(0.0, max));
  }

  void _scrollToBottom({required bool animate, bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.scrollController.hasClients) return;
      final pos = widget.scrollController.position;
      final target = pos.maxScrollExtent;
      if (jump || !animate) {
        _jumpToClamped(target);
      } else {
        widget.scrollController.animateTo(
          target.clamp(0.0, pos.maxScrollExtent),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  int? _globalMessageIndex(int listIndex, bool hasOlderBanner) {
    final offset = hasOlderBanner ? 1 : 0;
    final local = listIndex - offset;
    if (local < 0) return null;

    final visibleCount = widget.state.messages.length - _visibleFromIndex;
    if (local >= visibleCount) return null;

    return _visibleFromIndex + local;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final textTheme = Theme.of(context).textTheme;
    final messages = state.messages;
    final hasStreamingSlot = state.isLoading;
    final hasOlder = _visibleFromIndex > 0;

    final lastAssistantIndex = messages.lastIndexWhere(
      (m) => m.role == 'assistant',
    );

    final visibleCount = messages.length - _visibleFromIndex;
    final itemCount =
        (hasOlder ? 1 : 0) + visibleCount + (hasStreamingSlot ? 1 : 0);

    return ListView.builder(
      controller: widget.scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (ctx, index) {
        if (hasOlder && index == 0) {
          return _EarlierHistoryBanner(
            hiddenCount: _visibleFromIndex,
            onTap: _loadAllEarlier,
          );
        }

        final msgIndex = _globalMessageIndex(index, hasOlder);
        if (msgIndex == null) {
          final streamingContent = state.streamingContent;
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: AppColors.line.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI 命理师',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.cinnabar,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (streamingContent == null || streamingContent.isEmpty)
                    Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.aiAnalyzing,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.deepGray,
                          ),
                        ),
                      ],
                    )
                  else
                    FormattedAiText(
                      text: streamingContent,
                      style: textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          );
        }

        final msg = messages[msgIndex];
        final isUser = msg.role == 'user';
        final showSuggestions = !isUser &&
            !state.isLoading &&
            msgIndex == lastAssistantIndex;

        return GestureDetector(
          onLongPress: () => widget.onDeleteMessage(msgIndex),
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.gold.withValues(alpha: 0.08)
                    : AppColors.paper,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 18),
                ),
                border:
                    Border.all(color: AppColors.line.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? '你' : 'AI 命理师',
                    style: textTheme.bodySmall?.copyWith(
                      color: isUser ? AppColors.gold : AppColors.cinnabar,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isUser)
                    Text(msg.content, style: textTheme.bodyMedium)
                  else
                    AssistantMessageBody(
                      content: msg.content,
                      showSuggestions: showSuggestions,
                      onSuggestionTap: widget.onSuggestionTap,
                      textTheme: textTheme,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EarlierHistoryBanner extends StatelessWidget {
  const _EarlierHistoryBanner({
    required this.hiddenCount,
    required this.onTap,
  });

  final int hiddenCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 18,
                    color: AppColors.gold.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '上滑或点击加载更早的 $hiddenCount 条对话',
                    style: textTheme.bodySmall?.copyWith(color: AppColors.gold),
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

class AssistantMessageBody extends StatelessWidget {
  const AssistantMessageBody({
    super.key,
    required this.content,
    required this.showSuggestions,
    required this.onSuggestionTap,
    required this.textTheme,
  });

  final String content;
  final bool showSuggestions;
  final ValueChanged<String> onSuggestionTap;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final displayText =
        showSuggestions ? stripFollowUpBlock(content) : content;
    final suggestions = showSuggestions
        ? parseFollowUpSuggestions(content)
        : const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormattedAiText(text: displayText, style: textTheme.bodyMedium),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            '推荐追问',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.deepGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...suggestions.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSuggestionTap(q),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      q,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
