import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/app_strings.dart';
import '../../../../domain/entities/bazi_record.dart';
import '../../../../domain/services/bazi_record_repository.dart';
import '../../../history/application/bazi_records_list_controller.dart';
import '../../../history/application/collection_records_provider.dart';
import '../../../history/application/collections_list_controller.dart';
import '../../../history/presentation/widgets/birth_label_text.dart';
import '../../../history/application/save_bazi_record.dart'
    show findSavedRecord, saveBaziReport;
import '../../../input/application/bazi_input_controller.dart';
import 'chart_loading_widgets.dart';

enum _RecordPickerSource { all, collection }

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
  _RecordPickerSource _source = _RecordPickerSource.all;
  CollectionModel? _openedCollection;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeSavePendingChart();
      ref.read(baziRecordsListProvider.notifier).ensureLoaded();
      ref.read(collectionsListProvider.notifier).ensureLoaded();
    });
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
    if (_source == _RecordPickerSource.collection &&
        _openedCollection != null) {
      ref.invalidate(collectionRecordsProvider(_openedCollection!.id));
      return;
    }
    if (_source == _RecordPickerSource.collection) {
      await ref.read(collectionsListProvider.notifier).refresh(silent: false);
    } else {
      await ref.read(baziRecordsListProvider.notifier).refresh(silent: false);
    }
  }

  void _openCollection(CollectionModel collection) {
    setState(() => _openedCollection = collection);
  }

  void _backToCollections() {
    setState(() => _openedCollection = null);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(baziRecordsListProvider);
    final collectionsState = ref.watch(collectionsListProvider);
    final textTheme = Theme.of(context).textTheme;
    final records = ref.watch(deduplicatedRecordsProvider);

    final inCollectionRecords = _openedCollection != null;
    final title = inCollectionRecords
        ? _openedCollection!.name
        : AppStrings.aiSelectChartTitle;
    final sheetHeight = MediaQuery.of(context).size.height * 0.62;

    return PopScope(
      canPop: !inCollectionRecords,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _backToCollections();
      },
      child: SizedBox(
        height: sheetHeight,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
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
                padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
                child: Row(
                  children: [
                    if (inCollectionRecords)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: '返回合集列表',
                        onPressed: _backToCollections,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      )
                    else
                      const SizedBox(width: 8),
                    Expanded(
                      child: Text(title, style: textTheme.titleMedium),
                    ),
                    if (!inCollectionRecords &&
                        _source == _RecordPickerSource.all)
                      Text('共 ${records.length} 条', style: textTheme.bodySmall),
                  ],
                ),
              ),
              if (!inCollectionRecords)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: SegmentedButton<_RecordPickerSource>(
                    segments: const [
                      ButtonSegment(
                        value: _RecordPickerSource.all,
                        label: Text('全部命盘'),
                        icon: Icon(Icons.list_alt_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: _RecordPickerSource.collection,
                        label: Text('命盘合集'),
                        icon: Icon(Icons.folder_outlined, size: 18),
                      ),
                    ],
                    selected: {_source},
                    onSelectionChanged: (value) {
                      final next = value.first;
                      setState(() => _source = next);
                      if (next == _RecordPickerSource.collection) {
                        ref
                            .read(collectionsListProvider.notifier)
                            .ensureLoaded();
                      }
                    },
                  ),
                ),
              if (listState.isRefreshing || collectionsState.isRefreshing)
                const ChartListRefreshBar(
                  message: AppStrings.chartListRefreshing,
                ),
              Expanded(
                child: _buildBody(listState, collectionsState, records),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BaziRecordsListState listState,
    CollectionsListState collectionsState,
    List<BaziRecord> allRecords,
  ) {
    if (_openedCollection != null) {
      return _CollectionRecordsPane(
        collection: _openedCollection!,
        selectedId: widget.selectedId,
        onSelect: widget.onSelect,
        onRetry: _retryLoad,
      );
    }

    if (_source == _RecordPickerSource.collection) {
      return _CollectionListPane(
        state: collectionsState,
        onOpen: _openCollection,
        onRetry: _retryLoad,
      );
    }

    return _AllRecordsPane(
      listState: listState,
      records: allRecords,
      selectedId: widget.selectedId,
      onSelect: widget.onSelect,
      onRetry: _retryLoad,
    );
  }
}

class _AllRecordsPane extends StatelessWidget {
  const _AllRecordsPane({
    required this.listState,
    required this.records,
    required this.selectedId,
    required this.onSelect,
    required this.onRetry,
  });

  final BaziRecordsListState listState;
  final List<BaziRecord> records;
  final String? selectedId;
  final ValueChanged<BaziRecord> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (listState.isLoading && records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: ChartSessionLoading(message: AppStrings.chartListLoading),
        ),
      );
    }
    if (listState.error != null && records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.chartListLoadFailed,
                style: textTheme.bodySmall?.copyWith(color: AppColors.deepGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                child: const Text(AppStrings.actionRetry),
              ),
            ],
          ),
        ),
      );
    }
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Text(
            AppStrings.aiNoSavedRecords,
            style: textTheme.bodySmall?.copyWith(color: AppColors.deepGray),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return _RecordList(
      records: records,
      selectedId: selectedId,
      onSelect: onSelect,
    );
  }
}

class _CollectionListPane extends ConsumerWidget {
  const _CollectionListPane({
    required this.state,
    required this.onOpen,
    required this.onRetry,
  });

  final CollectionsListState state;
  final ValueChanged<CollectionModel> onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final collections = state.collections;

    if (state.isLoading && collections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: ChartSessionLoading(message: AppStrings.chartListLoading),
        ),
      );
    }
    if (state.error != null && collections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '合集加载失败',
                style: textTheme.bodySmall?.copyWith(color: AppColors.deepGray),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    if (collections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Text(
            '暂无合集，可在主页「命盘合集」中创建',
            style: textTheme.bodySmall?.copyWith(color: AppColors.deepGray),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: collections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final col = collections[i];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onOpen(col),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.folder_outlined,
                      color: AppColors.gold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(col.name, style: textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '点击查看命盘',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.deepGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.deepGray.withValues(alpha: 0.6),
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

class _CollectionRecordsPane extends ConsumerWidget {
  const _CollectionRecordsPane({
    required this.collection,
    required this.selectedId,
    required this.onSelect,
    required this.onRetry,
  });

  final CollectionModel collection;
  final String? selectedId;
  final ValueChanged<BaziRecord> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final asyncRecords = ref.watch(collectionRecordsProvider(collection.id));

    return asyncRecords.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: ChartSessionLoading(message: AppStrings.chartListLoading),
        ),
      ),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '加载合集命盘失败',
                style: textTheme.bodySmall?.copyWith(color: AppColors.deepGray),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ),
        ),
      ),
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Text(
                '该合集还没有添加命盘',
                style: textTheme.bodySmall?.copyWith(color: AppColors.deepGray),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return _RecordList(
          records: records,
          selectedId: selectedId,
          onSelect: onSelect,
        );
      },
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
