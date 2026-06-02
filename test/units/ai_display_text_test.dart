import 'package:bazi_app/features/ai_chat/application/ai_display_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeAiDisplayText converts markdown table rows', () {
    const input = '''
三、综合结论
| 年份 | 正缘概率 | 婚姻概率 |
|:---|:---|:---|
| 2026丙午年 | 20% | 几乎为零 |''';

    final out = normalizeAiDisplayText(input);
    expect(out, contains('三、综合结论'));
    expect(out, isNot(contains('|:---')));
    expect(out, contains('2026丙午年：20%，几乎为零'));
  });

  test('normalizeAiDisplayText leaves plain text unchanged', () {
    const text = '**甲木日主** 偏弱，宜补水木。';
    expect(normalizeAiDisplayText(text), text);
  });
}
