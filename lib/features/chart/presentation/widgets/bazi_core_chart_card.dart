import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/bazi_chart.dart';
import '../../../../domain/entities/pillar.dart';
import '../../../../domain/entities/shensha_item.dart';

class BaziCoreChartCard extends StatelessWidget {
  const BaziCoreChartCard({
    super.key,
    required this.chart,
    this.shenshaItems = const [],
  });

  final BaziChart chart;
  final List<ShenshaItem> shenshaItems;

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
                final pillars = chart.pillars;
                final tiles = pillars.map((pillar) {
                  final items = shenshaItems
                      .where((s) => s.pillar == pillar.label)
                      .toList();
                  return _PillarTile(pillar: pillar, shensha: items);
                }).toList();

                if (isWide) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: tiles[i]),
                        ],
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: tiles[0]),
                          const SizedBox(width: 12),
                          Expanded(child: tiles[1]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: tiles[2]),
                          const SizedBox(width: 12),
                          Expanded(child: tiles[3]),
                        ],
                      ),
                    ),
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

class _PillarTile extends StatelessWidget {
  const _PillarTile({
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
          if (shensha.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...shensha.map((item) => _ShenshaTag(item: item)),
          ],
        ],
      ),
    );
  }
}

class _ShenshaTag extends StatelessWidget {
  const _ShenshaTag({required this.item});

  final ShenshaItem item;

  Color _color() {
    const auspicious = {
      '天乙贵人', '太极贵人', '福星贵人', '天德贵人', '月德贵人',
      '文昌', '学堂', '词馆', '禄神', '金舆', '国印贵人',
      '天厨贵人', '德秀贵人', '天赦日', '天医',
      '红鸾', '天喜', '将星', '三奇贵人', '十灵日', '六秀日',
    };
    const inauspicious = {
      '亡神', '劫煞', '灾煞', '羊刃', '飞刃',
      '孤辰', '寡宿', '魁罡', '十恶大败', '孤鸾煞', '阴错阳差',
      '丧门', '吊客', '披麻', '血刃',
      '红艳煞', '流霞', '四废日', '八专日', '九丑日',
      '天转', '地转', '天罗', '地网',
    };
    if (auspicious.contains(item.name)) return AppColors.gold;
    if (inauspicious.contains(item.name)) return AppColors.cinnabar;
    return AppColors.deepGray;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Text(
            item.name,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final category = _categoryLabel();
    final color = _color();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item.name,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  )),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(category,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.target,
                style: Theme.of(ctx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(item.description,
                style: Theme.of(ctx)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.6)),
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

  String _categoryLabel() {
    const auspicious = {
      '天乙贵人', '太极贵人', '福星贵人', '天德贵人', '月德贵人',
      '文昌', '学堂', '词馆', '禄神', '金舆', '国印贵人',
      '天厨贵人', '德秀贵人', '天赦日', '天医',
      '红鸾', '天喜', '将星', '三奇贵人', '十灵日', '六秀日',
    };
    const inauspicious = {
      '亡神', '劫煞', '灾煞', '羊刃', '飞刃',
      '孤辰', '寡宿', '魁罡', '十恶大败', '孤鸾煞', '阴错阳差',
      '丧门', '吊客', '披麻', '血刃',
      '红艳煞', '流霞', '四废日', '八专日', '九丑日',
      '天转', '地转', '天罗', '地网',
    };
    if (auspicious.contains(item.name)) return '吉';
    if (inauspicious.contains(item.name)) return '凶';
    return '平';
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
