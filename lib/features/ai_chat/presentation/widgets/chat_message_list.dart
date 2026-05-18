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
  });

  final ChatState state;
  final ScrollController scrollController;
  final ValueChanged<String> onSuggestionTap;

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  @override
  void didUpdateWidget(covariant ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final textTheme = Theme.of(context).textTheme;

    final hasStreamingSlot = state.isLoading;

    final lastAssistantIndex = state.messages.lastIndexWhere(
      (m) => m.role == 'assistant',
    );

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.messages.length + (hasStreamingSlot ? 1 : 0),
      itemBuilder: (ctx, index) {
        if (index < state.messages.length) {
          final msg = state.messages[index];
          final isUser = msg.role == 'user';
          final showSuggestions = !isUser &&
              !state.isLoading &&
              index == lastAssistantIndex;

          return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.gold.withOpacity(0.08)
                    : AppColors.paper,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 18),
                ),
                border: Border.all(color: AppColors.line.withOpacity(0.5)),
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
          );
        }

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
              border: Border.all(color: AppColors.line.withOpacity(0.5)),
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
                          color: AppColors.gold.withOpacity(0.6),
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
      },
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
                      color: AppColors.gold.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.2),
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
