import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/app.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/bazi_request.dart';
import '../../../../domain/services/bazi_record_repository.dart';
import '../../../../domain/value_objects/calendar_type.dart';
import '../../../../domain/value_objects/gender.dart';
import '../../../../infrastructure/database/supabase_bazi_record_repository.dart';
import '../../../../infrastructure/database/supabase_collection_repository.dart';
import '../../application/bazi_records_list_controller.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import '../../../input/application/bazi_input_controller.dart';
import '../../../result/presentation/pages/bazi_result_page.dart';

final peopleListProvider = Provider<List<PersonSummary>>((ref) {
  final records = ref.watch(baziRecordsListProvider).records;
  final grouped = <String, List<_RawRecord>>{};
  for (final r in records) {
    grouped.putIfAbsent(r.personName, () => []).add(_RawRecord(
          id: r.id,
          birthLabel: r.birthLabel,
          savedAt: r.savedAt,
          requestJson: r.requestJson,
          reportJson: r.reportJson,
        ));
  }

  return grouped.entries.map((e) {
    e.value.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return PersonSummary(
      name: e.key,
      recordCount: e.value.length,
      latestRecord: e.value.isNotEmpty ? e.value.first.birthLabel : '',
      latestRequestJson: e.value.isNotEmpty ? e.value.first.requestJson : '',
    );
  }).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

final _collectionsProvider =
    FutureProvider.autoDispose<List<CollectionModel>>((ref) async {
  ref.watch(baziRecordsVersionProvider);
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return [];
  final repo = SupabaseCollectionRepository(Supabase.instance.client);
  return repo.listByUser(user.id);
});

class _RawRecord {
  final String id;
  final String birthLabel;
  final DateTime savedAt;
  final String requestJson;
  final String reportJson;
  _RawRecord({
    required this.id,
    required this.birthLabel,
    required this.savedAt,
    required this.requestJson,
    required this.reportJson,
  });
}

class PersonSummary {
  final String name;
  final int recordCount;
  final String latestRecord;
  final String latestRequestJson;
  const PersonSummary({
    required this.name,
    required this.recordCount,
    required this.latestRecord,
    required this.latestRequestJson,
  });
}

class PeopleListPage extends ConsumerWidget {
  const PeopleListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(_collectionsProvider);
    final recordsState = ref.watch(baziRecordsListProvider);
    final people = ref.watch(peopleListProvider);
    final authState = ref.watch(authControllerProvider);
    final displayName = authState.displayName;
    final avatarUrl = authState.user?.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('命主列表'),
        actions: [
          _UserAvatarButton(
            displayName: displayName,
            avatarUrl: avatarUrl,
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            tooltip: '命盘合集',
            onPressed: () => _showCreateCollectionDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '排盘记录',
            onPressed: () {
              Navigator.of(context).pushNamed('/history');
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建排盘',
            onPressed: () {
              Navigator.of(context).pushNamed('/input');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _SectionHeader(
              icon: Icons.folder,
              title: '命盘合集',
              onAdd: () => _showCreateCollectionDialog(context, ref),
            ),
            const SizedBox(height: 8),
            collections.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (list) => list.isEmpty
                  ? _HintCard(
                      icon: Icons.folder_open,
                      text: '暂无合集，创建合集来归总排盘记录',
                      actionLabel: '创建合集',
                      onAction: () =>
                          _showCreateCollectionDialog(context, ref),
                    )
                  : _CollectionsList(
                      collections: list,
                      onTap: (col) {
                        Navigator.of(context).pushNamed(
                          '/collection_detail',
                          arguments: {
                            'collectionId': col.id,
                            'collectionName': col.name,
                          },
                        );
                      },
                      onRename: (col) =>
                          _showRenameDialog(context, ref, col.id, col.name),
                      onDelete: (col) =>
                          _showDeleteCollectionDialog(context, ref, col.id),
                    ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.people,
              title: '命主列表',
              onAdd: () {
                Navigator.of(context).pushNamed('/input');
              },
            ),
            const SizedBox(height: 8),
            if (recordsState.isLoading && people.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (people.isEmpty)
              _HintCard(
                icon: Icons.people_outline,
                text: '暂无排盘，点击右上角 + 开始第一次排盘',
                actionLabel: '新建排盘',
                onAction: () {
                  Navigator.of(context).pushNamed('/input');
                },
              )
            else
              _PeopleList(
                people: people,
                onTap: (person) async {
                        final request =
                            _parseRequest(person.latestRequestJson);
                        if (request == null) return;
                        try {
                          await ref
                              .read(baziInputControllerProvider.notifier)
                              .loadFromSavedRequest(request);
                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const BaziResultPage(
                                    isFromHistory: true),
                              ),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('加载排盘失败，请重试')),
                            );
                          }
                        }
                      },
                      onDelete: (person) async {
                        final user = ref.read(authControllerProvider).user;
                        if (user == null) return;
                        final repo = SupabaseBaziRecordRepository(
                            Supabase.instance.client);
                        await repo.deleteByPerson(user.id, person.name);
                        await ref
                            .read(baziRecordsListProvider.notifier)
                            .refresh(silent: true);
                        ref.read(chatClearSignal.notifier).state++;
                      },
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateCollectionDialog(BuildContext context, WidgetRef ref) {
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
      ref.invalidate(_collectionsProvider);
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
      BuildContext ctx, WidgetRef ref, String collectionId, String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: ctx,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名合集'),
        content: TextFormField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '请输入新名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final repo =
                  SupabaseCollectionRepository(Supabase.instance.client);
              await repo.rename(collectionId, name);
              ref.invalidate(_collectionsProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCollectionDialog(BuildContext ctx, WidgetRef ref, String collectionId) {
    showDialog(
      context: ctx,
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
              await repo.deleteCollection(collectionId);
              ref.invalidate(_collectionsProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('删除',
                style: TextStyle(color: AppColors.cinnabar)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.onAdd,
  });

  final IconData icon;
  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.gold),
        const SizedBox(width: 8),
        Text(title, style: textTheme.titleMedium),
        const Spacer(),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 22),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 40,
                color: AppColors.deepGray.withValues(alpha: 0.25)),
            const SizedBox(height: 10),
            Text(text, style: textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionsList extends StatelessWidget {
  const _CollectionsList({
    required this.collections,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final List<CollectionModel> collections;
  final ValueChanged<CollectionModel> onTap;
  final ValueChanged<CollectionModel> onRename;
  final ValueChanged<CollectionModel> onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: collections.map((col) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => onTap(col),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.folder,
                        color: AppColors.gold, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(col.name, style: textTheme.titleMedium),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'rename') onRename(col);
                      if (action == 'delete') onDelete(col);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'rename', child: Text('重命名')),
                      PopupMenuItem(
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
      }).toList(),
    );
  }
}

class _PeopleList extends StatelessWidget {
  const _PeopleList({
    required this.people,
    required this.onTap,
    required this.onDelete,
  });

  final List<PersonSummary> people;
  final ValueChanged<PersonSummary> onTap;
  final ValueChanged<PersonSummary> onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: people.map((person) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => onTap(person),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.cinnabar.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      person.name.isNotEmpty ? person.name[0] : '?',
                      style: textTheme.titleMedium?.copyWith(
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
                        Text(person.name, style: textTheme.titleMedium),
                        const SizedBox(height: 3),
                        Text(
                          '${person.recordCount} 条排盘 · ${person.latestRecord}',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('确认删除'),
                        content: Text('确定要删除「${person.name}」的所有排盘记录吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              onDelete(person);
                            },
                            child: const Text('删除',
                                style: TextStyle(color: AppColors.cinnabar)),
                          ),
                        ],
                      ),
                    ),
                    color: AppColors.deepGray,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _UserAvatarButton extends StatelessWidget {
  const _UserAvatarButton({
    required this.displayName,
    this.avatarUrl,
  });

  final String displayName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName.length > 8
                  ? '${displayName.substring(0, 7)}…'
                  : displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ink,
                  ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.cinnabar.withValues(alpha: 0.08),
              backgroundImage:
                  url != null && url.isNotEmpty ? NetworkImage(url) : null,
              child: url == null || url.isEmpty
                  ? Icon(Icons.person,
                      size: 16, color: AppColors.cinnabar.withValues(alpha: 0.5))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
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
      personName: map['personName'] as String?,
    );
  } catch (_) {
    return null;
  }
}
