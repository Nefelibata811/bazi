import '../entities/solar_term_info.dart';

abstract class SolarTermProvider {
  Future<List<SolarTermInfo>> termsOfYear(int year);

  Future<List<SolarTermInfo>> surroundingTerms(DateTime moment);
}
