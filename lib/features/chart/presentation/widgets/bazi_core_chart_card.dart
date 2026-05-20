import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/bazi_chart.dart';
import '../../../../domain/entities/pillar.dart';

class BaziCoreChartCard extends StatelessWidget {
  const BaziCoreChartCard({
    super.key,
    required this.chart,
  });

  final BaziChart chart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('四柱排盘', style: textTheme.titleLarge),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cinnabar.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '日主 ${chart.dayMaster}',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.cinnabar,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                final tileWidth = isWide
                    ? (constraints.maxWidth - 36) / 4
                    : (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: chart.pillars
                      .map(
                        (pillar) => SizedBox(
                          width: tileWidth,
                          child: _PillarTile(pillar: pillar),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PillarTile extends StatelessWidget {
  const _PillarTile({
    required this.pillar,
  });

  final Pillar pillar;

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
                  style: textTheme.headlineSmall?.copyWith(
                    color: stemColor,
                  ),
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
          const SizedBox(height: 12),
          _MetaRow(label: '十神', value: pillar.tenGod),
          const SizedBox(height: 8),
          _MetaRow(label: '纳音', value: pillar.naYin),
          if (pillar.xunKong.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MetaRow(label: '空亡', value: pillar.xunKong),
          ],
          const SizedBox(height: 8),
          _MetaRow(label: '长生', value: pillar.growthPhase),
          const SizedBox(height: 12),
          Text('藏干', style: textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: pillar.hiddenStems
                .map(
                  (item) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.fiveElementByStem(item.stem)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.fiveElementByStem(item.stem)
                            .withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      '${item.stem} ${item.tenGod}',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(label, style: body),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: body?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
