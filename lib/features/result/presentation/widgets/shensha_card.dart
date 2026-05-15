import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/shensha_item.dart';

class ShenshaCard extends StatelessWidget {
  const ShenshaCard({
    super.key,
    required this.shenshaItems,
  });

  final List<ShenshaItem> shenshaItems;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (shenshaItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('神煞速览', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '年支日支所起，共 ${shenshaItems.length} 项',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: shenshaItems.map((item) {
                final color = _shenshaColor(item.name);

                return Container(
                  width: (MediaQuery.of(context).size.width - 88) / 2,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: color.withOpacity(0.14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.name,
                            style: textTheme.labelMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.target,
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: 'NotoSerifSC',
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: textTheme.labelSmall?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _shenshaColor(String name) {
    switch (name) {
      case '天乙贵人':
        return AppColors.gold;
      case '驿马':
        return AppColors.water;
      case '桃花':
        return AppColors.fire;
      case '华盖':
        return AppColors.earth;
      case '亡神':
        return AppColors.cinnabar;
      case '劫煞':
        return AppColors.cinnabar;
      case '空亡':
        return AppColors.deepGray;
      default:
        return AppColors.deepGray;
    }
  }
}
