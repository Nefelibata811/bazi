import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/useful_god_result.dart';

class UsefulGodCard extends StatelessWidget {
  const UsefulGodCard({
    super.key,
    required this.usefulGod,
  });

  final UsefulGodResult usefulGod;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('五行与用神', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatusBlock(
                    label: '日主旺衰',
                    value: usefulGod.dayMasterStrength,
                    color: AppColors.earth,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusBlock(
                    label: '用神',
                    value: usefulGod.usefulGod,
                    color: AppColors.cinnabar,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatusBlock(
                    label: '喜神',
                    value: usefulGod.supportiveGod,
                    color: AppColors.wood,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusBlock(
                    label: '忌神',
                    value: usefulGod.avoidGod,
                    color: AppColors.deepGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                usefulGod.summary,
                style: textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
