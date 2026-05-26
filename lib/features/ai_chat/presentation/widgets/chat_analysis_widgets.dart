import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/app_strings.dart';
import '../../../../domain/entities/bazi_record.dart';
import '../../../history/presentation/widgets/birth_label_text.dart';

class EmptyAnalysisPrompt extends StatelessWidget {
  const EmptyAnalysisPrompt({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_outlined,
                size: 48, color: AppColors.gold.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(AppStrings.aiEmptyNoChat,
                style: textTheme.titleMedium?.copyWith(color: AppColors.deepGray)),
            const SizedBox(height: 8),
            Text(
              AppStrings.aiEmptyNoChatSubtitle,
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text(AppStrings.actionGenerateAnalysis),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectedRecordBar extends StatelessWidget {
  const SelectedRecordBar({
    super.key,
    required this.record,
    required this.hasSavedHistory,
    required this.onClear,
  });

  final BaziRecord record;
  final bool hasSavedHistory;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              record.personName.isNotEmpty ? record.personName[0] : '?',
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record.personName,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                hasSavedHistory
                    ? Text(
                        '已有历史对话',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.gold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : BirthLabelText.fromRequestJson(
                        record.requestJson,
                        style: textTheme.bodySmall,
                        maxLines: 2,
                      ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: AppStrings.actionClearChart,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                child: const Icon(Icons.close, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StandaloneAddButton extends StatelessWidget {
  const StandaloneAddButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: onTap,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 20, color: AppColors.gold.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.aiPickChartToStart,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.gold.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
