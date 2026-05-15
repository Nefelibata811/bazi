import 'package:lunar/lunar.dart' hide Pillar;

import '../../../domain/entities/bazi_chart.dart';
import '../../../domain/entities/bazi_request.dart';
import '../../../domain/entities/calendar_snapshot.dart';
import '../../../domain/entities/flowing_year.dart';
import '../../../domain/entities/luck_cycle.dart';
import '../../../domain/entities/solar_term_info.dart';
import '../../../domain/services/bazi_rule_engine.dart';
import '../../../domain/services/luck_cycle_calculator.dart';
import '../../../domain/value_objects/calendar_type.dart';
import '../../../domain/value_objects/gender.dart';

class LunarLuckCycleCalculator implements LuckCycleCalculator {
  const LunarLuckCycleCalculator({
    required BaziRuleEngine ruleEngine,
  }) : _ruleEngine = ruleEngine;

  final BaziRuleEngine _ruleEngine;

  @override
  Future<List<LuckCycle>> calculate({
    required BaziRequest request,
    required CalendarSnapshot calendarSnapshot,
    required BaziChart chart,
    required List<SolarTermInfo> solarTerms,
  }) async {
    final EightChar ec;

    if (request.calendarType == CalendarType.solar) {
      final solar = Solar.fromYmdHms(
        request.solarDateTime.year,
        request.solarDateTime.month,
        request.solarDateTime.day,
        request.solarDateTime.hour,
        request.solarDateTime.minute,
        0,
      );
      ec = solar.getLunar().getEightChar();
    } else {
      final month =
          request.isLeapMonth ? -request.lunarMonth : request.lunarMonth;
      final lunar = Lunar.fromYmdHms(
        request.lunarYear,
        month,
        request.lunarDay,
        request.solarDateTime.hour,
        request.solarDateTime.minute,
        0,
      );
      ec = lunar.getEightChar();
    }

    final isMale = request.gender == Gender.male;
    final yun = ec.getYun(isMale ? 1 : 0);
    final daYunList = yun.getDaYun();
    final dayGan = ec.getDayGan();

    return daYunList.where((d) => d.getIndex() > 0).map((d) {
      final ganZhi = d.getGanZhi();
      final luckStem = ganZhi.substring(0, 1);
      final luckTenGod =
          _ruleEngine.tenGodFor(dayMasterStem: dayGan, targetStem: luckStem);

      final liuNian = d.getLiuNian();
      final flowingYears = liuNian.map((ln) {
        final lnGanZhi = ln.getGanZhi();
        final lnStem = lnGanZhi.substring(0, 1);
        final lnTenGod =
            _ruleEngine.tenGodFor(dayMasterStem: dayGan, targetStem: lnStem);
        return FlowingYear(
          year: ln.getYear(),
          ganZhi: lnGanZhi,
          tenGod: lnTenGod,
        );
      }).toList();

      return LuckCycle(
        index: d.getIndex(),
        ganZhi: ganZhi,
        tenGod: luckTenGod,
        startYear: d.getStartYear(),
        endYear: d.getEndYear(),
        startAge: d.getStartAge(),
        endAge: d.getEndAge(),
        flowingYears: flowingYears,
      );
    }).toList();
  }
}
