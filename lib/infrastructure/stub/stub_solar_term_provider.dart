import '../../domain/entities/solar_term_info.dart';
import '../../domain/services/solar_term_provider.dart';

class StubSolarTermProvider implements SolarTermProvider {
  @override
  Future<List<SolarTermInfo>> termsOfYear(int year) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));

    return [
      SolarTermInfo(
        name: '惊蛰',
        occurredAt: DateTime(year, 3, 6),
        index: 4,
        termMonth: 1,
      ),
      SolarTermInfo(
        name: '春分',
        occurredAt: DateTime(year, 3, 21),
        index: 5,
      ),
    ];
  }

  @override
  Future<List<SolarTermInfo>> surroundingTerms(DateTime moment) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));

    return [
      SolarTermInfo(
        name: '惊蛰',
        occurredAt: DateTime(moment.year, moment.month, moment.day)
            .subtract(const Duration(days: 7)),
        index: 4,
        termMonth: 1,
      ),
      SolarTermInfo(
        name: '春分',
        occurredAt: DateTime(moment.year, moment.month, moment.day)
            .add(const Duration(days: 8)),
        index: 5,
      ),
    ];
  }
}
