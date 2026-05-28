// 文件：中国出生地点
//
// 路径：`lib/infrastructure/geo/china_birth_places.dart`。
//
import '../../domain/entities/birth_place.dart';
import 'china_birth_places_data.dart';

/// 全国省市区县经度（约 3200+ 条，来源：qwd/LocationList），供真太阳时订正。
class ChinaBirthPlaces {
  const ChinaBirthPlaces._();

  static const BirthPlace defaultPlace = BirthPlace(
    name: '北京市',
    province: '北京',
    longitude: 116.4074,
    latitude: 39.9042,
  );

  static const int _searchLimit = 80;

  /// 全部地点（省 / 地级市 / 区县）。
  static List<BirthPlace> get all => kChinaBirthPlacesData;

  /// 未输入关键词时展示的常用城市（省会 + 直辖市 + 计划单列市等）。
  static final List<BirthPlace> hotCities = () {
    const names = [
      '北京市',
      '上海市',
      '天津市',
      '重庆市',
      '广州市',
      '深圳市',
      '杭州市',
      '南京市',
      '武汉市',
      '成都市',
      '西安市',
      '郑州市',
      '长沙市',
      '沈阳市',
      '哈尔滨市',
      '济南市',
      '青岛市',
      '大连市',
      '厦门市',
      '苏州市',
      '无锡市',
      '宁波市',
      '福州市',
      '合肥市',
      '南昌市',
      '昆明市',
      '贵阳市',
      '兰州市',
      '乌鲁木齐市',
      '拉萨市',
      '呼和浩特市',
      '南宁市',
      '海口市',
      '石家庄市',
      '太原市',
      '长春市',
      '香港',
      '澳门',
      '台北市',
    ];
    final byName = {for (final p in kChinaBirthPlacesData) p.name: p};
    final list = <BirthPlace>[];
    for (final n in names) {
      final p = byName[n];
      if (p != null) list.add(p);
    }
    if (!list.contains(defaultPlace)) list.insert(0, defaultPlace);
    return list;
  }();

  static List<BirthPlace> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return List<BirthPlace>.from(hotCities);

    final lower = q.toLowerCase();
    final normalized = q.replaceAll('市', '').replaceAll('省', '');

    final matches = <BirthPlace>[];
    for (final p in kChinaBirthPlacesData) {
      if (matches.length >= _searchLimit) break;
      final name = p.name;
      final prov = p.province ?? '';
      if (name.contains(q) ||
          prov.contains(q) ||
          p.displayLabel.contains(q) ||
          name.replaceAll('市', '').contains(normalized) ||
          p.displayLabel.toLowerCase().contains(lower)) {
        matches.add(p);
      }
    }
    return matches;
  }

  static BirthPlace? findByName(String name) {
    final trimmed = name.trim();
    for (final p in kChinaBirthPlacesData) {
      if (p.name == trimmed || p.displayLabel == trimmed) return p;
    }
    final hits = search(trimmed);
    return hits.isNotEmpty ? hits.first : null;
  }
}
