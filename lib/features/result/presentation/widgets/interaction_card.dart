import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/interaction_result.dart';

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
              '原局四柱：合、冲、刑、害、破、拱、伏吟、反吟等',
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
                    ...entry.value.map((r) {
                      final detail = r.description.isNotEmpty
                          ? r.description
                          : '${r.nodeA} · ${r.nodeB}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('· ', style: textTheme.bodyMedium),
                            Expanded(
                              child: Text(
                                detail,
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
