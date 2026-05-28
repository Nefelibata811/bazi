// 文件：司lingversion
//
// 路径：`lib/domain/value_objects/si_ling_version.dart`。
//
enum SiLingVersion {
  /// 《三命通会》原文（5-5-20 等）
  sanMingTongHui('三命通会'),

  /// 网络流传 / 商业排盘常用
  common('常用版');

  const SiLingVersion(this.label);

  final String label;
}
