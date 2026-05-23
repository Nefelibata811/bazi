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
                final isWide = constraints.maxWidth >= 720;
                final tiles = chart.extraPillars.map((pillar) {
                  final items = shenshaItems
                      .where((s) => s.pillar == pillar.label)
                      .toList();
                  return _ExtraPillarTile(pillar: pillar, shensha: items);
                }).toList();

                if (isWide) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < tiles.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: tiles[i]),
                        ],
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    for (var i = 0; i < tiles.length; i += 2) ...[
                      if (i > 0) const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: tiles[i]),
                            if (i + 1 < tiles.length) ...[
                              const SizedBox(width: 12),
                              Expanded(child: tiles[i + 1]),
                            ],
                          ],
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
  });

  final Pillar pillar;
  final List<ShenshaItem> shensha;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stemColor = AppColors.fiveElementByStem(pillar.stem);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pillar.label, style: textTheme.bodySmall),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  pillar.stem,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(color: stemColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pillar.branch,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${pillar.tenGod} · ${pillar.naYin}',
            style: textTheme.bodySmall?.copyWith(color: AppColors.deepGray),
          ),
          if (shensha.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: shensha
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
