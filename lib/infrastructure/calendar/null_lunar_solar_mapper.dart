import '../../domain/entities/lunar_date.dart';
import '../../domain/services/lunar_solar_mapper.dart';

class NullLunarSolarMapper implements LunarSolarMapper {
  const NullLunarSolarMapper();

  @override
  Future<LunarDate?> lunarFromSolar(DateTime solarDateTime) async {
    return null;
  }

  @override
  Future<DateTime?> solarFromLunar(LunarDate lunarDate) async {
    return null;
  }
}
