// 文件：出生地点
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/birth_place.dart`。
//
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
