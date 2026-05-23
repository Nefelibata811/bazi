import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/bazi_record.dart';
import '../../../../domain/entities/bazi_request.dart';
import '../../../../domain/services/bazi_record_repository.dart';
import '../../../../infrastructure/database/supabase_bazi_record_repository.dart';
import '../../../history/infrastructure/bazi_request_codec.dart';
import '../../../../infrastructure/database/supabase_collection_repository.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../input/application/bazi_input_controller.dart';
import '../../../result/presentation/pages/bazi_result_page.dart';

final _collectionListProvider =
    FutureProvider.autoDispose<List<CollectionModel>>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return Future.value([]);
  final repo = SupabaseCollectionRepository(Supabase.instance.client);
  return repo.listByUser(user.id);
});

class CollectionPage extends ConsumerWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(_collectionListProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('命盘合集'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            tooltip: '新建合集',
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: collections.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('加载失败')),
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open, size: 64,
                        color: AppColors.deepGray.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('暂无合集', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('点击右上角 + 创建合集来归总排盘记录',
                        style: textTheme.bodySmall),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateDialog(context, ref),
                      icon: const Icon(Icons.create_new_folder),
                      label: const Text('创建合集'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final col = list[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        '/collection_detail',
                        arguments: {
                          'collectionId': col.id,
                          'collectionName': col.name,
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.folder,
                                color: AppColors.gold, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(col.name, style: textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(
                                  '创建于 ${col.createdAt.year}年${col.createdAt.month}月${col.createdAt.day}日',
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'rename') {
                                _showRenameDialog(
                                    context, ref, col.id, col.name);
                              } else if (action == 'delete') {
                                _showDeleteDialog(context, ref, col.id);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'rename', child: Text('重命名')),
                              const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('删除',
                                      style:
                                          TextStyle(color: AppColors.cinnabar))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    bool isCreating = false;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.create_new_folder_rounded,
                        color: AppColors.gold, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text('新建合集', style: textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    '创建一个合集来归总您的排盘记录',
                    style: textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: '请输入合集名称',
                      prefixIcon: const Icon(Icons.folder_outlined,
                          color: AppColors.gold),
                      filled: true,
                      fillColor: AppColors.paper,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.gold, width: 1.5),
                      ),
                    ),
                    onFieldSubmitted: isCreating
                        ? null
                        : (_) => _doCreate(ctx, ref, controller,
                            setDialogState, () => isCreating, (v) => isCreating = v),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isCreating
                              ? null
                              : () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isCreating
                              ? null
                              : () => _doCreate(ctx, ref, controller,
                                  setDialogState, () => isCreating, (v) => isCreating = v),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isCreating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text('创建合集'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _doCreate(
    BuildContext ctx,
    WidgetRef ref,
    TextEditingController controller,
    void Function(void Function()) setDialogState,
    bool Function() getCreating,
    void Function(bool) setCreating,
  ) async {
    final name = controller.text.trim();
    if (name.isEmpty) return;
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    setDialogState(() => setCreating(true));
    try {
      final repo =
          SupabaseCollectionRepository(Supabase.instance.client);
      await repo.create(userId: user.id, name: name);
      ref.invalidate(_collectionListProvider);
      if (ctx.mounted) Navigator.of(ctx).pop();
    } catch (_) {
      setDialogState(() => setCreating(false));
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('创建失败，请重试')),
        );
      }
    }
  }

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, String id, String oldName) {
    final controller = TextEditingController(text: oldName);
    bool isSaving = false;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.drive_file_rename_outline_rounded,
                        color: AppColors.gold, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text('重命名合集', style: textTheme.titleLarge),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: '请输入新名称',
                      prefixIcon: const Icon(Icons.folder_outlined,
                          color: AppColors.gold),
                      filled: true,
                      fillColor: AppColors.paper,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.gold, width: 1.5),
                      ),
                    ),
                    onFieldSubmitted: isSaving
                        ? null
                        : (_) async {
                            final name = controller.text.trim();
                            if (name.isEmpty) return;
                            setDialogState(() => isSaving = true);
                            try {
                              final repo = SupabaseCollectionRepository(
                                  Supabase.instance.client);
                              await repo.rename(id, name);
                              ref.invalidate(_collectionListProvider);
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            } catch (_) {
                              setDialogState(() => isSaving = false);
                            }
                          },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final name = controller.text.trim();
                                  if (name.isEmpty) return;
                                  setDialogState(() => isSaving = true);
                                  try {
                                    final repo = SupabaseCollectionRepository(
                                        Supabase.instance.client);
                                    await repo.rename(id, name);
                                    ref.invalidate(_collectionListProvider);
                                    if (ctx.mounted) Navigator.of(ctx).pop();
                                  } catch (_) {
                                    setDialogState(() => isSaving = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('确认'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除合集不会删除排盘记录，确定要删除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final repo =
                  SupabaseCollectionRepository(Supabase.instance.client);
              await repo.deleteCollection(id);
              ref.invalidate(_collectionListProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child:
                const Text('删除', style: TextStyle(color: AppColors.cinnabar)),
          ),
        ],
      ),
    );
  }
}

class CollectionDetailPage extends ConsumerWidget {
  const CollectionDetailPage({
    super.key,
    required this.collectionId,
    required this.collectionName,
  });

  final String collectionId;
  final String collectionName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(_collectionRecordsProvider(collectionId));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(collectionName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加排盘记录',
            onPressed: () =>
                _showAddRecordDialog(context, ref, collectionId),
          ),
        ],
      ),
      body: SafeArea(
        child: records.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('加载失败')),
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('暂无排盘记录', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('点击右上角 + 添加排盘到该合集',
                        style: textTheme.bodySmall),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddRecordDialog(
                          context, ref, collectionId),
                      icon: const Icon(Icons.add),
                      label: const Text('添加排盘'),
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      final request = _parseRequest(record.requestJson);
                      if (request == null) return;

                      try {
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
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('加载排盘失败，请重试')),
                          );
                        }
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
                              '${index + 1}',
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
                                Text(record.personName,
                                    style: textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(record.dateLabel,
                                    style: textTheme.bodySmall),
                              ],
                            ),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.link_off, size: 20),
                            onPressed: () async {
                              final repo = SupabaseCollectionRepository(
                                  Supabase.instance.client);
                              await repo.removeRecord(
                                  collectionId, record.id);
                              ref.invalidate(
                                  _collectionRecordsProvider(collectionId));
                            },
                            color: AppColors.deepGray,
                            tooltip: '从合集中移除',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showAddRecordDialog(
      BuildContext context, WidgetRef ref, String collectionId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (ctx, scrollController) =>
              _AddRecordSheet(collectionId: collectionId),
        );
      },
    );
  }

  BaziRequest? _parseRequest(String json) => BaziRequestCodec.fromJson(json);
}

final _collectionRecordsProvider =
    FutureProvider.autoDispose.family<List<BaziRecord>, String>(
        (ref, collectionId) async {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return [];

  final colRepo = SupabaseCollectionRepository(Supabase.instance.client);
  final recordIds = await colRepo.getRecordIds(collectionId);

  if (recordIds.isEmpty) return [];

  final recordRepo =
      SupabaseBaziRecordRepository(Supabase.instance.client);
  final allRecords = await recordRepo.listByUser(user.id);

  return allRecords.where((r) => recordIds.contains(r.id)).toList();
});

final _allRecordsProvider =
    FutureProvider.autoDispose<List<BaziRecord>>((ref) async {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return [];
  final repo = SupabaseBaziRecordRepository(Supabase.instance.client);
  return repo.listByUser(user.id);
});

final _addedRecordIdsProvider =
    FutureProvider.autoDispose.family<Set<String>, String>(
        (ref, collectionId) async {
  final colRepo = SupabaseCollectionRepository(Supabase.instance.client);
  final ids = await colRepo.getRecordIds(collectionId);
  return ids.toSet();
});

class _AddRecordSheet extends ConsumerWidget {
  const _AddRecordSheet({required this.collectionId});

  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRecords = ref.watch(_allRecordsProvider);
    final addedIdsAsync = ref.watch(_addedRecordIdsProvider(collectionId));
    final textTheme = Theme.of(context).textTheme;
    final addedIds = addedIdsAsync.valueOrNull ?? <String>{};

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('选择要添加的排盘',
              style: textTheme.titleMedium),
        ),
        Expanded(
          child: allRecords.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('加载失败')),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text('暂无排盘记录', style: textTheme.bodyMedium),
                );
              }
              return ListView.builder(
                controller: ScrollController(),
                itemCount: list.length,
                itemBuilder: (ctx, index) {
                  final record = list[index];
                  final alreadyAdded = addedIds.contains(record.id);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.cinnabar.withValues(alpha: 0.08),
                      child: Text(
                        record.personName.isNotEmpty
                            ? record.personName[0]
                            : '?',
                        style: const TextStyle(
                            color: AppColors.cinnabar,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(record.personName),
                    subtitle: Text(record.dateLabel),
                    trailing: alreadyAdded
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: AppColors.gold, size: 20),
                              const SizedBox(width: 4),
                              Text('已添加',
                                  style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.gold)),
                            ],
                          )
                        : const Icon(Icons.add_circle_outline,
                            color: AppColors.gold),
                    onTap: alreadyAdded
                        ? null
                        : () async {
                            final repo = SupabaseCollectionRepository(
                                Supabase.instance.client);
                            await repo.addRecord(collectionId, record.id);
                            ref.invalidate(
                                _collectionRecordsProvider(collectionId));
                            ref.invalidate(
                                _addedRecordIdsProvider(collectionId));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('已添加「${record.personName}」'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
