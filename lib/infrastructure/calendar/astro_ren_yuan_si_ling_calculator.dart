// 文件：astro人元元司lingcalculator
//
// 历法算法：八字排盘核心计算。
// 路径：`lib/infrastructure/calendar/astro_ren_yuan_si_ling_calculator.dart`。
//
import '../../domain/entities/ren_yuan_si_ling.dart';
import '../../domain/entities/solar_term_info.dart';
import '../../domain/services/ren_yuan_si_ling_calculator.dart';
import '../../domain/services/solar_term_provider.dart';
import '../../domain/value_objects/si_ling_version.dart';
import 'si_ling_tables.dart';

/// 自节气时刻起算 24 小时为一日的人元司令。
class AstroRenYuanSiLingCalculator implements RenYuanSiLingCalculator {
  const AstroRenYuanSiLingCalculator({
    required SolarTermProvider solarTermProvider,
  }) : _solarTermProvider = solarTermProvider;

  final SolarTermProvider _solarTermProvider;

  @override
  Future<RenYuanSiLing?> calculate({
    required DateTime solarDateTime,
    required String monthBranch,
    SiLingVersion version = SiLingVersion.common,
  }) async {
    final terms = await _jieTermsAround(solarDateTime);
    final days = _daysSincePrevJie(solarDateTime, terms);
    if (days == null) return null;

    final segments = SiLingTables.tableFor(version)[monthBranch];
    if (segments == null) return null;

    var accumulated = 0.0;
    for (final seg in segments) {
      accumulated += seg.days;
      if (days < accumulated) {
        return RenYuanSiLing(
          stem: seg.stem,
          origin: seg.origin,
          daysSinceJie: days,
          monthBranch: monthBranch,
        );
      }
    }

    final last = segments.last;
    return RenYuanSiLing(
      stem: last.stem,
      origin: last.origin,
      daysSinceJie: days,
      monthBranch: monthBranch,
    );
  }

  Future<List<SolarTermInfo>> _jieTermsAround(DateTime moment) async {
    final prev = await _solarTermProvider.termsOfYear(moment.year - 1);
    final cur = await _solarTermProvider.termsOfYear(moment.year);
    final next = await _solarTermProvider.termsOfYear(moment.year + 1);
    return [...prev, ...cur, ...next]
        .where((t) => t.termMonth != null)
        .toList();
  }

  double? _daysSincePrevJie(
    DateTime moment,
    List<SolarTermInfo> jieTerms,
  ) {
    SolarTermInfo? prev;
    for (final t in jieTerms) {
      if (!t.occurredAt.isAfter(moment)) {
        prev = t;
      }
    }
    if (prev == null) return null;
    return moment.difference(prev.occurredAt).inSeconds / 86400.0;
  }
}
