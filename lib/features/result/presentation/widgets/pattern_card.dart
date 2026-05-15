import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/pattern_result.dart';

class PatternCard extends StatelessWidget {
  const PatternCard({
    super.key,
    required this.patterns,
  });

  final List<PatternResult> patterns;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (patterns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('格局分析', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '基于《子平真诠》月令取格法',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ...patterns.map((pattern) {
              final isPrimary = pattern.confidence >= 0.4;
              final chipColor = isPrimary
                  ? AppColors.cinnabar
                  : AppColors.deepGray;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cinnabar.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPrimary
                        ? AppColors.cinnabar.withOpacity(0.18)
                        : AppColors.line,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: chipColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            pattern.name,
                            style: textTheme.labelMedium?.copyWith(
                              color: chipColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(pattern.confidence * 100).round()}%',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.deepGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pattern.summary,
                      style: textTheme.bodyMedium,
                    ),
                    if (pattern.evidence.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...pattern.evidence.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '· ',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.deepGray,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e,
                                  style: textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
