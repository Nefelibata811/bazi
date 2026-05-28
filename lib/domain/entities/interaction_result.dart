// 文件：刑冲合害结果
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/interaction_result.dart`。
//
enum InteractionType {
  stemCombine, // 天干五合
  stemClash, // 天干相冲
  branchCombine6, // 地支六合
  branchCombine3, // 地支三合
  branchCombineHalf, // 地支半合
  branchArch, // 地支拱合
  branchCombineMeet3, // 地支三会
  branchClash6, // 地支六冲
  branchHarm6, // 地支六害
  branchBreak, // 地支相破
  branchPunish, // 地支相刑
  branchPunishTriple, // 三刑会全
  branchSelfPunish, // 自刑
  stemBranchBothClash, // 天克地冲
  fuYin, // 伏吟
  fanYin, // 反吟
}

/// 类 `InteractionResult`：实现 Interaction Result 相关逻辑。
class InteractionResult {
  const InteractionResult({
    required this.type,
    required this.nodeA,
    required this.nodeB,
    this.combinedElement,
    this.description = '',
  });

  final InteractionType type;
  final String nodeA;
  final String nodeB;
  final String? combinedElement;
  final String description;

  String get typeLabel {
    switch (type) {
      case InteractionType.stemCombine:
        return '天干五合';
      case InteractionType.stemClash:
        return '天干相冲';
      case InteractionType.branchCombine6:
        return '地支六合';
      case InteractionType.branchCombine3:
        return '地支三合';
      case InteractionType.branchCombineHalf:
        return '地支半合';
      case InteractionType.branchArch:
        return '地支拱合';
      case InteractionType.branchCombineMeet3:
        return '地支三会';
      case InteractionType.branchClash6:
        return '地支六冲';
      case InteractionType.branchHarm6:
        return '地支六害';
      case InteractionType.branchBreak:
        return '地支相破';
      case InteractionType.branchPunish:
        return '地支相刑';
      case InteractionType.branchPunishTriple:
        return '三刑会全';
      case InteractionType.branchSelfPunish:
        return '自刑';
      case InteractionType.stemBranchBothClash:
        return '天克地冲';
      case InteractionType.fuYin:
        return '伏吟';
      case InteractionType.fanYin:
        return '反吟';
    }
  }
}
