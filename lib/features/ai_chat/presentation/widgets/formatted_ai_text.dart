// 文件：格式化AItext
//
// UI 组件：可复用的界面片段。
// 路径：`lib/features/ai_chat/presentation/widgets/formatted_ai_text.dart`。
//
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Renders AI text with **bold** segments.
class FormattedAiText extends StatelessWidget {
  const FormattedAiText({
    super.key,
    required this.text,
    this.style,
  });

  final String text;
  final TextStyle? style;

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyMedium;
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var start = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: base?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    if (spans.isEmpty) {
      return Text(text, style: base);
    }

    return Text.rich(
      TextSpan(style: base, children: spans),
    );
  }
}

/// Extracts bullet suggestions after 「你可能还想了解：」
List<String> parseFollowUpSuggestions(String content) {
  final lines = content.split('\n');
  final start = lines.indexWhere((l) => l.contains('你可能还想了解'));
  if (start < 0) return const [];

  final result = <String>[];
  for (var i = start + 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    if (line.startsWith('•') || line.startsWith('-') || line.startsWith('·')) {
      result.add(line.replaceFirst(RegExp(r'^[•\-·]\s*'), ''));
    } else if (result.isNotEmpty) {
      break;
    }
  }
  return result;
}

/// Body text without the follow-up suggestion block (for display split).
String stripFollowUpBlock(String content) {
  const markers = ['你可能还想了解', '推荐追问', '**已生成完毕。**'];
  var end = content.length;
  for (final marker in markers) {
    final idx = content.indexOf(marker);
    if (idx >= 0 && idx < end) end = idx;
  }
  if (end < content.length) {
    return content.substring(0, end).trimRight();
  }
  return content;
}
