// 文件：农历公历映射
//
// 路径：`lib/domain/services/lunar_solar_mapper.dart`。
//
import '../entities/lunar_date.dart';

abstract class LunarSolarMapper {
  Future<DateTime?> solarFromLunar(LunarDate lunarDate);

  Future<LunarDate?> lunarFromSolar(DateTime solarDateTime);
}
