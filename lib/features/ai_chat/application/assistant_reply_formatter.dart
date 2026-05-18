import '../../../domain/services/chat_repository.dart';
import 'follow_up_question_generator.dart';

/// Strips model-appended trailers and appends client-side follow-up questions.
class AssistantReplyFormatter {
  static const _markers = [
    '你可能还想了解',
    '推荐追问',
    '**已生成完毕。**',
    '已生成完毕',
  ];

  static String finalize({
    required String raw,
    required bool isInitialAnalysis,
    required List<ChatMessage> conversation,
    required String personName,
    required String reportSummary,
  }) {
    final body = stripFollowUpTrailer(raw);
    final questions = FollowUpQuestionGenerator.generate(
      assistantReply: body,
      messages: conversation,
      personName: personName,
      reportSummary: reportSummary,
    );

    final buf = StringBuffer(body);
    buf.writeln();
    buf.writeln();
    if (isInitialAnalysis) {
      buf.writeln('**已生成完毕。**');
      buf.writeln();
    }
    buf.writeln(FollowUpQuestionGenerator.followUpHeader());
    for (final q in questions) {
      buf.writeln('• $q');
    }
    return buf.toString();
  }

  static String stripFollowUpTrailer(String content) {
    var text = content.trimRight();
    for (final marker in _markers) {
      final idx = text.indexOf(marker);
      if (idx >= 0) {
        text = text.substring(0, idx).trimRight();
      }
    }
    return text.trim();
  }
}
