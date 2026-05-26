import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/app.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/app_strings.dart';
import '../../../../domain/entities/bazi_record.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../history/application/bazi_records_list_controller.dart';
import '../../../history/application/save_bazi_record.dart'
    show persistLastSelectedRecord,
        saveBaziReport;
import '../../../input/application/bazi_input_controller.dart';
import '../../application/chat_controller.dart';
import '../widgets/chart_loading_widgets.dart';
import '../widgets/chat_analysis_widgets.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/record_picker_sheet.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  BaziRecord? _selectedRecord;
  bool _isRestoringSession = false;
  bool _isSyncingChart = false;
  bool _bootstrapInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(baziRecordsListProvider.notifier).ensureLoaded());
      final currentTab = ref.read(mainTabIndexProvider);
      if (currentTab == 1) {
        _bootstrapAiTab();
      }
    });
  }

  Future<void> _bootstrapAiTab() async {
    if (_bootstrapInFlight) return;
    _bootstrapInFlight = true;
    try {
      await Future.wait([
        ref.read(baziRecordsListProvider.notifier).ensureLoaded(),
        _syncPendingChart(),
      ]);
      if (!mounted) return;
      await _tryRestoreSession();
    } finally {
      _bootstrapInFlight = false;
    }
  }

  static const _pendingAutoStartKey = 'pending_ai_auto_start';

  /// Persists the in-memory chart from 排盘 into Supabase so AI 看盘 can list it.
  Future<void> _syncPendingChart() async {
    if (_isSyncingChart) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_pendingAutoStartKey) != true) return;

    final input = ref.read(baziInputControllerProvider);
    final report = input.report;
    if (report == null) return;

    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    _isSyncingChart = true;
    try {
      await saveBaziReport(
        ref,
        report: report,
        personName: input.personName,
      );
      if (!mounted) return;
    } finally {
      _isSyncingChart = false;
    }
  }

  Future<void> _tryRestoreSession() async {
    if (_isRestoringSession) return;
    _isRestoringSession = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final autoStart = prefs.getBool(_pendingAutoStartKey) ?? false;
      if (!autoStart) {
        return;
      }

      await prefs.remove(_pendingAutoStartKey);
      final saved = await ChatController.loadLastSelectedRecord();
      if (saved == null) return;

      final recordId = saved['id'] as String;
      final hasHistory = await ChatController.hasChatHistory(
        ref.read(chatHistoryStoreProvider),
        recordId,
      );
      await _restoreLastSession(beginAnalysis: !hasHistory);
    } finally {
      _isRestoringSession = false;
    }
  }

  Future<void> _restoreLastSession({bool beginAnalysis = false}) async {
    final saved = await ChatController.loadLastSelectedRecord();
    if (saved == null) return;
    if (!mounted) return;

    final chat = ref.read(chatControllerProvider.notifier);

    final recordId = saved['id'] as String;
    final personName = saved['personName'] as String? ?? '';
    final requestJson = saved['requestJson'] as String? ?? '';
    final reportJson = saved['reportJson'] as String? ?? '';

    final userId = ref.read(authControllerProvider).user?.id ?? '';
    BaziRecord? fromList = _findRecordInList(recordId);
    fromList ??= BaziRecord(
      id: recordId,
      userId: userId,
      personName: personName,
      requestJson: requestJson,
      reportJson: reportJson,
      savedAt: DateTime.now(),
    );
    ref.read(baziRecordsListProvider.notifier).upsertRecord(fromList);

    if (!mounted) return;
    setState(() {
      _selectedRecord = fromList;
    });

    await _selectChartOnController(
      chat,
      recordId: recordId,
      personName: personName,
      requestJson: requestJson,
      reportJson: reportJson,
      beginAnalysis: beginAnalysis,
    );
  }

  BaziRecord? _findRecordInList(String recordId) {
    for (final r in ref.read(baziRecordsListProvider).records) {
      if (r.id == recordId) return r;
    }
    return null;
  }

  Future<void> _selectChartOnController(
    ChatController chat, {
    required String recordId,
    required String personName,
    required String requestJson,
    required String reportJson,
    required bool beginAnalysis,
  }) async {
    if (beginAnalysis) {
      await chat.selectChartAndStartAnalysis(
        recordId: recordId,
        personName: personName,
        requestJson: requestJson,
        reportJson: reportJson,
      );
    } else {
      await chat.selectChart(
        recordId: recordId,
        personName: personName,
        requestJson: requestJson,
        reportJson: reportJson,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onSelectRecord(
    BaziRecord record, {
    bool beginAnalysis = false,
  }) async {
    final chatState = ref.read(chatControllerProvider);
    if (chatState.selectedRecordId == record.id && !beginAnalysis) {
      setState(() => _selectedRecord = record);
      return;
    }

    setState(() => _selectedRecord = record);
    await persistLastSelectedRecord(record);

    final chat = ref.read(chatControllerProvider.notifier);
    if (chatState.selectedRecordId == record.id && beginAnalysis) {
      await chat.startInitialAnalysisAsync();
      return;
    }

    await _selectChartOnController(
      chat,
      recordId: record.id,
      personName: record.personName,
      requestJson: record.requestJson,
      reportJson: record.reportJson,
      beginAnalysis: beginAnalysis,
    );
  }

  Future<void> _confirmDeleteHistory() async {
    final chatState = ref.read(chatControllerProvider);
    if (!chatState.hasSavedHistory && chatState.messages.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.actionDeleteChatTitle),
        content: const Text(AppStrings.actionDeleteChatBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.actionDelete,
                style: TextStyle(color: AppColors.cinnabar)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(chatControllerProvider.notifier).deleteChatHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.actionChatDeleted)),
    );
  }

  Future<void> _confirmDeleteMessage(int index) async {
    final chatState = ref.read(chatControllerProvider);
    if (index < 0 || index >= chatState.messages.length) return;

    final msg = chatState.messages[index];
    final preview = msg.content.length > 30
        ? '${msg.content.substring(0, 30)}...'
        : msg.content;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除消息'),
        content: Text('确定删除这条消息？\n"$preview"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.actionDelete,
                style: TextStyle(color: AppColors.cinnabar)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(chatControllerProvider.notifier).deleteMessage(index);
  }

  void _sendMessage() {
    final chatState = ref.read(chatControllerProvider);
    if (chatState.isLoading) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    ref.read(chatControllerProvider.notifier).askQuestion(text);
  }

  void _clearChat() {
    if (_selectedRecord != null) {
      setState(() => _selectedRecord = null);
    }
    ref.read(chatControllerProvider.notifier).clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(aiChatRefreshSignal, (_, __) {
      _bootstrapAiTab();
    });

    ref.listen(mainTabIndexProvider, (prev, next) {
      if (next == 1 && prev != 1) {
        _bootstrapAiTab();
      }
    });

    ref.listen(chatClearSignal, (_, __) {
      _clearChat();
    });

    final chatState = ref.watch(chatControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final restoringChart = chatState.isRestoringChart == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 看盘'),
        leading: _selectedRecord != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: AppStrings.actionClearChart,
                onPressed: () {
                  setState(() => _selectedRecord = null);
                  _clearChat();
                },
              )
            : null,
        actions: [
          if (chatState.selectedRecordId != null &&
              (chatState.hasSavedHistory || chatState.messages.isNotEmpty))
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: AppStrings.actionDeleteChat,
              onPressed: chatState.isLoading ? null : _confirmDeleteHistory,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedRecord != null)
              SelectedRecordBar(
                record: _selectedRecord!,
                hasSavedHistory: chatState.hasSavedHistory,
                onClear: _clearChat,
              ),
            if (chatState.selectedRecordId != null &&
                chatState.hasSavedHistory &&
                chatState.messages.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                // ignore: deprecated_member_use
                color: AppColors.gold.withValues(alpha: 0.06),
                child: Text(
                  AppStrings.aiHistoryRestored,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.gold),
                ),
              ),
            if (_isRestoringSession || restoringChart)
              Expanded(
                child: ChartSessionLoading(
                  message: restoringChart
                      ? AppStrings.chartSwitching
                      : AppStrings.chartLoading,
                ),
              )
            else if (chatState.selectedRecordId == null && _selectedRecord == null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            // ignore: deprecated_member_use
                            size: 56, color: AppColors.gold.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(AppStrings.aiPickChartPrompt,
                            style: textTheme.titleMedium?.copyWith(
                                color: AppColors.deepGray)),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.aiPickChartSubtitle,
                          style: textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: chatState.isLoading
                              ? null
                              : () => _showRecordPicker(beginAnalysis: true),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text(AppStrings.actionGenerateAnalysis),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (chatState.messages.isEmpty && !chatState.isLoading)
              Expanded(
                child: EmptyAnalysisPrompt(
                  onStart: () => _showRecordPicker(beginAnalysis: true),
                ),
              )
            else
              Expanded(
                child: ChatMessageList(
                  state: chatState,
                  scrollController: _scrollController,
                  onSuggestionTap: (q) {
                    ref.read(chatControllerProvider.notifier).askQuestion(q);
                  },
                  onDeleteMessage: (index) => _confirmDeleteMessage(index),
                ),
              ),
            if (chatState.error != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                // ignore: deprecated_member_use
                color: AppColors.cinnabar.withValues(alpha: 0.06),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.cinnabar, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatState.error!,
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppColors.cinnabar),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref.read(chatControllerProvider.notifier).retryInitialAnalysis(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: AppColors.cinnabar.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(AppStrings.actionRetry,
                            style: textTheme.bodySmall?.copyWith(
                                color: AppColors.cinnabar)),
                      ),
                    ),
                  ],
                ),
              ),
            if (chatState.selectedRecordId != null) ChatInputBar(
              controller: _messageController,
              isLoading: chatState.isLoading,
              onSend: _sendMessage,
              onAddRecord: () => _showRecordPicker(),
              onCancel: () => ref.read(chatControllerProvider.notifier).cancelAnalysis(),
            )
            else
              StandaloneAddButton(
                onTap: () => _showRecordPicker(beginAnalysis: false),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRecordPicker({bool beginAnalysis = false}) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.loginRequiredForAi)),
      );
      return;
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => RecordPickerSheet(
        selectedId: _selectedRecord?.id,
        onSelect: (r) {
          Navigator.of(sheetContext).pop();
          _onSelectRecord(r, beginAnalysis: beginAnalysis);
        },
      ),
    );
  }
}
