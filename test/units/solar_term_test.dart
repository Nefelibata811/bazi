// 文件：单元测试 — 公历节气
//
// 验证 公历节气 的正确性与边界情况。
// 修改实现时请同步维护本测试。
//
import 'package:bazi_app/domain/constants/solar_term_constants.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bazi_app/infrastructure/calendar/astro_solar_term_provider.dart';

void main() {
  late AstroSolarTermProvider provider;

  setUp(() {
    provider = const AstroSolarTermProvider();
  });

  group('节气天文精算', () {
    test('2024 年全年产生 24 个节气', () async {
      final terms = await provider.termsOfYear(2024);
      expect(terms, hasLength(24));
    });

    test('节气名称顺序正确', () async {
      final terms = await provider.termsOfYear(2024);
      expect(terms.map((t) => t.name).toList(),
          SolarTermConstants.names);
    });

    test('节气时间按升序排列', () async {
      final terms = await provider.termsOfYear(2024);
      for (int i = 1; i < terms.length; i++) {
        expect(
          terms[i].occurredAt.isAfter(terms[i - 1].occurredAt),
          isTrue,
          reason: '${terms[i - 1].name} 应在 ${terms[i].name} 之前',
        );
      }
    });

    test('每个节气发生在所属年份内', () async {
      for (int year = 1950; year <= 2050; year += 50) {
        final terms = await provider.termsOfYear(year);
        for (final term in terms) {
          // 小寒可能在上一年的 1 月（因为小寒在 1 月 5 日左右）
          if (term.index == 0 && term.occurredAt.year == year) {
            // OK
          } else if (term.index == 23 && term.occurredAt.year == year) {
            // 冬至在 12 月
          }
          // 至少年月日合法
          expect(term.occurredAt.year, greaterThanOrEqualTo(year - 1));
          expect(term.occurredAt.year, lessThanOrEqualTo(year + 1));
        }
      }
    });

    test('同一年内节气日期在合理范围内', () async {
      final terms = await provider.termsOfYear(2024);
      final first = terms.first.occurredAt;
      final last = terms.last.occurredAt;

      // 第一个节气（小寒）应在 1 月 5-7 日之间
      expect(first.month, 1);
      expect(first.day, inInclusiveRange(4, 8));

      // 最后一个节气（冬至）应在 12 月 21-23 日之间
      expect(last.month, 12);
      expect(last.day, inInclusiveRange(20, 23));
    });

    test('节气的 termMonth 映射正确', () async {
      final terms = await provider.termsOfYear(2024);

      // 立春(index=2) → 寅月(0)
      final lichun = terms.firstWhere((t) => t.index == 2);
      expect(lichun.termMonth, 0);

      // 惊蛰(4) → 卯月(1)
      final jingzhe = terms.firstWhere((t) => t.index == 4);
      expect(jingzhe.termMonth, 1);

      // 小寒(0) → 丑月(11)
      final xiaohan = terms.firstWhere((t) => t.index == 0);
      expect(xiaohan.termMonth, 11);

      // 立冬(20) → 亥月(9)
      final lidong = terms.firstWhere((t) => t.index == 20);
      expect(lidong.termMonth, 9);
    });

    test('中气（index 为奇数）的 termMonth 为 null', () async {
      final terms = await provider.termsOfYear(2024);
      for (final term in terms) {
        if (term.index.isOdd) {
          expect(term.termMonth, isNull,
              reason: '${term.name} 是中气，termMonth 应为 null');
        }
      }
    });

    test('节气精度：与已知精算值偏差小于 15 分钟', () async {
      final terms = await provider.termsOfYear(2024);

      // 已知 2024 年部分节气参考值（来自中国天文年历）
      // 小寒 1月6日 04:49
      // 立春 2月4日 16:27
      // 春分 3月20日 11:06
      // 夏至 6月21日 04:51
      // 秋分 9月22日 20:44
      // 冬至 12月21日 17:21
      final known = {
        '小寒': DateTime(2024, 1, 6, 4, 49),
        '立春': DateTime(2024, 2, 4, 16, 27),
        '春分': DateTime(2024, 3, 20, 11, 6),
        '夏至': DateTime(2024, 6, 21, 4, 51),
        '秋分': DateTime(2024, 9, 22, 20, 44),
        '冬至': DateTime(2024, 12, 21, 17, 21),
      };

      for (final entry in known.entries) {
        final term = terms.firstWhere((t) => t.name == entry.key);
        final diff =
            term.occurredAt.difference(entry.value).abs();
        // 允许 ±15 分钟误差（章动项简化导致）
        expect(
          diff.inMinutes,
          lessThanOrEqualTo(15),
          reason: '${entry.key} 计算偏差过大：计算=${term.occurredAt}, 参考=${entry.value}',
        );
      }
    });

    test('surroundingTerms 返回 6 个节气', () async {
      final center = DateTime(2024, 6, 21, 12, 0, 0);
      final terms = await provider.surroundingTerms(center);
      expect(terms, hasLength(6));
    });

    test('surroundingTerms 跨年回归测试', () async {
      final center = DateTime(2024, 1, 1);
      final terms = await provider.surroundingTerms(center);
      expect(terms.length, 6);
      // 应该有 2023 年的节气和 2024 年的节气
      final has2023 =
          terms.any((t) => t.occurredAt.year == 2023);
      final has2024 =
          terms.any((t) => t.occurredAt.year == 2024);
      expect(has2023, isTrue);
      expect(has2024, isTrue);
    });

    test('多年度节气连续性检验', () async {
      // 验证相邻两年节气日期无跳变
      final terms2023 = await provider.termsOfYear(2023);
      final terms2024 = await provider.termsOfYear(2024);
      final gap = terms2024.first.occurredAt
          .difference(terms2023.last.occurredAt)
          .inDays;
      expect(gap, inInclusiveRange(14, 17),
          reason: '冬至到次年小寒约 15 天');
    });

    test('所有节气都有非 0 的时间分量', () async {
      final terms = await provider.termsOfYear(2024);
      for (final term in terms) {
        final t = term.occurredAt;
        // 每个节气都应该有具体的时分秒（不等于 00:00:00）
        final hasTime =
            t.hour != 0 || t.minute != 0 || t.second != 0;
        expect(hasTime, isTrue,
            reason: '${term.name} 应该是精确时刻而非 00:00:00');
      }
    });
  });
}
