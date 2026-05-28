// 文件：农历八字反查lookup
//
// 历法算法：八字排盘核心计算。
// 路径：`lib/infrastructure/calendar/lunar_bazi_reverse_lookup.dart`。
//
import 'package:lunar/lunar.dart';

import '../../domain/entities/bazi_reverse_candidate.dart';
import '../../domain/entities/bazi_reverse_query.dart';
import '../../domain/services/bazi_reverse_lookup.dart';
import '../../domain/value_objects/bazi_sect.dart';

/// 基于 `Solar.fromBaZi` 与逐日扫描的八字反查。
class LunarBaziReverseLookup implements BaziReverseLookup {
  const LunarBaziReverseLookup();

  static const _stems = '甲乙丙丁戊己庚辛壬癸';
  static const _branches = '子丑寅卯辰巳午未申酉戌亥';

  @override
  Future<List<BaziReverseCandidate>> search(BaziReverseQuery query) async {
    if (query.yearGanZhi.length != 2) {
      throw ArgumentError('年柱须为两字干支');
    }
    if (query.startYear > query.endYear) {
      throw ArgumentError('起始年不能晚于结束年');
    }

    if (query.isFull) {
      return _searchFull(query);
    }
    return _searchPartial(query);
  }

  List<BaziReverseCandidate> _searchFull(BaziReverseQuery query) {
    final solars = Solar.fromBaZi(
      query.yearGanZhi,
      query.monthGanZhi!,
      query.dayGanZhi!,
      query.timeGanZhi!,
      sect: query.baziSect.lunarSect,
      baseYear: query.startYear,
    );

    final results = <BaziReverseCandidate>[];
    for (final solar in solars) {
      if (solar.getYear() < query.startYear || solar.getYear() > query.endYear) {
        continue;
      }
      results.add(_candidateFromSolar(solar, query));
      if (results.length >= query.maxResults) break;
    }
    return results;
  }

  List<BaziReverseCandidate> _searchPartial(BaziReverseQuery query) {
    final results = <BaziReverseCandidate>[];
    final seen = <String>{};

    if (query.dayGanZhi != null &&
        query.monthGanZhi != null &&
        query.timeGanZhi == null) {
      for (var i = 0; i < 12; i++) {
        final branch = _branches[i];
        final dayStem = query.dayGanZhi!.substring(0, 1);
        final timeGz = '${_timeStemFor(dayStem, branch)}$branch';
        final partial = BaziReverseQuery(
          yearGanZhi: query.yearGanZhi,
          monthGanZhi: query.monthGanZhi,
          dayGanZhi: query.dayGanZhi,
          timeGanZhi: timeGz,
          startYear: query.startYear,
          endYear: query.endYear,
          gender: query.gender,
          baziSect: query.baziSect,
          maxResults: query.maxResults,
        );
        for (final c in _searchFull(partial)) {
          final key = c.dateLabel;
          if (seen.add(key)) {
            results.add(c);
            if (results.length >= query.maxResults) return results;
          }
        }
      }
      return results;
    }

    for (var y = query.endYear; y >= query.startYear; y--) {
      for (var m = 1; m <= 12; m++) {
        final days = DateTime(y, m + 1, 0).day;
        for (var d = 1; d <= days; d++) {
            final solar = Solar.fromYmdHms(y, m, d, 12, 0, 0);
            final lunar = solar.getLunar();
            final ec = lunar.getEightChar();
            ec.setSect(query.baziSect.lunarSect);

            final yearGz = lunar.getYearInGanZhiExact();
            if (yearGz != query.yearGanZhi) continue;

            if (query.monthGanZhi != null &&
                lunar.getMonthInGanZhiExact() != query.monthGanZhi) {
              continue;
            }

            final dayGz = query.baziSect == BaziSect.sameDay
                ? lunar.getDayInGanZhiExact2()
                : lunar.getDayInGanZhiExact();
            if (query.dayGanZhi != null && dayGz != query.dayGanZhi) {
              continue;
            }

            if (query.timeGanZhi != null &&
                lunar.getTimeInGanZhi() != query.timeGanZhi) {
              continue;
            }

            final candidate = BaziReverseCandidate(
              solarDateTime: DateTime(
                solar.getYear(),
                solar.getMonth(),
                solar.getDay(),
                solar.getHour(),
                solar.getMinute(),
              ),
              yearGanZhi: yearGz,
              monthGanZhi: lunar.getMonthInGanZhiExact(),
              dayGanZhi: dayGz,
              timeGanZhi: lunar.getTimeInGanZhi(),
              isLateZi: solar.getHour() == 23,
              gender: query.gender,
              baziSect: query.baziSect,
            );
            final key = candidate.dateLabel;
            if (seen.add(key)) {
              results.add(candidate);
              if (results.length >= query.maxResults) {
                return results;
              }
            }
        }
      }
    }

    return results;
  }

  BaziReverseCandidate _candidateFromSolar(
    Solar solar,
    BaziReverseQuery query,
  ) {
    final lunar = solar.getLunar();
    final ec = lunar.getEightChar();
    ec.setSect(query.baziSect.lunarSect);
    final dayGz = query.baziSect == BaziSect.sameDay
        ? lunar.getDayInGanZhiExact2()
        : lunar.getDayInGanZhiExact();

    return BaziReverseCandidate(
      solarDateTime: DateTime(
        solar.getYear(),
        solar.getMonth(),
        solar.getDay(),
        solar.getHour(),
        solar.getMinute(),
      ),
      yearGanZhi: lunar.getYearInGanZhiExact(),
      monthGanZhi: lunar.getMonthInGanZhiExact(),
      dayGanZhi: dayGz,
      timeGanZhi: lunar.getTimeInGanZhi(),
      isLateZi: solar.getHour() == 23,
      gender: query.gender,
      baziSect: query.baziSect,
    );
  }

  /// 五鼠遁：由日干、时支推时干。
  static String _timeStemFor(String dayStem, String branch) {
    const startByDay = {
      '甲': 0,
      '己': 0,
      '乙': 2,
      '庚': 2,
      '丙': 4,
      '辛': 4,
      '丁': 6,
      '壬': 6,
      '戊': 8,
      '癸': 8,
    };
    final start = startByDay[dayStem] ?? 0;
    final branchIdx = _branches.indexOf(branch);
    return _stems[(start + branchIdx) % 10];
  }
}
