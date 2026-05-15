import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bazi_request.dart';
import '../../../domain/entities/bazi_report.dart';
import '../../../domain/services/bazi_calculator.dart';
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
import '../../../domain/value_objects/calendar_type.dart';
import '../../../domain/value_objects/gender.dart';
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
  return RuleShenshaCalculator(
    ruleEngine: ref.watch(baziRuleEngineProvider),
  );
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

final buildBaziReportUseCaseProvider = Provider<BuildBaziReportUseCase>((ref) {
  return BuildBaziReportUseCase(
    calendarConverter: ref.watch(calendarConverterProvider),
    solarTermProvider: ref.watch(solarTermProvider),
    luckCycleCalculator: ref.watch(luckCycleCalculatorProvider),
    buildChartUseCase: ref.watch(buildBaziChartUseCaseProvider),
    analyzeBaziUseCase: ref.watch(analyzeBaziUseCaseProvider),
    baziCalculator: ref.watch(baziCalculatorProvider),
  );
});

final baziInputControllerProvider =
    StateNotifierProvider<BaziInputController, BaziInputState>((ref) {
  return BaziInputController(ref.watch(buildBaziReportUseCaseProvider));
});

class BaziInputController extends StateNotifier<BaziInputState> {
  BaziInputController(this._buildBaziReportUseCase)
      : super(BaziInputState.initial());

  final BuildBaziReportUseCase _buildBaziReportUseCase;

  void setCalendarType(CalendarType type) {
    state = state.copyWith(calendarType: type, clearChart: true);
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
  }

  void setSolarMinute(int minute) {
    final dt = state.solarDateTime;
    state = state.copyWith(
      solarDateTime: DateTime(dt.year, dt.month, dt.day, dt.hour, minute),
      clearChart: true,
    );
  }

  int _lastDayOf(int year, int month) => DateTime(year, month + 1, 0).day;

  void setLunarYear(int year) {
    state = state.copyWith(lunarYear: year, clearChart: true);
  }

  void setLunarMonth(int month) {
    state = state.copyWith(lunarMonth: month, clearChart: true);
  }

  void setLunarDay(int day) {
    state = state.copyWith(lunarDay: day, clearChart: true);
  }

  void setLeapMonth(bool value) {
    state = state.copyWith(isLeapMonth: value, clearChart: true);
  }

  Future<void> submit() async {
    state = state.copyWith(loading: true);

    final request = BaziRequest(
      calendarType: state.calendarType,
      gender: state.gender,
      solarDateTime: state.solarDateTime,
      lunarYear: state.lunarYear,
      lunarMonth: state.lunarMonth,
      lunarDay: state.lunarDay,
      isLeapMonth: state.isLeapMonth,
      personName: state.personName.isEmpty ? null : state.personName,
    );

    final report = await _buildBaziReportUseCase(request);
    if (mounted) {
      state = state.copyWith(loading: false, chart: report.chart, report: report);
    }
  }

  Future<void> loadFromSavedRequest(BaziRequest request) async {
    state = state.copyWith(
      personName: request.personName ?? state.personName,
      loading: true,
    );
    final report = await _buildBaziReportUseCase(request);
    if (mounted) {
      state = state.copyWith(
          loading: false, chart: report.chart, report: report);
    }
  }
}
