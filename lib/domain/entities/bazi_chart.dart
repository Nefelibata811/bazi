import 'pillar.dart';

class BaziChart {
  const BaziChart({
    required this.dayMaster,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
  });

  final String dayMaster;
  final Pillar year;
  final Pillar month;
  final Pillar day;
  final Pillar hour;

  List<Pillar> get pillars => [year, month, day, hour];
}
