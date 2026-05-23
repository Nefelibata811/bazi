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
        return AppColors.water;
      case InteractionType.stemClash:
      case InteractionType.branchClash6:
      case InteractionType.branchHarm6:
      case InteractionType.branchPunish:
        return AppColors.cinnabar;
    }
  }

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
            Text('刑冲合害', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '原局四柱天干地支互动关系',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ...grouped.entries.map((entry) {
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
