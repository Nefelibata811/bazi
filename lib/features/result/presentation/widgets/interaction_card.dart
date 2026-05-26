import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/interaction_result.dart';

/// 将「关系说明（柱位证明）」拆成摘要与括号内证明。
({String summary, String? proof}) parseInteractionDescription(String description) {
  final match = RegExp(r'^(.+?)（([^）]+)）$').firstMatch(description.trim());
  if (match != null) {
    return (summary: match.group(1)!, proof: match.group(2)!);
  }
  return (summary: description, proof: null);
}

class InteractionCard extends StatelessWidget {
  const InteractionCard({
    super.key,
    required this.interactions,
  });

  final List<InteractionResult> interactions;

  static Color _accentFor(InteractionType type) {
    switch (type) {
      case InteractionType.stemCombine:
      case InteractionType.branchCombine6:
      case InteractionType.branchCombine3:
      case InteractionType.branchCombineHalf:
      case InteractionType.branchArch:
      case InteractionType.branchCombineMeet3:
        return AppColors.water;
      case InteractionType.stemClash:
      case InteractionType.branchClash6:
      case InteractionType.branchHarm6:
      case InteractionType.branchBreak:
      case InteractionType.branchPunish:
      case InteractionType.branchPunishTriple:
      case InteractionType.branchSelfPunish:
      case InteractionType.stemBranchBothClash:
      case InteractionType.fanYin:
        return AppColors.cinnabar;
      case InteractionType.fuYin:
        return AppColors.gold;
    }
  }

  static const _displayOrder = [
    InteractionType.stemCombine,
    InteractionType.stemClash,
    InteractionType.branchCombine6,
    InteractionType.branchCombine3,
    InteractionType.branchCombineMeet3,
    InteractionType.branchCombineHalf,
    InteractionType.branchArch,
    InteractionType.branchClash6,
    InteractionType.stemBranchBothClash,
    InteractionType.fanYin,
    InteractionType.branchHarm6,
    InteractionType.branchBreak,
    InteractionType.branchPunish,
    InteractionType.branchPunishTriple,
    InteractionType.branchSelfPunish,
    InteractionType.fuYin,
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (interactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final grouped = <InteractionType, List<InteractionResult>>{};
    for (final item in interactions) {
      grouped.putIfAbsent(item.type, () => []).add(item);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('干支关系', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '原局四柱：合、冲、刑、害、破、拱、伏吟、反吟等 · 加粗条目可点击查看柱位',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ..._displayOrder.where(grouped.containsKey).map((type) {
              final entry = MapEntry(type, grouped[type]!);
              final color = _accentFor(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.value.first.typeLabel,
                      style: textTheme.labelMedium?.copyWith(color: color),
                    ),
                    const SizedBox(height: 8),
                    ...entry.value.map(
                      (r) => _InteractionLine(
                        result: r,
                        color: color,
                        onTap: () => _showInteractionDetail(context, r, color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _InteractionLine extends StatelessWidget {
  const _InteractionLine({
    required this.result,
    required this.color,
    required this.onTap,
  });

  final InteractionResult result;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final parsed = parseInteractionDescription(
      result.description.isNotEmpty
          ? result.description
          : '${result.nodeA} · ${result.nodeB}',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('· ', style: textTheme.bodyMedium),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Text(
                parsed.summary,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showInteractionDetail(
  BuildContext context,
  InteractionResult result,
  Color color,
) {
  final parsed = parseInteractionDescription(
    result.description.isNotEmpty
        ? result.description
        : '${result.nodeA} · ${result.nodeB}',
  );

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result.typeLabel,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parsed.summary,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
          ),
          if (parsed.proof != null) ...[
            const SizedBox(height: 12),
            Text(
              '柱位',
              style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                    color: AppColors.deepGray,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              parsed.proof!,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ] else if (result.nodeA.isNotEmpty || result.nodeB.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '柱位',
              style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                    color: AppColors.deepGray,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '${result.nodeA} · ${result.nodeB}',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ],
          if (result.combinedElement != null &&
              result.combinedElement!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '合化五行：${result.combinedElement}',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}
