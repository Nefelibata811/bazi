// 文件：追问upquestion生成器
//
// 路径：`lib/features/ai_chat/application/follow_up_question_generator.dart`。
//
import 'dart:math';

import '../../../domain/services/chat_repository.dart';

/// Picks 3 contextual follow-up questions after each assistant reply.
class FollowUpQuestionGenerator {
  static final Random _random = Random();

  static const _followUpHeader = '你可能还想了解：';

  static List<String> generate({
    required String assistantReply,
    required List<ChatMessage> messages,
    required String personName,
    required String reportSummary,
  }) {
    final lastUser = _lastUserQuestion(messages);
    final summarySnippet = reportSummary.length <= 800
        ? reportSummary
        : reportSummary.substring(0, 800);
    final combined = '$lastUser $assistantReply $summarySnippet';
    final userTopics = _collectUserTopics(messages);

    final pool = <String>{};

    void addAll(List<String> items) => pool.addAll(items);

    if (_mentions(combined, ['事业', '财运', '工作', '职场', '收入', '投资'])) {
      addAll([
        '$personName 未来三年事业财运的关键转折点在哪？',
        '当前命局最适合发展的行业与方位有哪些？',
        '如何规避财星受克带来的财务风险？',
      ]);
    }
    if (_mentions(combined, ['感情', '婚姻', '桃花', '配偶', '恋爱'])) {
      addAll([
        '$personName 感情婚姻中需要留意的年份与征兆是什么？',
        '命盘中哪些因素会影响婚恋时机？',
        '如何改善感情运势的日常建议？',
      ]);
    }
    if (_mentions(combined, ['健康', '身体', '疾病', '养生'])) {
      addAll([
        '命局中哪些五行失衡需要特别注意健康？',
        '有哪些适合的养生调理方向？',
        '流年对健康影响较大的时段是何时？',
      ]);
    }
    if (_mentions(combined, ['大运', '流年', '运势', '今年', '明年'])) {
      addAll([
        '当前大运与接下来一步大运的衔接有何影响？',
        '近年流年里哪些年份宜进取、哪些宜守成？',
        '大运交接前后需要提前做好哪些准备？',
      ]);
    }
    if (_mentions(combined, ['用神', '喜神', '忌神', '格局', '日主'])) {
      addAll([
        '如何根据用神选择有利的颜色、方位与行业？',
        '格局中最需要强化与规避的五行分别是什么？',
        '日主强弱变化对近年决策有何提示？',
      ]);
    }
    if (_mentions(combined, ['神煞', '贵人', '空亡', '刑冲'])) {
      addAll([
        '命盘中神煞对现实生活的具体影响有哪些？',
        '哪些神煞需要格外留意并如何化解？',
        '贵人运在何时较易显现？',
      ]);
    }
    if (_mentions(combined, ['子女', '学业', '考试', '教育'])) {
      addAll([
        '子女缘分与教育方式上有何命理提示？',
        '学业考试方面哪些年份更有利？',
        '如何为子女营造有利的成长环境？',
      ]);
    }

    for (final topic in userTopics) {
      switch (topic) {
        case '事业财运':
          addAll([
            '结合刚才的分析，事业方面还有哪些细节值得深挖？',
            '财运上是否适合合作投资或独立经营？',
          ]);
        case '感情婚姻':
          addAll([
            '感情方面还有哪些年份需要特别留心？',
            '配偶特征与相处模式上有何命理提示？',
          ]);
        case '健康':
          addAll([
            '健康调理上还有哪些具体建议？',
          ]);
        case '大运流年':
          addAll([
            '能否结合大运再细化近五年的运势走向？',
          ]);
      }
    }

    if (lastUser.isNotEmpty && lastUser.length > 4) {
      addAll([
        '关于「${_shorten(lastUser, 18)}」，还有哪些延伸角度可以解读？',
        '如果按刚才的问题深入一层，命盘还提示了什么？',
      ]);
    }

    addAll(_defaultPool(personName, reportSummary));

    final candidates = pool.toList()..shuffle(_random);
    if (candidates.length >= 3) {
      return candidates.take(3).toList();
    }

    final fallbacks = _defaultPool(personName, reportSummary)..shuffle(_random);
    for (final q in fallbacks) {
      if (candidates.length >= 3) break;
      if (!candidates.contains(q)) candidates.add(q);
    }
    return candidates.take(3).toList();
  }

  static String followUpHeader() => _followUpHeader;

  static bool _mentions(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  static String _lastUserQuestion(List<ChatMessage> messages) {
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (m.role == 'user' && m.content.trim().isNotEmpty) {
        return m.content.trim();
      }
    }
    return '';
  }

  static Set<String> _collectUserTopics(List<ChatMessage> messages) {
    final topics = <String>{};
    for (final m in messages.where((m) => m.role == 'user')) {
      final c = m.content;
      if (_mentions(c, ['事业', '财运', '工作'])) topics.add('事业财运');
      if (_mentions(c, ['感情', '婚姻', '桃花'])) topics.add('感情婚姻');
      if (_mentions(c, ['健康', '身体'])) topics.add('健康');
      if (_mentions(c, ['大运', '流年', '运势'])) topics.add('大运流年');
    }
    return topics;
  }

  static List<String> _defaultPool(String personName, String summary) {
    final qs = <String>[
      '$personName 的整体命局优势与短板分别是什么？',
      '近年有哪些需要把握的时机与需要规避的风险？',
      '日常生活中有哪些开运习惯较为适宜？',
      '命盘中最值得关注的十神关系是什么？',
    ];
    if (summary.contains('用神')) {
      qs.add('用神调候在实际生活中如何落实？');
    }
    if (summary.contains('称骨')) {
      qs.add('称骨与四柱结论有哪些相互印证之处？');
    }
    if (summary.contains('大运')) {
      qs.add('当前大运对整体运势的主导影响是什么？');
    }
    return qs;
  }

  static String _shorten(String text, int maxLen) {
    final t = text.replaceAll('\n', ' ').trim();
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen)}…';
  }
}
