enum InteractionType {
  stemCombine,  // 天干五合
  stemClash,    // 天干相冲
  branchCombine6,  // 地支六合
  branchCombine3,  // 地支三合
  branchCombineHalf, // 地支半合
  branchClash6,  // 地支六冲
  branchHarm6,   // 地支六害
  branchPunish,  // 地支相刑
}

class InteractionResult {
  const InteractionResult({
    required this.type,
    required this.nodeA,
    required this.nodeB,
    this.combinedElement,
    this.description = '',
  });

  final InteractionType type;
  final String nodeA; // e.g. "年支丑"
  final String nodeB; // e.g. "日支未"
  final String? combinedElement; // e.g. "土" for 子丑合土
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
      case InteractionType.branchClash6:
        return '地支六冲';
      case InteractionType.branchHarm6:
        return '地支六害';
      case InteractionType.branchPunish:
        return '地支相刑';
    }
  }
}
