// 文件：生辰录入 — 状态控制器
//
// 管理公历/农历、出生时刻、出生地、真太阳时与排盘 sect。
// 农历变更时同步公历；触发排盘并缓存 BaziReport。
//
// 排盘录入状态：日历/性别/姓名/时辰等表单，提交时调用 BuildBaziReportUseCase。
// Riverpod 注册见文件末尾 baziInputControllerProvider。
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bazi_request.dart';
import '../../../domain/entities/birth_place.dart';
import '../../../domain/services/bazi_calculator.dart';
import '../../../domain/services/ren_yuan_si_ling_calculator.dart';
import '../../../domain/services/bazi_rule_engine.dart';
import '../../../domain/services/calendar_converter.dart';
import '../../../domain/services/luck_cycle_calculator.dart';
import '../../../domain/services/pattern_analyzer.dart';
import '../../../domain/services/shensha_calculator.dart';
import '../../../domain/services/solar_term_provider.dart';
import '../../../domain/services/useful_god_analyzer.dart';
import '../../../domain/usecases/analyze_bazi_usecase.dart';
import '../../../domain/usecases/build_bazi_chart_usecase.dart';
import '../../../domain/usecases/build_bazi_report_usecase.dart';
import '../../../domain/value_objects/bazi_sect.dart';
import '../../../domain/value_objects/calendar_type.dart';
import '../../../domain/value_objects/gender.dart';
import '../../../infrastructure/calendar/chart_datetime_resolver.dart';
import '../../../domain/entities/bazi_reverse_candidate.dart';
import '../../../infrastructure/calendar/astro_ren_yuan_si_ling_calculator.dart';
import '../../../infrastructure/calendar/astro_solar_term_provider.dart';
import '../../../infrastructure/calendar/lunar_bazi_calculator.dart';
import '../../../infrastructure/calendar/lunar_calendar_converter.dart';
import '../../../infrastructure/calendar/lunar_luck_cycle_calculator.dart';
import '../../../infrastructure/calendar/rule_pattern_analyzer.dart';
import '../../../infrastructure/calendar/rule_shensha_calculator.dart';
import '../../../infrastructure/calendar/rule_useful_god_analyzer.dart';
import 'bazi_input_state.dart';

final baziRuleEngineProvider = Provider<BaziRuleEngine>((ref) {
  return BaziRuleEngine();
});

final calendarConverterProvider = Provider<CalendarConverter>((ref) {
  return const LunarCalendarConverter();
});

final solarTermProvider = Provider<SolarTermProvider>((ref) {
  return const AstroSolarTermProvider();
});

final baziCalculatorProvider = Provider<BaziCalculator>((ref) {
  return LunarBaziCalculator(
    ruleEngine: ref.watch(baziRuleEngineProvider),
  );
});

final luckCycleCalculatorProvider = Provider<LuckCycleCalculator>((ref) {
  return LunarLuckCycleCalculator(
    ruleEngine: ref.watch(baziRuleEngineProvider),
  );
});

final patternAnalyzerProvider = Provider<PatternAnalyzer>((ref) {
  return RulePatternAnalyzer(
    ruleEngine: ref.watch(baziRuleEngineProvider),
  );
});

final shenshaCalculatorProvider = Provider<ShenshaCalculator>((ref) {
  return const RuleShenshaCalculator();
});

final usefulGodAnalyzerProvider = Provider<UsefulGodAnalyzer>((ref) {
  return RuleUsefulGodAnalyzer(
    ruleEngine: ref.watch(baziRuleEngineProvider),
  );
});

final buildBaziChartUseCaseProvider = Provider<BuildBaziChartUseCase>((ref) {
  return BuildBaziChartUseCase(ref.watch(baziCalculatorProvider));
});

final analyzeBaziUseCaseProvider = Provider<AnalyzeBaziUseCase>((ref) {
  return AnalyzeBaziUseCase(
    patternAnalyzer: ref.watch(patternAnalyzerProvider),
    shenshaCalculator: ref.watch(shenshaCalculatorProvider),
    usefulGodAnalyzer: ref.watch(usefulGodAnalyzerProvider),
  );
});

final renYuanSiLingCalculatorProvider = Provider<RenYuanSiLingCalculator>((ref) {
  return AstroRenYuanSiLingCalculator(
    solarTermProvider: ref.watch(solarTermProvider),
  );
});

final buildBaziReportUseCaseProvider = Provider<BuildBaziReportUseCase>((ref) {
  return BuildBaziReportUseCase(
    calendarConverter: ref.watch(calendarConverterProvider),
    solarTermProvider: ref.watch(solarTermProvider),
    luckCycleCalculator: ref.watch(luckCycleCalculatorProvider),
    buildChartUseCase: ref.watch(buildBaziChartUseCaseProvider),
    analyzeBaziUseCase: ref.watch(analyzeBaziUseCaseProvider),
    baziCalculator: ref.watch(baziCalculatorProvider),
    renYuanSiLingCalculator: ref.watch(renYuanSiLingCalculatorProvider),
  );
});

final baziInputControllerProvider =
    StateNotifierProvider<BaziInputController, BaziInputState>((ref) {
  return BaziInputController(ref.watch(buildBaziReportUseCaseProvider));
});

/// 类 `BaziInputController`：实现 Bazi Input Controller 相关逻辑。
class BaziInputController extends StateNotifier<BaziInputState> {
  BaziInputController(this._buildBaziReportUseCase)
      : super(BaziInputState.initial());

  final BuildBaziReportUseCase _buildBaziReportUseCase;

  void setCalendarType(CalendarType type) {
    state = state.copyWith(calendarType: type, clearChart: true);
    if (type == CalendarType.lunar) {
      _syncSolarFromLunar();
    }
  }

  void setGender(Gender gender) {
    state = state.copyWith(gender: gender, clearChart: true);
  }

  void setPersonName(String name) {
    state = state.copyWith(personName: name, clearChart: true);
  }

  void setSolarYear(int year) {
    final dt = state.solarDateTime;
    final lastDay = _lastDayOf(year, dt.month);
    final day = dt.day > lastDay ? lastDay : dt.day;
    state = state.copyWith(
      solarDateTime: DateTime(year, dt.month, day, dt.hour, dt.minute),
      clearChart: true,
    );
  }

  void setSolarMonth(int month) {
    final dt = state.solarDateTime;
    final lastDay = _lastDayOf(dt.year, month);
    final day = dt.day > lastDay ? lastDay : dt.day;
    state = state.copyWith(
      solarDateTime: DateTime(dt.year, month, day, dt.hour, dt.minute),
      clearChart: true,
    );
  }

  void setSolarDay(int day) {
    final dt = state.solarDateTime;
    state = state.copyWith(
      solarDateTime: DateTime(dt.year, dt.month, day, dt.hour, dt.minute),
      clearChart: true,
    );
  }

  void setSolarHour(int hour) {
    final dt = state.solarDateTime;
    state = state.copyWith(
      solarDateTime: DateTime(dt.year, dt.month, dt.day, hour, dt.minute),
      clearChart: true,
    );
    if (state.calendarType == CalendarType.lunar) {
      _syncSolarFromLunar();
    }
  }

  void setSolarMinute(int minute) {
    final dt = state.solarDateTime;
    state = state.copyWith(
      solarDateTime: DateTime(dt.year, dt.month, dt.day, dt.hour, minute),
      clearChart: true,
    );
    if (state.calendarType == CalendarType.lunar) {
      _syncSolarFromLunar();
    }
  }

  int _lastDayOf(int year, int month) => DateTime(year, month + 1, 0).day;

  void setLunarYear(int year) {
    state = state.copyWith(lunarYear: year, clearChart: true);
    _syncSolarFromLunar();
  }

  void setLunarMonth(int month) {
    state = state.copyWith(lunarMonth: month, clearChart: true);
    _syncSolarFromLunar();
  }

  void setLunarDay(int day) {
    state = state.copyWith(lunarDay: day, clearChart: true);
    _syncSolarFromLunar();
  }

  void setLeapMonth(bool value) {
    state = state.copyWith(isLeapMonth: value, clearChart: true);
    _syncSolarFromLunar();
  }

  void _syncSolarFromLunar() {
    if (state.calendarType != CalendarType.lunar) return;
    final request = BaziRequest(
      calendarType: state.calendarType,
      gender: state.gender,
      solarDateTime: state.solarDateTime,
      lunarYear: state.lunarYear,
      lunarMonth: state.lunarMonth,
      lunarDay: state.lunarDay,
      isLeapMonth: state.isLeapMonth,
      baziSect: state.baziSect,
      useTrueSolarTime: state.useTrueSolarTime,
      longitude: state.longitude,
      standardMeridian: state.standardMeridian,
    );
    final clock = ChartDateTimeResolver.clockLocal(request);
    state = state.copyWith(solarDateTime: clock, clearChart: true);
  }

  void setBaziSect(BaziSect sect) {
    state = state.copyWith(baziSect: sect, clearChart: true);
  }

  void setUseTrueSolarTime(bool value) {
    state = state.copyWith(useTrueSolarTime: value, clearChart: true);
  }

  void setBirthPlace(BirthPlace place) {
    state = state.copyWith(
      birthPlaceName: place.displayLabel,
      longitude: place.longitude,
      latitude: place.latitude,
      clearChart: true,
    );
  }

  void setManualLongitude(double longitude) {
    state = state.copyWith(
      longitude: longitude,
      birthPlaceName: '自定义经度 ${longitude.toStringAsFixed(2)}°E',
      latitude: null,
      clearChart: true,
    );
  }

  Future<void> submit() async {
    if (state.calendarType == CalendarType.lunar) {
      _syncSolarFromLunar();
    }
    state = state.copyWith(loading: true);

    final request = BaziRequest(
      calendarType: state.calendarType,
      gender: state.gender,
      solarDateTime: state.solarDateTime,
      lunarYear: state.lunarYear,
      lunarMonth: state.lunarMonth,
      lunarDay: state.lunarDay,
      isLeapMonth: state.isLeapMonth,
      baziSect: state.baziSect,
      personName: state.personName.isEmpty ? null : state.personName,
      useTrueSolarTime: state.useTrueSolarTime,
      longitude: state.longitude,
      latitude: state.latitude,
      birthPlaceName: state.birthPlaceName,
      standardMeridian: state.standardMeridian,
    );

    final report = await _buildBaziReportUseCase(request);
    if (mounted) {
      state = state.copyWith(loading: false, chart: report.chart, report: report);
    }
  }

  Future<void> applyFromReverseCandidate(BaziReverseCandidate candidate) async {
    state = state.copyWith(
      calendarType: CalendarType.solar,
      gender: candidate.gender,
      solarDateTime: candidate.solarDateTime,
      baziSect: candidate.baziSect,
      loading: true,
      clearChart: true,
    );
    final request = BaziRequest(
      calendarType: CalendarType.solar,
      gender: candidate.gender,
      solarDateTime: candidate.solarDateTime,
      lunarYear: candidate.solarDateTime.year,
      lunarMonth: candidate.solarDateTime.month,
      lunarDay: candidate.solarDateTime.day,
      isLeapMonth: false,
      baziSect: candidate.baziSect,
      personName: state.personName.isEmpty ? null : state.personName,
    );
    final report = await _buildBaziReportUseCase(request);
    if (mounted) {
      state = state.copyWith(
        loading: false,
        chart: report.chart,
        report: report,
      );
    }
  }

  /// 清除内存中的排盘结果（删除命盘后避免 AI Tab 自动写回云端）。
  void clearCachedChart() {
    if (state.report == null && state.chart == null) return;
    state = state.copyWith(clearChart: true);
  }

  Future<void> loadFromSavedRequest(BaziRequest request) async {
    var resolved = request;
    if (request.calendarType == CalendarType.lunar) {
      final clock = ChartDateTimeResolver.clockLocal(request);
      resolved = BaziRequest(
        calendarType: request.calendarType,
        gender: request.gender,
        solarDateTime: clock,
        lunarYear: request.lunarYear,
        lunarMonth: request.lunarMonth,
        lunarDay: request.lunarDay,
        isLeapMonth: request.isLeapMonth,
        baziSect: request.baziSect,
        personName: request.personName,
        useTrueSolarTime: request.useTrueSolarTime,
        longitude: request.longitude,
        latitude: request.latitude,
        birthPlaceName: request.birthPlaceName,
        standardMeridian: request.standardMeridian,
      );
    }
    state = state.copyWith(
      calendarType: resolved.calendarType,
      gender: resolved.gender,
      solarDateTime: resolved.solarDateTime,
      lunarYear: resolved.lunarYear,
      lunarMonth: resolved.lunarMonth,
      lunarDay: resolved.lunarDay,
      isLeapMonth: resolved.isLeapMonth,
      baziSect: resolved.baziSect,
      personName: resolved.personName ?? state.personName,
      useTrueSolarTime: resolved.useTrueSolarTime,
      longitude: resolved.longitude,
      latitude: resolved.latitude,
      birthPlaceName: resolved.birthPlaceName,
      standardMeridian: resolved.standardMeridian,
      loading: true,
    );
    final report = await _buildBaziReportUseCase(resolved);
    if (mounted) {
      state = state.copyWith(
          loading: false, chart: report.chart, report: report);
    }
  }
}
