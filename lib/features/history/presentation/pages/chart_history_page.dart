import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/app_strings.dart';
import '../../../../domain/entities/bazi_record.dart';
import '../../../../domain/entities/bazi_request.dart';
import '../../application/bazi_records_list_controller.dart';
import '../widgets/birth_label_text.dart';
import '../../infrastructure/bazi_request_codec.dart';
import '../../infrastructure/person_identity.dart';
import '../../application/save_bazi_record.dart'
    show baziRecordRepositoryProvider, clearLastSelectedRecordIfMatches;
import '../../../ai_chat/application/chat_controller.dart';
import '../../../input/application/bazi_input_controller.dart';
import '../../../result/presentation/pages/bazi_result_page.dart';

final chartHistoryProvider = Provider<List<BaziRecord>>((ref) {
  return ref.watch(deduplicatedRecordsProvider);
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

            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(baziRecordsListProvider.notifier).refresh(),
              child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
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
                                  '保存 $savedDate $savedTime',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: AppColors.deepGray,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                BirthLabelText.fromRequestJson(
                                  record.requestJson,
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _confirmDeleteRecord(
                              context,
                              ref,
                              record,
                            ),
                            color: AppColors.deepGray,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            );
          }),
      ),
    );
  }

  BaziRequest? _parseRequest(String json) =>
      BaziRequestCodec.fromJson(json);
}

Future<void> _confirmDeleteRecord(
  BuildContext context,
  WidgetRef ref,
  BaziRecord record,
) async {
  final name =
      record.personName.isNotEmpty ? record.personName : '未命名';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('确认删除'),
      content: Text('确定要删除「$name」的这条排盘记录吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(baziRecordRepositoryProvider).delete(record.id);
    ref.read(baziRecordsListProvider.notifier).removeRecord(record.id);
    await clearLastSelectedRecordIfMatches(recordId: record.id);

    final input = ref.read(baziInputControllerProvider);
    if (input.report != null) {
      final loaded = BaziRequestCodec.fromJson(record.requestJson);
      if (loaded != null &&
          loaded.solarDateTime == input.report!.request.solarDateTime &&
          PersonIdentity.normalizeName(record.personName) ==
              PersonIdentity.normalizeName(input.personName)) {
        ref.read(baziInputControllerProvider.notifier).clearCachedChart();
      }
    }

    final chatId = ref.read(chatControllerProvider).selectedRecordId;
    if (chatId == record.id) {
      ref.read(chatClearSignal.notifier).state++;
    }

    await ref.read(baziRecordsListProvider.notifier).refresh(silent: true);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除「$name」')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    }
  }
}
