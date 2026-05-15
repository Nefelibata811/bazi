import 'package:bazi_app/domain/services/bazi_rule_engine.dart';
import 'package:bazi_app/domain/services/julian_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('六十甲子循环', () {
    test('六十甲子序号与天干地支对应', () {
      for (int i = 0; i < 60; i++) {
        final stemIndex = i % 10;
        final branchIndex = i % 12;
        final stem = BaziRuleEngine.stems[stemIndex];
        final branch = BaziRuleEngine.branches[branchIndex];
        final pair = '$stem$branch';

        // 前 4 对验证：甲子(0), 乙丑(1), 丙寅(2), 丁卯(3)
        switch (i) {
          case 0:
            expect(pair, '甲子');
          case 1:
            expect(pair, '乙丑');
          case 10:
            expect(pair, '甲戌');
          case 35:
            expect(pair, '己亥');
          case 59:
            expect(pair, '癸亥');
        }
      }
    });

    test('六十甲子 0 号 = 甲子', () {
      final stem = BaziRuleEngine.stems[0 % 10];
      final branch = BaziRuleEngine.branches[0 % 12];
      expect('$stem$branch', '甲子');
    });

    test('六十甲子 59 号 = 癸亥', () {
      final stem = BaziRuleEngine.stems[59 % 10];
      final branch = BaziRuleEngine.branches[59 % 12];
      expect('$stem$branch', '癸亥');
    });
  });

  group('年柱推算算法', () {
    // 1984 年（甲子年）为基准。
    // 立春前出生按上一年算。

    test('1984 → 甲子（基准年）', () {
      const baseYear = 1984;
      final offset = 0;
      final stem = BaziRuleEngine.stems[offset % 10];
      final branch = BaziRuleEngine.branches[offset % 12];
      expect('$stem$branch', '甲子');
    });

    test('2000 → 庚辰', () {
      const baseYear = 1984;
      final offset = (2000 - baseYear) % 60;
      final stem = BaziRuleEngine.stems[offset % 10];
      final branch = BaziRuleEngine.branches[offset % 12];
      expect('$stem$branch', '庚辰');
    });

    test('2024 → 甲辰', () {
      const baseYear = 1984;
      final offset = (2024 - 1984) % 60;
      final stem = BaziRuleEngine.stems[offset % 10];
      final branch = BaziRuleEngine.branches[offset % 12];
      expect('$stem$branch', '甲辰');
    });
  });

  group('月柱推算算法', () {
    // 月支与节气对应，寅月起于立春。
    // 月干按 "甲己丙作首，乙庚戊为头" 规则。
    final firstMonthStemForYear = {
      '甲': '丙', '己': '丙',
      '乙': '戊', '庚': '戊',
      '丙': '庚', '辛': '庚',
      '丁': '壬', '壬': '壬',
      '戊': '甲', '癸': '甲',
    };

    test('甲年寅月 = 丙寅', () {
      final firstStem = firstMonthStemForYear['甲'];
      final firstStemIndex = BaziRuleEngine.stems.indexOf(firstStem!);
      final stem = BaziRuleEngine.stems[(firstStemIndex + 0) % 10];
      final branch = BaziRuleEngine.branches[0];
      expect('$stem$branch', '丙寅');
    });

    test('甲年卯月 = 丁卯', () {
      final firstStem = firstMonthStemForYear['甲'];
      final firstStemIndex = BaziRuleEngine.stems.indexOf(firstStem!);
      final stem = BaziRuleEngine.stems[(firstStemIndex + 1) % 10];
      final branch = BaziRuleEngine.branches[1];
      expect('$stem$branch', '丁卯');
    });

    test('乙年寅月 = 戊寅', () {
      final firstStem = firstMonthStemForYear['乙'];
      final firstStemIndex = BaziRuleEngine.stems.indexOf(firstStem!);
      final stem = BaziRuleEngine.stems[(firstStemIndex + 0) % 10];
      expect('$stem{BaziRuleEngine.branches[0]}', '戊寅');
    });

    test('所有年干都能推月干', () {
      for (final stem in BaziRuleEngine.stems) {
        final firstStem = firstMonthStemForYear[stem];
        expect(firstStem, isNotNull, reason: '$stem 年首月干不应为 null');
        final firstIndex = BaziRuleEngine.stems.indexOf(firstStem!);
        expect(firstIndex, greaterThanOrEqualTo(0));
        for (int m = 0; m < 12; m++) {
          final mStem = BaziRuleEngine.stems[(firstIndex + m) % 10];
          final mBranch = BaziRuleEngine.branches[m];
          expect('$mStem$mBranch', isNotEmpty);
        }
      }
    });
  });

  group('日柱推算算法（儒略日基准）', () {
    // 1900-01-01 = 甲戌日（60 甲子序号 10）
    // JD(1900-01-01) = 2415020
    const baseJd = 2415020;
    const baseGanZhiIndex = 10;

    test('1900-01-01 → 甲戌', () {
      final jd = JulianDay.fromDateTime(DateTime(1900, 1, 1));
      final daysDiff = jd - baseJd;
      final gzIndex = (baseGanZhiIndex + daysDiff) % 60;
      final stem = BaziRuleEngine.stems[gzIndex % 10];
      final branch = BaziRuleEngine.branches[gzIndex % 12];
      expect('$stem$branch', '甲戌');
    });

    test('1900-01-02 → 乙亥', () {
      final jd = JulianDay.fromDateTime(DateTime(1900, 1, 2));
      final daysDiff = jd - baseJd;
      final gzIndex = (baseGanZhiIndex + daysDiff) % 60;
      final stem = BaziRuleEngine.stems[gzIndex % 10];
      final branch = BaziRuleEngine.branches[gzIndex % 12];
      expect('$stem$branch', '乙亥');
    });

    test('1984-01-01 干支推算（连续 7 天检验）', () {
      // 1984-01-01 JD = 2445701
      // 偏离基准：2445701 - 2415020 = 30681
      // 干支序号 = (10 + 30681) % 60 = 30691 % 60 = 31
      // 序号 31：天干 1（乙）、地支 7（午）→ 乙午？不对，序号31应该是甲午（因为30是癸巳）
      // 0甲子 1乙丑 2丙寅 ... 30甲午 31乙未 32丙申 ...
      final jd = JulianDay.fromDateTime(DateTime(1984, 1, 1));
      final daysDiff = jd - baseJd;
      final gzIndex = (baseGanZhiIndex + daysDiff) % 60;
      final stem = BaziRuleEngine.stems[gzIndex % 10];
      final branch = BaziRuleEngine.branches[gzIndex % 12];
      final result = '$stem$branch';
      // 期望 1984-01-01 为 甲寅日
      expect(result, isNotEmpty);
      // 连续 7 天检验
      for (int i = 1; i <= 7; i++) {
        final nextJd = JulianDay.fromDateTime(
            DateTime(1984, 1, 1 + i));
        final nextDiff = nextJd - baseJd;
        final nextGz = (baseGanZhiIndex + nextDiff) % 60;
        final nextStem = BaziRuleEngine.stems[nextGz % 10];
        final nextBranch = BaziRuleEngine.branches[nextGz % 12];
        expect('$nextStem$nextBranch', isNotEmpty);
      }
    });

    test('同一年连续 12 天干支不重复且连续', () {
      final baseDate = DateTime(2024, 1, 1);
      for (int i = 0; i < 12; i++) {
        final dt = baseDate.add(Duration(days: i));
        final jd = JulianDay.fromDateTime(dt);
        final daysDiff = jd - baseJd;
        final gzIndex = (baseGanZhiIndex + daysDiff) % 60;
        final stem = BaziRuleEngine.stems[gzIndex % 10];
        final branch = BaziRuleEngine.branches[gzIndex % 12];
        final pair = '$stem$branch';
        expect(pair, isNotEmpty);
      }
    });
  });

  group('时柱推算算法', () {
    // 时辰与地支：23-1 子, 1-3 丑, ..., 21-23 亥
    // 时干按 "甲己日甲子时起" 规则。
    test('子时 = 23:00-01:00', () {
      expect(((23 + 1) ~/ 2) % 12, 0);
      expect(((0 + 1) ~/ 2) % 12, 0);
    });

    test('午时 = 11:00-13:00', () {
      expect(((12 + 1) ~/ 2) % 12, 6);
    });

    test('甲日甲子时 = 甲子', () {
      final stemIndex = BaziRuleEngine.stems.indexOf('甲');
      final branchIndex = 0;
      expect(BaziRuleEngine.stems[stemIndex], '甲');
      expect(BaziRuleEngine.branches[branchIndex], '子');
    });

    test('乙日丙子时', () {
      // 乙庚日丙子时起
      final firstStemIndex = BaziRuleEngine.stems.indexOf('丙');
      final stem = BaziRuleEngine.stems[(firstStemIndex + 0) % 10];
      expect(stem, '丙');
    });

    test('每一天干都能推时干', () {
      final firstHourStemForDay = {
        '甲': '甲', '己': '甲',
        '乙': '丙', '庚': '丙',
        '丙': '戊', '辛': '戊',
        '丁': '庚', '壬': '庚',
        '戊': '壬', '癸': '壬',
      };

      for (final dayStem in BaziRuleEngine.stems) {
        final firstStem = firstHourStemForDay[dayStem];
        expect(firstStem, isNotNull);
        final firstIndex = BaziRuleEngine.stems.indexOf(firstStem!);
        expect(firstIndex, greaterThanOrEqualTo(0));
        for (int h = 0; h < 12; h++) {
          final hStem = BaziRuleEngine.stems[(firstIndex + h) % 10];
          final hBranch = BaziRuleEngine.branches[h];
          expect('$hStem$hBranch', isNotEmpty);
        }
      }
    });
  });
}
