// 文件：神煞item
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/shensha_item.dart`。
//
class ShenshaItem {
  const ShenshaItem({
    required this.name,
    required this.target,
    required this.description,
    this.pillar,
  });

  final String name;
  final String target;
  final String description;
  final String? pillar;
}
