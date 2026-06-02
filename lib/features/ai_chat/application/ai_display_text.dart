// 文件：AI 展示文本规范化
//
// 将模型偶发的 Markdown 表格转为 App 可读的纯文本段落。
//
/// Converts Markdown table rows and separators into plain Chinese lines.
String normalizeAiDisplayText(String text) {
  if (!text.contains('|')) return text;

  final lines = text.split('\n');
  final out = <String>[];
  final tableSeparator = RegExp(r'^\|?[\s\-:|]+\|?$');

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      out.add('');
      continue;
    }
    if (tableSeparator.hasMatch(trimmed)) continue;

    if (trimmed.startsWith('|') && trimmed.contains('|', 1)) {
      final cells = trimmed
          .split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      if (cells.length >= 2) {
        final head = cells.first;
        final rest = cells.skip(1).join('，');
        out.add('$head：$rest');
      } else if (cells.isNotEmpty) {
        out.add(cells.join(' '));
      }
      continue;
    }

    out.add(line);
  }

  return out.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trimRight();
}
