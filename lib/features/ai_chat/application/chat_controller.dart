import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ai_api_messages.dart';
import '../../../core/api_config.dart';
import '../../../core/app_strings.dart';
import '../../../domain/services/chat_repository.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../../../features/history/infrastructure/bazi_request_codec.dart';
import '../../../infrastructure/calendar/chart_datetime_resolver.dart';
import '../../../infrastructure/ai/deepseek_chat_repository.dart';
import '../../../infrastructure/database/supabase_chat_history_store.dart';
import '../../../features/history/application/save_bazi_record.dart'
    show lastSelectedRecordPrefsKey;
import '../infrastructure/chat_history_store.dart';
import 'assistant_reply_formatter.dart';
import 'streaming_typing_reveal.dart';

final chatHistoryStoreProvider = Provider<ChatHistoryStore>((ref) {
  return HybridChatHistoryStore(
    local: SharedPreferencesChatHistoryStore(),
    cloud: SupabaseChatHistoryStore(Supabase.instance.client),
    isLoggedIn: () => ref.read(authControllerProvider).isLoggedIn,
  );
});

final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(
    repository: DeepSeekChatRepository(
      apiKey: ApiConfig.deepseekApiKey,
      baseUrl: ApiConfig.deepseekBaseUrl,
    ),
    historyStore: ref.watch(chatHistoryStoreProvider),
  );
});

@immutable
class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.selectedRecordId,
    this.selectedPersonName,
    this.reportSummary,
    this.error,
    this.streamingContent,
    this.hasSavedHistory = false,
    this.isRestoringChart = false,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final String? selectedRecordId;
  final String? selectedPersonName;
  final String? reportSummary;
  final String? error;
  final String? streamingContent;
  /// Whether persisted chat history exists for the current chart.
  final bool hasSavedHistory;
  final bool isRestoringChart;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? selectedRecordId,
    String? selectedPersonName,
    String? reportSummary,
    String? error,
    String? streamingContent,
    bool? hasSavedHistory,
    bool? isRestoringChart,
    bool clearStreamingContent = false,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      selectedRecordId: selectedRecordId ?? this.selectedRecordId,
      selectedPersonName: selectedPersonName ?? this.selectedPersonName,
      reportSummary: reportSummary ?? this.reportSummary,
      error: clearError ? null : error,
      streamingContent: clearStreamingContent
          ? null
          : (streamingContent ?? this.streamingContent),
      hasSavedHistory: hasSavedHistory ?? this.hasSavedHistory,
      isRestoringChart: isRestoringChart ?? this.isRestoringChart,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  ChatController({
    required this.repository,
    required ChatHistoryStore historyStore,
    String? deepseekApiKey,
  })  : _historyStore = historyStore,
        _deepseekApiKey = deepseekApiKey ?? ApiConfig.deepseekApiKey,
        super(const ChatState());

  final ChatRepository repository;
  final ChatHistoryStore _historyStore;
  final String _deepseekApiKey;
  String? _analyzingRecordId;
  StreamSubscription<String>? _activeSubscription;
  StreamingTypingReveal? _typingReveal;

  static const _initialAnalysisPrompt =
      '请根据以上排盘数据为我做一份完整的八字命理分析';

  void _disposeTyping() {
    _typingReveal?.dispose();
    _typingReveal = null;
  }

  bool _hasCompletedConversation() {
    return state.messages.any(
      (m) => m.role == 'assistant' && m.content.trim().isNotEmpty,
    );
  }

  void _setupTypingForRecord(String recordId) {
    _disposeTyping();
    _typingReveal = StreamingTypingReveal()
      ..onTick = (visible) {
        if (mounted && _analyzingRecordId == recordId) {
          state = state.copyWith(streamingContent: visible);
        }
      };
  }

  void cancelAnalysis() {
    _activeSubscription?.cancel();
    _activeSubscription = null;
    _disposeTyping();
    _analyzingRecordId = null;
    if (mounted) {
      state = state.copyWith(
        isLoading: false,
        clearStreamingContent: true,
        error: AppStrings.analysisCancelled,
      );
    }
  }

  Future<void> selectChart({
    required String recordId,
    required String personName,
    required String requestJson,
    required String reportJson,
  }) async {
    final isSameRecord = state.selectedRecordId == recordId;
    final summary = _buildReportSummary(personName, requestJson, reportJson);

    if (isSameRecord &&
        state.messages.isNotEmpty &&
        summary == state.reportSummary) {
      return;
    }

    if (!isSameRecord && state.isLoading) {
      _activeSubscription?.cancel();
      _activeSubscription = null;
      _analyzingRecordId = null;
    }

    if (!isSameRecord) {
      state = state.copyWith(
        selectedRecordId: recordId,
        selectedPersonName: personName,
        reportSummary: summary,
        isRestoringChart: true,
        clearError: true,
        clearStreamingContent: true,
      );
    }

    try {
      final history = await _historyStore.load(recordId);
      final hasHistory = history.any(
        (m) => m.role == 'assistant' && m.content.trim().isNotEmpty,
      );

      if (!mounted) return;

      state = state.copyWith(
        selectedRecordId: recordId,
        selectedPersonName: personName,
        reportSummary: summary,
        messages: history,
        hasSavedHistory: hasHistory,
        isRestoringChart: false,
        clearError: true,
        clearStreamingContent: true,
      );

      _saveLastSelectedRecord(recordId, personName, requestJson, reportJson);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          isRestoringChart: false,
          error: '加载命盘对话失败，请重试',
        );
      }
      rethrow;
    } finally {
      if (mounted && state.isRestoringChart) {
        state = state.copyWith(isRestoringChart: false);
      }
    }
  }

  /// Selects a chart and runs the first analysis (used after picker confirm).
  Future<void> selectChartAndStartAnalysis({
    required String recordId,
    required String personName,
    required String requestJson,
    required String reportJson,
  }) async {
    await selectChart(
      recordId: recordId,
      personName: personName,
      requestJson: requestJson,
      reportJson: reportJson,
    );
    if (!mounted) return;
    await startInitialAnalysisAsync();
  }

  Future<void> startInitialAnalysisAsync() async {
    final recordId = state.selectedRecordId;
    if (recordId == null) return;
    if (state.isLoading) return;
    if (_hasCompletedConversation()) return;
    await _sendInitialAnalysis(recordId);
  }

  void clearSelection() {
    _activeSubscription?.cancel();
    _activeSubscription = null;
    _disposeTyping();
    _analyzingRecordId = null;
    _clearLastSelection();
    state = const ChatState();
  }

  void _clearLastSelection() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(lastSelectedRecordPrefsKey);
    });
  }

  void retryInitialAnalysis() {
    if (_hasCompletedConversation()) {
      final lastUser = state.messages
          .where((m) => m.role == 'user')
          .fold<ChatMessage?>(null, (prev, m) => m);
      if (lastUser != null) {
        unawaited(askQuestion(lastUser.content, resend: true));
      }
      return;
    }
    unawaited(startInitialAnalysisAsync());
  }

  /// Deletes persisted chat history for the current chart.
  Future<void> deleteChatHistory() async {
    final id = state.selectedRecordId;
    if (id == null) return;

    _activeSubscription?.cancel();
    _activeSubscription = null;
    _disposeTyping();
    _analyzingRecordId = null;

    await _historyStore.delete(id);

    if (!mounted) return;
    state = state.copyWith(
      messages: [],
      hasSavedHistory: false,
      isLoading: false,
      clearError: true,
      clearStreamingContent: true,
    );
  }

  Future<void> deleteMessage(int index) async {
    if (index < 0 || index >= state.messages.length) return;
    if (state.isLoading) return;

    final updated = [...state.messages];
    updated.removeAt(index);
    state = state.copyWith(messages: updated);
    await _persistMessages(updated);
  }

  static Future<bool> hasChatHistory(
    ChatHistoryStore store,
    String recordId,
  ) {
    return store.hasHistory(recordId);
  }

  Future<void> _sendInitialAnalysis(String recordId) async {
    final summary = state.reportSummary;
    if (summary == null) return;
    if (state.isLoading) return;
    if (_hasCompletedConversation()) return;

    _activeSubscription?.cancel();
    _disposeTyping();

    final systemPrompt = _buildSystemPrompt(summary);

    final List<ChatMessage> messagesForApi;
    if (state.messages.isNotEmpty &&
        state.messages.last.role == 'user' &&
        state.messages.last.content == _initialAnalysisPrompt) {
      messagesForApi = List.of(state.messages);
    } else {
      messagesForApi = [
        ...state.messages,
        const ChatMessage(role: 'user', content: _initialAnalysisPrompt),
      ];
    }

    _analyzingRecordId = recordId;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      streamingContent: '',
      messages: messagesForApi,
    );
    await _persistMessages(messagesForApi);

    final keyError = missingDeepseekApiKeyMessage(_deepseekApiKey);
    if (keyError != null) {
      if (mounted && _analyzingRecordId == recordId) {
        state = state.copyWith(
          isLoading: false,
          clearStreamingContent: true,
          error: keyError,
        );
      }
      _analyzingRecordId = null;
      return;
    }

    try {
      final stream = await repository.sendMessage(
        history: messagesForApi,
        systemPrompt: systemPrompt,
      );
      await _consumeStream(
        recordId: recordId,
        stream: stream,
        baseMessages: messagesForApi,
        isInitialAnalysis: true,
      );
    } catch (e) {
      if (mounted && _analyzingRecordId == recordId) {
        state = state.copyWith(
          isLoading: false,
          clearStreamingContent: true,
          error: formatAiApiError(e),
        );
      }
      _activeSubscription = null;
      _disposeTyping();
      _analyzingRecordId = null;
    }
  }

  Future<void> askQuestion(String question, {bool resend = false}) async {
    final summary = state.reportSummary;
    final recordId = state.selectedRecordId;
    if (summary == null || recordId == null) return;
    if (question.trim().isEmpty) return;
    if (state.isLoading) return;

    _activeSubscription?.cancel();
    _disposeTyping();

    final List<ChatMessage> updatedMessages;
    if (resend) {
      updatedMessages = List.of(state.messages);
    } else {
      updatedMessages = [
        ...state.messages,
        ChatMessage(role: 'user', content: question.trim()),
      ];
    }

    _analyzingRecordId = recordId;

    state = state.copyWith(
      messages: updatedMessages,
      isLoading: true,
      clearError: true,
      streamingContent: '',
    );
    await _persistMessages(updatedMessages);

    final systemPrompt = _buildSystemPrompt(summary);

    final keyError = missingDeepseekApiKeyMessage(_deepseekApiKey);
    if (keyError != null) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          clearStreamingContent: true,
          error: keyError,
        );
      }
      _analyzingRecordId = null;
      return;
    }

    try {
      final stream = await repository.sendMessage(
        history: updatedMessages,
        systemPrompt: systemPrompt,
      );
      await _consumeStream(
        recordId: recordId,
        stream: stream,
        baseMessages: updatedMessages,
        isInitialAnalysis: false,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          clearStreamingContent: true,
          error: formatAiApiError(e),
        );
      }
      _activeSubscription = null;
      _disposeTyping();
      _analyzingRecordId = null;
    }
  }

  Future<void> _consumeStream({
    required String recordId,
    required Stream<String> stream,
    required List<ChatMessage> baseMessages,
    required bool isInitialAnalysis,
  }) async {
    final buffer = StringBuffer();
    final completer = Completer<void>();
    _setupTypingForRecord(recordId);

    _activeSubscription = stream.listen(
      (chunk) {
        buffer.write(chunk);
        _typingReveal?.append(chunk);
      },
      onError: (e) {
        _disposeTyping();
        if (mounted && _analyzingRecordId == recordId) {
          state = state.copyWith(
            isLoading: false,
            clearStreamingContent: true,
            error: formatAiApiError(e),
          );
        }
        _activeSubscription = null;
        _analyzingRecordId = null;
        completer.complete();
      },
      onDone: () {
        unawaited(() async {
          await _typingReveal?.waitUntilCaughtUp();
          if (mounted && _analyzingRecordId == recordId) {
            final reply = AssistantReplyFormatter.finalize(
              raw: buffer.toString(),
              isInitialAnalysis: isInitialAnalysis,
              conversation: baseMessages,
              personName: state.selectedPersonName ?? '命主',
              reportSummary: state.reportSummary ?? '',
            );
            final finalMessages = [
              ...baseMessages,
              ChatMessage(role: 'assistant', content: reply),
            ];
            _disposeTyping();
            state = state.copyWith(
              isLoading: false,
              clearStreamingContent: true,
              messages: finalMessages,
            );
            await _persistMessages(finalMessages);
          } else {
            _disposeTyping();
          }
          _activeSubscription = null;
          _analyzingRecordId = null;
          completer.complete();
        }());
      },
      cancelOnError: true,
    );

    await completer.future;
  }

  Future<void> _persistMessages(List<ChatMessage> messages) async {
    final id = state.selectedRecordId;
    if (id == null || messages.isEmpty) return;
    await _historyStore.save(id, messages);
    if (!mounted) return;
    state = state.copyWith(hasSavedHistory: true);
  }

  Future<void> _saveLastSelectedRecord(
    String recordId,
    String personName,
    String requestJson,
    String reportJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        lastSelectedRecordPrefsKey,
        jsonEncode({
          'id': recordId,
          'personName': personName,
          'requestJson': requestJson,
          'reportJson': reportJson,
        }),
      );
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> loadLastSelectedRecord() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(lastSelectedRecordPrefsKey);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static const _chineseDigits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

  String _toChineseNumber(int n) {
    if (n <= 0) return _chineseDigits[0];
    if (n < 10) return _chineseDigits[n];
    if (n < 20) return '十${n == 10 ? '' : _chineseDigits[n % 10]}';
    final tens = n ~/ 10;
    final ones = n % 10;
    return '${_chineseDigits[tens]}十${ones == 0 ? '' : _chineseDigits[ones]}';
  }

  String _buildReportSummary(
      String personName, String requestJson, String reportJson) {
    final buf = StringBuffer();
    buf.writeln('命主姓名：$personName');

    try {
      final reqMap = jsonDecode(requestJson) as Map<String, dynamic>;
      final repMap = jsonDecode(reportJson) as Map<String, dynamic>;

      final isMale = reqMap['gender'] != 'female';
      final gender = isMale ? '男' : '女';
      final cal = reqMap['calendarType'] == 'lunar' ? '农历' : '公历';
      final solar = DateTime.parse(reqMap['solarDateTime'] as String);
      final minute = solar.minute.toString().padLeft(2, '0');
      final time = minute == '00' ? '${solar.hour}时' : '${solar.hour}:$minute';
      buf.writeln(
          '性别：$gender，历法：$cal，出生日期：${solar.year}年${solar.month}月${solar.day}日 $time');
      _appendTrueSolarTimeLines(buf, requestJson: requestJson, clockTimeLabel: time);

      final dayMaster = repMap['dayMaster'] as String? ?? '';
      if (dayMaster.isNotEmpty) buf.writeln('日主：$dayMaster');

      for (final key in ['year', 'month', 'day', 'hour']) {
        final p = repMap[key] as Map<String, dynamic>?;
        if (p == null) continue;
        final stem = p['stem'] as String? ?? '';
        final branch = p['branch'] as String? ?? '';
        if (stem.isEmpty || branch.isEmpty) continue;

        final tenGod = p['tenGod'] as String? ?? '';
        final tenGodStr = tenGod.isNotEmpty ? tenGod : '';
        final naYin = p['naYin'] as String? ?? '';
        final naYinStr = naYin.isNotEmpty ? '，纳音 $naYin' : '';
        final growthPhase = p['growthPhase'] as String? ?? '';
        final growthPhaseStr = growthPhase.isNotEmpty ? '，$growthPhase' : '';
        final xunKong = p['xunKong'] as String? ?? '';
        final xunKongStr = xunKong.isNotEmpty ? '，空亡 $xunKong' : '';

        final hiddenStemsRaw = p['hiddenStems'] as List<dynamic>?;
        final hiddenStr = hiddenStemsRaw != null && hiddenStemsRaw.isNotEmpty
            ? '，藏干：${hiddenStemsRaw.map((h) => '${(h as Map)['stem']}(${(h)['tenGod']})').join('、')}'
            : '';

        buf.writeln(
            '${_pillarLabel(key)}：$stem$branch${tenGodStr.isNotEmpty ? ' ($tenGodStr)' : ''}$naYinStr$growthPhaseStr$xunKongStr$hiddenStr');
      }

      final luckCyclesRaw = repMap['luckCycles'] as List<dynamic>?;
      if (luckCyclesRaw != null && luckCyclesRaw.isNotEmpty) {
        final lcLines = luckCyclesRaw.map((lc) {
          final m = lc as Map<String, dynamic>;
          final ganZhi = m['ganZhi'] as String? ?? '';
          final tenGod = m['tenGod'] as String? ?? '';
          final startAge = m['startAge'];
          final startYear = m['startYear'];
          return '$ganZhi${tenGod.isNotEmpty ? '($tenGod)' : ''}（$startAge岁/$startYear年起）';
        }).join('；');
        buf.writeln('大运：$lcLines');
      }

      final boneWeightMap = repMap['boneWeight'] as Map<String, dynamic>?;
      if (boneWeightMap != null && boneWeightMap['totalWeight'] != null) {
        final w = (boneWeightMap['totalWeight'] as num).toDouble();
        final liang = w.floor();
        final qian = ((w - liang) * 10).round();
        final label = qian == 0
            ? '${_toChineseNumber(liang)}两'
            : '${_toChineseNumber(liang)}两${_toChineseNumber(qian)}钱';
        final comment = isMale
            ? (boneWeightMap['maleComment'] as String? ?? '')
            : (boneWeightMap['femaleComment'] as String? ?? '');
        buf.writeln('称骨重量：$label（$comment）');
      }

      final analysisMap = repMap['analysis'] as Map<String, dynamic>?;
      if (analysisMap != null) {
        final patterns = analysisMap['patterns'] as List<dynamic>?;
        if (patterns != null && patterns.isNotEmpty) {
          final patternDescs = patterns.map((p) {
            final m = p as Map<String, dynamic>;
            final name = m['name'] as String? ?? '';
            final summary = m['summary'] as String? ?? '';
            final evidence = m['evidence'] as List<dynamic>?;
            final confidence = m['confidence'];
            final evStr = evidence != null && evidence.isNotEmpty
                ? '（依据：${evidence.join('、')}）'
                : '';
            final cfStr = confidence != null ? '（置信度$confidence）' : '';
            return '$name$cfStr${summary.isNotEmpty ? '：$summary' : ''}$evStr';
          }).where((s) => s.isNotEmpty).join('\n  ');
          if (patternDescs.isNotEmpty) buf.writeln('格局：\n  $patternDescs');
        }

        final usefulGod = analysisMap['usefulGod'] as Map<String, dynamic>?;
        if (usefulGod != null) {
          final ug = usefulGod['usefulGod'] as String? ?? '';
          final sg = usefulGod['supportiveGod'] as String? ?? '';
          final ag = usefulGod['avoidGod'] as String? ?? '';
          final strength = usefulGod['dayMasterStrength'] as String? ?? '';
          final summary = usefulGod['summary'] as String? ?? '';
          if (ug.isNotEmpty || summary.isNotEmpty) {
            if (strength.isNotEmpty) buf.writeln('日主强弱：$strength');
            buf.writeln('用神：$ug，喜神：$sg，忌神：$ag');
            if (summary.isNotEmpty) buf.writeln('用神解析：$summary');
          }
        }

        final shensha = analysisMap['shenshaItems'] as List<dynamic>?;
        if (shensha != null && shensha.isNotEmpty) {
          final items = shensha
              .map((s) => s is Map<String, dynamic>
                  ? _formatShenshaItem(s)
                  : s.toString())
              .where((s) => s.isNotEmpty)
              .join('；');
          if (items.isNotEmpty) buf.writeln('神煞：$items');
        }

        final notes = analysisMap['notes'] as List<dynamic>?;
        if (notes != null && notes.isNotEmpty) {
          buf.writeln('命理提示：${notes.join('；')}');
        }

        final interactionsRaw = analysisMap['interactions'] as List<dynamic>?;
        if (interactionsRaw != null && interactionsRaw.isNotEmpty) {
          final interLines = interactionsRaw.map((r) {
            final m = r as Map<String, dynamic>;
            final typeLabel = _interactionTypeLabel(m['type'] as String? ?? '');
            final nodeA = m['nodeA'] as String? ?? '';
            final nodeB = m['nodeB'] as String? ?? '';
            final desc = m['description'] as String? ?? '';
            return '[$typeLabel] $nodeA ↔ $nodeB${desc.isNotEmpty ? '（$desc）' : ''}';
          }).join('；');
          buf.writeln('干支互动：$interLines');
        }
      }
    } catch (e) {
      debugPrint('构建排盘摘要失败: $e');
      buf.writeln('[数据解析异常，部分命理数据缺失，请重新排盘]');
    }

    return buf.toString();
  }

  void _appendTrueSolarTimeLines(
    StringBuffer buf, {
    required String requestJson,
    required String clockTimeLabel,
  }) {
    final request = BaziRequestCodec.fromJson(requestJson);
    if (request == null) return;

    if (!request.useTrueSolarTime || request.longitude == null) {
      buf.writeln('真太阳时排盘：否（四柱按钟表时间 $clockTimeLabel 推算）');
      return;
    }

    final info = ChartDateTimeResolver.resolveInfo(request);
    if (info == null) return;

    final place = request.birthPlaceName?.trim();
    final placeLabel = place != null && place.isNotEmpty
        ? place
        : '东经 ${request.longitude!.toStringAsFixed(2)}°';
    final trueDt = info.trueSolarDateTime;
    final trueText =
        '${trueDt.hour.toString().padLeft(2, '0')}:${trueDt.minute.toString().padLeft(2, '0')}';
    final total = info.totalCorrectionMinutes;
    final sign = total >= 0 ? '+' : '';

    buf.writeln('真太阳时排盘：是（出生地 $placeLabel）');
    buf.writeln(
      '钟表 $clockTimeLabel → 真太阳时 $trueText（订正 $sign${total.toStringAsFixed(1)} 分；'
      '四柱按时辰以真太阳时为准）',
    );
  }

  String _pillarLabel(String key) {
    switch (key) {
      case 'year':
        return '年柱';
      case 'month':
        return '月柱';
      case 'day':
        return '日柱';
      case 'hour':
        return '时柱';
      default:
        return key;
    }
  }

  String _formatShenshaItem(Map<String, dynamic> s) {
    final name = s['name'] as String? ?? '';
    final target = s['target'] as String? ?? '';
    final desc = s['description'] as String? ?? '';
    final pillar = s['pillar'] as String?;
    final loc = pillar != null ? '[$pillar]' : '';
    return '$loc$name（$target）：$desc';
  }

  String _interactionTypeLabel(String type) {
    switch (type) {
      case 'stemCombine':
        return '天干五合';
      case 'stemClash':
        return '天干相冲';
      case 'branchCombine6':
        return '地支六合';
      case 'branchCombine3':
        return '地支三合';
      case 'branchCombineHalf':
        return '地支半合';
      case 'branchArch':
        return '地支拱合';
      case 'branchCombineMeet3':
        return '地支三会';
      case 'branchClash6':
        return '地支六冲';
      case 'branchHarm6':
        return '地支六害';
      case 'branchBreak':
        return '地支相破';
      case 'branchPunish':
        return '地支相刑';
      case 'branchPunishTriple':
        return '三刑会全';
      case 'branchSelfPunish':
        return '自刑';
      case 'stemBranchBothClash':
        return '天克地冲';
      case 'fuYin':
        return '伏吟';
      case 'fanYin':
        return '反吟';
      default:
        return type;
    }
  }

  @override
  void dispose() {
    _activeSubscription?.cancel();
    _activeSubscription = null;
    _disposeTyping();
    super.dispose();
  }

  String _buildSystemPrompt(String reportSummary) {
    final buf = StringBuffer();
    buf.writeln('你是一位专业的八字命理分析师，精通中国传统八字（四柱预测学）、纳音、神煞、用神、格局等。');
    buf.writeln('请用中文回答，语气亲切、专业，适当引用古文典籍。');
    buf.writeln();
    buf.writeln('用户八字排盘数据如下：');
    buf.writeln(reportSummary);
    buf.writeln();
    buf.writeln(
        '请严格基于以上数据进行分析，以连贯自然的段落撰写命理解读，涵盖命局概述、格局与用神、神煞要点及综合建议，不要分条编号，也不要重复同一内容。');
    buf.writeln('对 **日主**、**用神**、**格局**、**大运**、**神煞** 名称及关键结论，请用双星号包裹强调，例如 **甲木日主**、**正官格**。');
    buf.writeln('用户若有追问，请针对其问题作答，不要重新生成完整报告。');
    buf.writeln('【对话记忆】严格延续本会话全部上文，记住用户已提出的需求、设定与约定；禁止忽略历史、禁止无故重置对话或重复完整报告。');
    buf.writeln('【输出格式】只输出正文分析内容；禁止在文末自行添加「你可能还想了解」「推荐追问」或类似追问列表，系统会在每次回答结束后自动追加。');
    buf.writeln('不要使用 Markdown 标题（禁止使用 # 号），段落之间空一行，以纯文本段落呈现。');
    buf.writeln('以上所有分析必须严格基于上文排盘数据，禁止自行推算或编造任何数值。');

    return buf.toString();
  }
}
