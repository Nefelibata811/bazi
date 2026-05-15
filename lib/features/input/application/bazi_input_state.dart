import '../../../domain/entities/bazi_chart.dart';
import '../../../domain/entities/bazi_report.dart';
import '../../../domain/value_objects/calendar_type.dart';
import '../../../domain/value_objects/gender.dart';

class BaziInputState {
  const BaziInputState({
    required this.calendarType,
    required this.gender,
    required this.solarDateTime,
    required this.lunarYear,
    required this.lunarMonth,
    required this.lunarDay,
    required this.isLeapMonth,
    required this.personName,
    required this.loading,
    this.chart,
    this.report,
  });

  factory BaziInputState.initial() {
    final now = DateTime.now();
    return BaziInputState(
      calendarType: CalendarType.solar,
      gender: Gender.male,
      solarDateTime: DateTime(now.year, now.month, now.day, 9, 30),
      lunarYear: now.year,
      lunarMonth: 1,
      lunarDay: 1,
      isLeapMonth: false,
      personName: '',
      loading: false,
    );
  }

  final CalendarType calendarType;
  final Gender gender;
  final DateTime solarDateTime;
  final int lunarYear;
  final int lunarMonth;
  final int lunarDay;
  final bool isLeapMonth;
  final String personName;
  final bool loading;
  final BaziChart? chart;
  final BaziReport? report;

  BaziInputState copyWith({
    CalendarType? calendarType,
    Gender? gender,
    DateTime? solarDateTime,
    int? lunarYear,
    int? lunarMonth,
    int? lunarDay,
    bool? isLeapMonth,
    String? personName,
    bool? loading,
    BaziChart? chart,
    BaziReport? report,
    bool clearChart = false,
  }) {
    return BaziInputState(
      calendarType: calendarType ?? this.calendarType,
      gender: gender ?? this.gender,
      solarDateTime: solarDateTime ?? this.solarDateTime,
      lunarYear: lunarYear ?? this.lunarYear,
      lunarMonth: lunarMonth ?? this.lunarMonth,
      lunarDay: lunarDay ?? this.lunarDay,
      isLeapMonth: isLeapMonth ?? this.isLeapMonth,
      personName: personName ?? this.personName,
      loading: loading ?? this.loading,
      chart: clearChart ? null : (chart ?? this.chart),
      report: clearChart ? null : (report ?? this.report),
    );
  }
}
