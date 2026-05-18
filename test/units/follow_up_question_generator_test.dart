import 'package:bazi_app/domain/services/chat_repository.dart';
import 'package:bazi_app/features/ai_chat/application/assistant_reply_formatter.dart';
import 'package:bazi_app/features/ai_chat/application/follow_up_question_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('每次生成恰好 3 个推荐追问', () {
    final qs = FollowUpQuestionGenerator.generate(
      assistantReply: '您的事业宫见官星，近年财运以稳为主。',
      messages: const [
        ChatMessage(role: 'user', content: '请分析事业财运'),
      ],
      personName: '张三',
      reportSummary: '日主：甲木，用神：水',
    );
    expect(qs.length, equals(3));
    expect(qs.every((q) => q.trim().isNotEmpty), isTrue);
  });

  test('追问回复也会追加推荐问题块', () {
    final out = AssistantReplyFormatter.finalize(
      raw: '关于感情，命盘显示……',
      isInitialAnalysis: false,
      conversation: const [
        ChatMessage(role: 'user', content: '感情如何？'),
      ],
      personName: '李四',
      reportSummary: '日主：乙木',
    );
    expect(out, contains('你可能还想了解：'));
    expect(out.split('•').length, greaterThanOrEqualTo(4));
    expect(out, isNot(contains('**已生成完毕。**')));
  });

  test('首轮分析保留已生成完毕并追加 3 问', () {
    final out = AssistantReplyFormatter.finalize(
      raw: '命局概述……',
      isInitialAnalysis: true,
      conversation: const [
        ChatMessage(role: 'user', content: '请分析'),
      ],
      personName: '王五',
      reportSummary: '日主：丙火',
    );
    expect(out, contains('**已生成完毕。**'));
    expect(out, contains('你可能还想了解：'));
  });
}
