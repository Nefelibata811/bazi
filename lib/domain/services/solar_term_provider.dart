// 文件：公历节气提供者
//
// 路径：`lib/domain/services/solar_term_provider.dart`。
//
import '../entities/solar_term_info.dart';

abstract class SolarTermProvider {
  Future<List<SolarTermInfo>> termsOfYear(int year);

  Future<List<SolarTermInfo>> surroundingTerms(DateTime moment);
}
