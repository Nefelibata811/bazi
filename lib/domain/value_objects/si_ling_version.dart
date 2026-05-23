/// 人元司令分野表版本。
enum SiLingVersion {
  /// 《三命通会》原文（5-5-20 等）
  sanMingTongHui('三命通会'),

  /// 网络流传 / 商业排盘常用
  common('常用版');

  const SiLingVersion(this.label);

  final String label;
}
