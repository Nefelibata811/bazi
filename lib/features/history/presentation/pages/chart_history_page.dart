import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/app_strings.dart';
import '../../../../domain/entities/bazi_record.dart';
import '../../../../domain/entities/bazi_request.dart';
import '../../../../domain/value_objects/calendar_type.dart';
import '../../../../domain/value_objects/gender.dart';
import '../../application/bazi_records_list_controller.dart';
import '../../application/save_bazi_record.dart';
import '../../../input/application/bazi_input_controller.dart';
import '../../../result/presentation/pages/bazi_result_page.dart';

final chartHistoryProvider = Provider<List<BaziRecord>>((ref) {
  return ref.watch(baziRecordsListProvider).records;
});

class ChartHistoryPage extends ConsumerWidget {
  const ChartHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(baziRecordsListProvider);
    final list = ref.watch(chartHistoryProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('排盘记录'),
      ),
      body: SafeArea(
        child: listState.isLoading && list.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Builder(builder: (context) {
            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '——',
                      style: textTheme.displaySmall?.copyWith(
                        color: AppColors.deepGray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.aiNoSavedRecords,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '每次排盘结果将自动保存在这里',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final record = list[index];
                final savedDate =
                    '${record.savedAt.year}.${record.savedAt.month.toString().padLeft(2, '0')}.${record.savedAt.day.toString().padLeft(2, '0')}';
                final savedTime =
                    '${record.savedAt.hour.toString().padLeft(2, '0')}:${record.savedAt.minute.toString().padLeft(2, '0')}';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      final request =
                          _parseRequest(record.requestJson);
                      if (request == null) return;

                      await ref
                          .read(baziInputControllerProvider.notifier)
                          .loadFromSavedRequest(request);

                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BaziResultPage(),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.line),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${list.length - index}',
                              style: textTheme.titleMedium?.copyWith(
                                color: AppColors.deepGray,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.personName.isNotEmpty
                                      ? record.personName
                                      : '未命名',
                                  style: textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$savedDate $savedTime  ·  ${record.birthLabel}',
                                  style: textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              await ref
                                  .read(baziRecordRepositoryProvider)
                                  .delete(record.id);
                              ref
                                  .read(baziRecordsListProvider.notifier)
                                  .removeRecord(record.id);
                            },
                            color: AppColors.deepGray,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
      ),
    );
  }

  BaziRequest? _parseRequest(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return BaziRequest(
        calendarType: map['calendarType'] == 'lunar'
            ? CalendarType.lunar
            : CalendarType.solar,
        gender: map['gender'] == 'female' ? Gender.female : Gender.male,
        solarDateTime: DateTime.parse(map['solarDateTime'] as String),
        lunarYear: map['lunarYear'] as int,
        lunarMonth: map['lunarMonth'] as int,
        lunarDay: map['lunarDay'] as int,
        isLeapMonth: map['isLeapMonth'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}
