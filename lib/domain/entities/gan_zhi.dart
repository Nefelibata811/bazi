// 文件：干支
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/gan_zhi.dart`。
//
class GanZhi {
  const GanZhi({
    required this.stem,
    required this.branch,
  });

  final String stem;
  final String branch;

  String get name => '$stem$branch';
}
