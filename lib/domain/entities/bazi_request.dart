// 文件：八字请求
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/bazi_request.dart`。
//
import '../value_objects/bazi_sect.dart';
import '../value_objects/calendar_type.dart';
import '../value_objects/gender.dart';

/// 类 `BaziRequest`：实现 Bazi Request 相关逻辑。
class BaziRequest {
  const BaziRequest({
    required this.calendarType,
    required this.gender,
    required this.solarDateTime,
    required this.lunarYear,
    required this.lunarMonth,
    required this.lunarDay,
    required this.isLeapMonth,
    this.baziSect = BaziSect.sameDay,
    this.personName,
    this.useTrueSolarTime = false,
    this.longitude,
    this.latitude,
    this.birthPlaceName,
    this.standardMeridian = 120.0,
  });

  final CalendarType calendarType;
  final Gender gender;
  /// 用户录入的钟表时间（北京时间 / 公历或农历对应的时刻）。
  final DateTime solarDateTime;
  final int lunarYear;
  final int lunarMonth;
  final int lunarDay;
  final bool isLeapMonth;
  final BaziSect baziSect;
  final String? personName;
  /// 是否按出生地经度换算真太阳时后排盘。
  final bool useTrueSolarTime;
  final double? longitude;
  final double? latitude;
  final String? birthPlaceName;
  /// 标准时区基准经线，中国默认东经 120°。
  final double standardMeridian;
}
