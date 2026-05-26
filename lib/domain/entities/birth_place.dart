/// 命主出生地点（用于真太阳时经度订正）。
class BirthPlace {
  const BirthPlace({
    required this.name,
    required this.longitude,
    this.latitude,
    this.province,
  });

  final String name;
  final double longitude;
  final double? latitude;
  final String? province;

  String get displayLabel =>
      province != null && province!.isNotEmpty ? '$province$name' : name;
}
