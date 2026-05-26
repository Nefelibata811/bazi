import 'package:flutter/material.dart';

import '../../infrastructure/birth_display_label.dart';

/// 出生时间展示：自动分行，限制行数并省略，避免窄屏溢出。
class BirthLabelText extends StatelessWidget {
  const BirthLabelText({
    super.key,
    required this.lines,
    this.style,
    this.maxLines = 2,
    this.color,
  });

  final List<String> lines;
  final TextStyle? style;
  final int maxLines;
  final Color? color;

  factory BirthLabelText.fromRequestJson(
    String requestJson, {
    TextStyle? style,
    int maxLines = 3,
    Color? color,
  }) {
    return BirthLabelText(
      lines: birthDisplayLinesFromRequestJson(requestJson) ?? const [],
      style: style,
      maxLines: maxLines,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();

    final textStyle = (style ?? Theme.of(context).textTheme.bodySmall)
        ?.copyWith(color: color);

    return Text(
      lines.join('\n'),
      style: textStyle,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
    );
  }
}
