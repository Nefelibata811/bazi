import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/five_element_colors.dart';
import 'five_element_char.dart';
import '../../../../domain/entities/bazi_chart.dart';
import '../../../../domain/entities/pillar.dart';
import '../../../../domain/entities/shensha_item.dart';

/// 命宫、身宫、胎元、胎息（简版辅宫，避免与四柱大表重复）。
class ExtraPillarsCard extends StatelessWidget {
  /// 含内边距与五行字号，略留余量避免底部溢出。
  static const _tileHeight = 132.0;
  const ExtraPillarsCard({
    super.key,
    required this.chart,
    this.shenshaItems = const [],
  });

  final BaziChart chart;
  final List<ShenshaItem> shenshaItems;

  @override
  Widget build(BuildContext context) {
    final pillars = chart.extraPillars;
    if (pillars.isEmpty) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('辅命宫位', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '命宫、身宫、胎元、胎息为辅助参考，非上方本命四柱',
              style: textTheme.bodySmall?.copyWith(color: AppColors.deepGray),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final gap = 8.0;
                final tileWidth =
                    (constraints.maxWidth - gap * (pillars.length - 1)) /
                        pillars.length;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < pillars.length; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      SizedBox(
                        width: tileWidth,
                        height: _tileHeight,
                        child: _AuxPillarTile(
                          pillar: pillars[i],
                          shensha: shenshaItems
                              .where((s) => s.pillar == pillars[i].label)
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AuxPillarTile extends StatelessWidget {
  const _AuxPillarTile({
    required this.pillar,
    required this.shensha,
  });

  final Pillar pillar;
  final List<ShenshaItem> shensha;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final p = pillar;

    final shenshaText = shensha.isEmpty
        ? ''
        : shensha.map((e) => e.name).take(2).join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.rice.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 16,
            child: Center(
              child: Text(
                p.label,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.deepGray,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            height: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FiveElementChar(
                  text: p.stem,
                  color: FiveElementColors.byStem(p.stem),
                  large: false,
                ),
                const SizedBox(width: 4),
                FiveElementChar(
                  text: p.branch,
                  color: FiveElementColors.byBranch(p.branch),
                  large: false,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 16,
            child: Center(
              child: Text(
                p.tenGod,
                style: textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: Center(
              child: Text(
                p.naYin,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.deepGray,
                  fontSize: 10,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: Center(
              child: Text(
                shenshaText,
                style: textTheme.labelSmall?.copyWith(
                  color: shenshaText.isEmpty
                      ? Colors.transparent
                      : AppColors.gold,
                  fontSize: 10,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
