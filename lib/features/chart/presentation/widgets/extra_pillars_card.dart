import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/bazi_chart.dart';
import '../../../../domain/entities/pillar.dart';
import '../../../../domain/entities/shensha_item.dart';

/// 命宫、身宫、胎元、胎息（由 lunar EightChar 推算）。
class ExtraPillarsCard extends StatelessWidget {
  const ExtraPillarsCard({
    super.key,
    required this.chart,
    this.shenshaItems = const [],
  });

  final BaziChart chart;
  final List<ShenshaItem> shenshaItems;

  @override
  Widget build(BuildContext context) {
    if (chart.extraPillars.isEmpty) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('命宫 · 身宫 · 胎元 · 胎息', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final gap = constraints.maxWidth < 420 ? 6.0 : 10.0;
                final count = chart.extraPillars.length;
                final pillarWidth =
                    (constraints.maxWidth - gap * (count - 1)) / count;
                final compact = pillarWidth < 120;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < count; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      Expanded(
                        child: _ExtraPillarTile(
                          pillar: chart.extraPillars[i],
                          shensha: shenshaItems
                              .where(
                                  (s) => s.pillar == chart.extraPillars[i].label)
                              .toList(),
                          compact: compact,
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

class _ExtraPillarTile extends StatelessWidget {
  const _ExtraPillarTile({
    required this.pillar,
    required this.shensha,
    required this.compact,
  });

  final Pillar pillar;
  final List<ShenshaItem> shensha;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stemColor = AppColors.fiveElementByStem(pillar.stem);
    final padding = compact ? 8.0 : 14.0;
    final ganZhiStyle =
        compact ? textTheme.titleLarge : textTheme.headlineSmall;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment:
            compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            pillar.label,
            style: textTheme.bodySmall,
            textAlign: compact ? TextAlign.center : null,
          ),
          SizedBox(height: compact ? 6 : 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pillar.stem,
                textAlign: TextAlign.center,
                style: ganZhiStyle?.copyWith(color: stemColor),
              ),
              SizedBox(height: compact ? 2 : 6),
              Text(
                pillar.branch,
                textAlign: TextAlign.center,
                style: ganZhiStyle,
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            '${pillar.tenGod} · ${pillar.naYin}',
            style: textTheme.bodySmall?.copyWith(color: AppColors.deepGray),
            textAlign: compact ? TextAlign.center : TextAlign.start,
            maxLines: compact ? 3 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
          ),
          if (shensha.isNotEmpty) ...[
            SizedBox(height: compact ? 8 : 10),
            Wrap(
              spacing: compact ? 4 : 6,
              runSpacing: compact ? 4 : 6,
              alignment: compact ? WrapAlignment.center : WrapAlignment.start,
              children: shensha
                  .map(
                    (item) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 6 : 8,
                        vertical: compact ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.name,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
