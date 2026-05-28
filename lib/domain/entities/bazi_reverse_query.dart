// 文件：八字反查query
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/bazi_reverse_query.dart`。
//
import '../value_objects/bazi_sect.dart';
import '../value_objects/gender.dart';

/// 八字反查条件（独立于正向 [BaziRequest]）。
class BaziReverseQuery {
  const BaziReverseQuery({
    required this.yearGanZhi,
    this.monthGanZhi,
    this.dayGanZhi,
    this.timeGanZhi,
    this.startYear = 1950,
    this.endYear = 2030,
    this.gender = Gender.male,
    this.baziSect = BaziSect.sameDay,
    this.maxResults = 50,
  });

  final String yearGanZhi;
  final String? monthGanZhi;
  final String? dayGanZhi;
  final String? timeGanZhi;
  final int startYear;
  final int endYear;
  final Gender gender;
  final BaziSect baziSect;
  final int maxResults;

  bool get isFull =>
      monthGanZhi != null && dayGanZhi != null && timeGanZhi != null;
}
