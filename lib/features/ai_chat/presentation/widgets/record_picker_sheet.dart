import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/app_strings.dart';
import '../../../../domain/entities/bazi_record.dart';
import '../../../history/application/bazi_records_list_controller.dart';
import '../../../history/presentation/widgets/birth_label_text.dart';
import '../../../history/application/save_bazi_record.dart'
    show findSavedRecord, saveBaziReport;
import '../../../input/application/bazi_input_controller.dart';
import 'chart_loading_widgets.dart';

class RecordPickerSheet extends ConsumerStatefulWidget {
  const RecordPickerSheet({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  final String? selectedId;
  final ValueChanged<BaziRecord> onSelect;

  @override
  ConsumerState<RecordPickerSheet> createState() => _RecordPickerSheetState();
}

class _RecordPickerSheetState extends ConsumerState<RecordPickerSheet> {
  bool _pendingSave = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSavePendingChart());
  }

  static const _pendingAutoStartKey = 'pending_ai_auto_start';

  Future<void> _maybeSavePendingChart() async {
    if (_pendingSave) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_pendingAutoStartKey) != true) return;

    final input = ref.read(baziInputControllerProvider);
    if (input.report == null) return;

    _pendingSave = true;
    try {
      final existing = findSavedRecord(
        ref,
        report: input.report!,
        personName: input.personName,
      );
      if (existing == null) {
        await saveBaziReport(
          ref,
          report: input.report!,
          personName: input.personName,
        );
      }
    } finally {
      _pendingSave = false;
    }
  }

  Future<void> _retryLoad() async {
    await ref.read(baziRecordsListProvider.notifier).refresh(silent: false);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(baziRecordsListProvider);
    final textTheme = Theme.of(context).textTheme;
    final records = ref.watch(deduplicatedRecordsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(AppStrings.aiSelectChartTitle, style: textTheme.titleMedium),
                const Spacer(),
                if (records.isNotEmpty)
                  Text('共 ${records.length} 条', style: textTheme.bodySmall),
              ],
            ),
          ),
          if (listState.isRefreshing)
            const ChartListRefreshBar(message: AppStrings.chartListRefreshing),
          if (listState.isLoading && records.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: ChartSessionLoading(message: AppStrings.chartListLoading),
            )
          else if (listState.error != null && records.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                children: [
                  Text(
                    AppStrings.chartListLoadFailed,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.deepGray),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _retryLoad,
                    child: const Text(AppStrings.actionRetry),
                  ),
                ],
              ),
            )
          else if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Text(
                AppStrings.aiNoSavedRecords,
                style: textTheme.bodySmall?.copyWith(color: AppColors.deepGray),
                textAlign: TextAlign.center,
              ),
            )
          else
            Flexible(child: _RecordList(records: records, selectedId: widget.selectedId, onSelect: widget.onSelect)),
        ],
      ),
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({
    required this.records,
    required this.selectedId,
    required this.onSelect,
  });

  final List<BaziRecord> records;
  final String? selectedId;
  final ValueChanged<BaziRecord> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      shrinkWrap: true,
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = records[i];
        final isSelected = r.id == selectedId;
        final saved =
            '${r.savedAt.year}.${r.savedAt.month.toString().padLeft(2, '0')}'
            '.${r.savedAt.day.toString().padLeft(2, '0')}';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelect(r),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold.withValues(alpha: 0.06)
                    : AppColors.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.gold.withValues(alpha: 0.25)
                      : AppColors.line,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.cinnabar.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      r.personName.isNotEmpty ? r.personName[0] : '?',
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.cinnabar,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.personName.isNotEmpty ? r.personName : '未命名',
                          style: textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        BirthLabelText.fromRequestJson(
                          r.requestJson,
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '保存于 $saved',
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: AppColors.deepGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '当前',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
