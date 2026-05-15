import '../entities/lunar_date.dart';

abstract class LunarSolarMapper {
  Future<DateTime?> solarFromLunar(LunarDate lunarDate);

  Future<LunarDate?> lunarFromSolar(DateTime solarDateTime);
}
