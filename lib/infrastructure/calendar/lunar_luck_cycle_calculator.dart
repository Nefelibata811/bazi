import 'package:lunar/lunar.dart';



import '../../domain/entities/bazi_chart.dart';

import '../../domain/entities/bazi_request.dart';

import '../../domain/entities/calendar_snapshot.dart';

import '../../domain/entities/flowing_month.dart';
import '../../domain/entities/flowing_year.dart';

import '../../domain/entities/luck_cycle.dart';

import '../../domain/entities/solar_term_info.dart';

import '../../domain/services/bazi_rule_engine.dart';

import '../../domain/services/luck_cycle_calculator.dart';

import '../../domain/value_objects/gender.dart';

import 'lunar_eight_char_factory.dart';



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

    final ec = LunarEightCharFactory.eightCharFromRequest(request);

    final isMale = request.gender == Gender.male;

    final yun = ec.getYun(isMale ? 1 : 0, request.baziSect.lunarSect);

    final daYunList = yun.getDaYun();

    final dayGan = ec.getDayGan();



    return daYunList.map((d) {

      if (d.getIndex() == 0) {

        return _mapPreStartCycle(d, dayGan);

      }

      return _mapDaYunCycle(d, dayGan);

    }).toList();

  }



  LuckCycle _mapPreStartCycle(DaYun d, String dayGan) {

    final liuNian = d.getLiuNian();

    final xiaoYuns = d.getXiaoYun();

    final flowingYears = <FlowingYear>[];

    for (var i = 0; i < liuNian.length; i++) {

      final ln = liuNian[i];

      final lnGanZhi = ln.getGanZhi();

      final xiaoYunGanZhi =

          i < xiaoYuns.length ? xiaoYuns[i].getGanZhi() : null;

      flowingYears.add(
        _mapFlowingYear(ln, dayGan, xiaoYunGanZhi: xiaoYunGanZhi),
      );
    }



    return LuckCycle(

      index: 0,

      ganZhi: '起运前',

      tenGod: '小运',

      startYear: d.getStartYear(),

      endYear: d.getEndYear(),

      startAge: d.getStartAge(),

      endAge: d.getEndAge(),

      flowingYears: flowingYears,

      isPreStart: true,

    );

  }



  LuckCycle _mapDaYunCycle(DaYun d, String dayGan) {

    final ganZhi = d.getGanZhi();

    final luckStem = ganZhi.substring(0, 1);

    final luckTenGod =

        _ruleEngine.tenGodFor(dayMasterStem: dayGan, targetStem: luckStem);



    final flowingYears =
        d.getLiuNian().map((ln) => _mapFlowingYear(ln, dayGan)).toList();



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

  }

  FlowingYear _mapFlowingYear(
    LiuNian ln,
    String dayGan, {
    String? xiaoYunGanZhi,
  }) {
    final lnGanZhi = ln.getGanZhi();
    final lnStem = lnGanZhi.substring(0, 1);
    final months = ln.getLiuYue().map((ly) {
      final gz = ly.getGanZhi();
      final stem = gz.substring(0, 1);
      return FlowingMonth(
        index: ly.getIndex() + 1,
        monthName: ly.getMonthInChinese(),
        ganZhi: gz,
        tenGod: _ruleEngine.tenGodFor(
          dayMasterStem: dayGan,
          targetStem: stem,
        ),
      );
    }).toList();

    return FlowingYear(
      year: ln.getYear(),
      ganZhi: lnGanZhi,
      tenGod: _ruleEngine.tenGodFor(dayMasterStem: dayGan, targetStem: lnStem),
      xiaoYunGanZhi: xiaoYunGanZhi,
      flowingMonths: months,
    );
  }
}

