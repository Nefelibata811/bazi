import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/shensha_item.dart';

class ShenshaCard extends StatelessWidget {
  const ShenshaCard({
    super.key,
    required this.shenshaItems,
  });

  final List<ShenshaItem> shenshaItems;

  static const _auspicious = {
    '天乙贵人', '太极贵人', '福星贵人', '天德贵人', '月德贵人',
    '文昌', '学堂', '词馆',
    '禄神', '金舆', '国印贵人',
    '天厨贵人', '德秀贵人', '天赦日', '天医',
    '红鸾', '天喜', '将星',
    '三奇贵人', '十灵日', '六秀日',
  };

  static const _inauspicious = {
    '亡神', '劫煞', '灾煞', '羊刃', '飞刃',
    '孤辰', '寡宿', '魁罡',
    '十恶大败', '孤鸾煞', '阴错阳差',
    '丧门', '吊客', '披麻', '血刃',
    '红艳煞', '流霞',
    '四废日', '八专日', '九丑日',
    '天转', '地转',
    '天罗', '地网',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final grouped = <String, List<ShenshaItem>>{};
    for (final item in shenshaItems) {
      grouped.putIfAbsent(item.name, () => []).add(item);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('神煞', style: textTheme.titleLarge),
                const Spacer(),
                if (shenshaItems.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '共 ${shenshaItems.length} 项',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '日干、年支、日支所起，含贵人、桃花、驿马、空亡等',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            if (shenshaItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  '本命盘未命中常见神煞，或神煞力量较弱。',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.deepGray),
                ),
              )
            else
              ...grouped.entries.map((entry) {
                final color = _shenshaColor(entry.key);
                final targets =
                    entry.value.map((e) => e.target).toSet().join(' · ');
                final desc = entry.value.first.description;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.14)),
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
                            entry.key,
                            style: textTheme.titleSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CategoryChip(
                            label: _categoryLabel(entry.key),
                            color: color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        targets,
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: textTheme.bodySmall?.copyWith(height: 1.5),
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

  String _categoryLabel(String name) {
    if (_auspicious.contains(name)) return '吉';
    if (_inauspicious.contains(name)) return '凶';
    return '平';
  }

  Color _shenshaColor(String name) {
    if (_auspicious.contains(name)) return AppColors.gold;
    if (_inauspicious.contains(name)) return AppColors.cinnabar;
    switch (name) {
      case '驿马':
        return AppColors.water;
      case '桃花':
        return AppColors.fire;
      case '华盖':
        return AppColors.earth;
      case '空亡':
        return AppColors.deepGray;
      default:
        return AppColors.deepGray;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
            ),
      ),
    );
  }
}
