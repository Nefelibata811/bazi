import 'dart:async';

import 'package:bazi_app/domain/services/chat_repository.dart';
import 'package:bazi_app/features/ai_chat/application/chat_controller.dart';
import 'package:bazi_app/features/ai_chat/infrastructure/chat_history_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockChatRepository implements ChatRepository {
  _MockChatRepository();

  List<ChatMessage> lastHistory = [];
  String lastSystemPrompt = '';
  StreamController<String>? _activeController;
  int callCount = 0;

  @override
  Future<Stream<String>> sendMessage({
    required List<ChatMessage> history,
    required String systemPrompt,
  }) async {
    callCount++;
    lastHistory = List.of(history);
    lastSystemPrompt = systemPrompt;
    _activeController = StreamController<String>();
    return _activeController!.stream;
  }

  void emitDone() {
    _activeController?.close();
    _activeController = null;
  }

  void emitChunk(String text) {
    _activeController?.add(text);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatController controller;
  late _MockChatRepository mockRepo;
  late InMemoryChatHistoryStore historyStore;

  const testRequestJson = '''
{
  "gender": "male",
  "calendarType": "solar",
  "solarDateTime": "1990-05-15T08:30:00.000"
}''';

  const testReportJson = '''
{
  "dayMaster": "甲",
  "year": {"stem": "庚", "branch": "午", "tenGod": "七杀", "naYin": "路旁土", "growthPhase": "病", "xunKong": "辰巳", "hiddenStems": [{"stem": "己","tenGod":"正财"},{"stem": "丁","tenGod":"伤官"}]},
  "month": {"stem": "辛", "branch": "巳", "tenGod": "正官", "naYin": "白蜡金", "growthPhase": "长生", "xunKong": "申酉", "hiddenStems": [{"stem": "丙","tenGod":"食神"},{"stem": "庚","tenGod":"七杀"}]},
  "day": {"stem": "甲", "branch": "寅", "tenGod": "比肩", "naYin": "大溪水", "growthPhase": "临官", "xunKong": "子丑", "hiddenStems": [{"stem": "甲","tenGod":"比肩"},{"stem": "丙","tenGod":"食神"}]},
  "hour": {"stem": "戊", "branch": "辰", "tenGod": "偏财", "naYin": "大林木", "growthPhase": "衰", "xunKong": "戌亥", "hiddenStems": [{"stem": "戊","tenGod":"偏财"},{"stem": "乙","tenGod":"劫财"}]},
  "analysis": {
    "patterns": [{"name": "正官格", "summary": "月令巳中丙火不透", "evidence": ["月支巳"], "confidence": 0.8}],
    "usefulGod": {"usefulGod": "水", "supportiveGod": "木", "avoidGod": "火", "dayMasterStrength": "偏弱", "summary": "甲生巳月火旺木弱"},
    "shenshaItems": [{"name": "天乙贵人", "target": "年支午", "description": "逢凶化吉"}],
    "notes": ["注意调和"]
  },
  "boneWeight": {"totalWeight": 4.2, "maleComment": "此命推来事不同", "femaleComment": ""},
  "luckCycles": [{"index": 0, "ganZhi": "辛巳", "tenGod": "正官", "startAge": 5, "startYear": 1995, "endYear": 2004}]
}''';

  const recordId = 'test-record';
  const personName = '测试';

  Future<void> selectChart() {
    return controller.selectChart(
      recordId: recordId,
      personName: personName,
      requestJson: testRequestJson,
      reportJson: testReportJson,
    );
  }

  Future<void> selectAndAnalyze() async {
    await controller.selectChartAndStartAnalysis(
      recordId: recordId,
      personName: personName,
      requestJson: testRequestJson,
      reportJson: testReportJson,
    );
  }

  setUp(() {
    mockRepo = _MockChatRepository();
    historyStore = InMemoryChatHistoryStore();
    controller = ChatController(
      repository: mockRepo,
      historyStore: historyStore,
    );
  });

  group('聊天记录', () {
    test('选择命盘不会自动生成分析', () async {
      await selectChart();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(mockRepo.callCount, equals(0));
      expect(controller.state.selectedRecordId, equals(recordId));
    });

    test('手动开始分析会调用 AI', () async {
      await selectChart();
      final analysis = controller.startInitialAnalysisAsync();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(mockRepo.callCount, equals(1));
      mockRepo.emitDone();
      await analysis;
    });

    test('有历史对话时不自动触发分析', () async {
      await historyStore.save(recordId, [
        const ChatMessage(role: 'user', content: '请分析'),
        const ChatMessage(role: 'assistant', content: '已有分析结果'),
      ]);

      await selectChart();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepo.callCount, equals(0));
      expect(controller.state.messages.length, equals(2));
      expect(controller.state.hasSavedHistory, isTrue);
    });

    test('已有助手回复时手动开始分析不会重复请求', () async {
      await historyStore.save(recordId, [
        const ChatMessage(role: 'user', content: '请分析'),
        const ChatMessage(role: 'assistant', content: '已有分析结果'),
      ]);

      await selectChart();
      await controller.startInitialAnalysisAsync();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepo.callCount, equals(0));
    });

    test('删除对话后可手动重新生成', () async {
      await historyStore.save(recordId, [
        const ChatMessage(role: 'user', content: '请分析'),
        const ChatMessage(role: 'assistant', content: '旧回复'),
      ]);

      await selectChart();
      expect(mockRepo.callCount, equals(0));

      await controller.deleteChatHistory();
      expect(controller.state.messages, isEmpty);
      expect(controller.state.hasSavedHistory, isFalse);

      final analysis = controller.startInitialAnalysisAsync();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(mockRepo.callCount, equals(1));
      mockRepo.emitDone();
      await analysis;
    });

    test('分析完成后会持久化聊天记录', () async {
      final analysis = selectAndAnalyze();
      await Future.delayed(const Duration(milliseconds: 50));
      mockRepo.emitChunk('分析内容');
      mockRepo.emitDone();
      await analysis;
      await Future.delayed(const Duration(milliseconds: 50));

      final saved = await historyStore.load(recordId);
      expect(saved.length, equals(2));
      expect(saved.last.role, equals('assistant'));
      expect(saved.last.content, contains('分析内容'));
      expect(await historyStore.hasHistory(recordId), isTrue);
    });
  });

  group('重复报告根因排查', () {
    Future<void> runAnalysisAndClose() async {
      final analysis = selectAndAnalyze();
      await Future.delayed(const Duration(milliseconds: 50));
      mockRepo.emitDone();
      await analysis;
    }

    test('1. sendMessage 只调用一次（排除前端重复请求）', () async {
      await runAnalysisAndClose();
      expect(mockRepo.callCount, equals(1));
    });

    test('2. history 必须包含 user 消息（排除空 history 导致 AI 重复输出）', () async {
      await runAnalysisAndClose();
      expect(mockRepo.lastHistory.isNotEmpty, isTrue);
      expect(mockRepo.lastHistory.first.role, equals('user'));
    });

    test('3. systemPrompt 不包含编号指令（排除 AI 把编号当多任务执行）', () async {
      await runAnalysisAndClose();
      expect(mockRepo.lastSystemPrompt, isNot(contains('=== 回答要求 ===')));
      expect(mockRepo.lastSystemPrompt, isNot(contains('1. 先对')));
    });

    test('4. systemPrompt 包含融合后的自然段落指令', () async {
      await runAnalysisAndClose();
      expect(mockRepo.lastSystemPrompt, contains('请严格基于以上数据进行分析'));
      expect(mockRepo.lastSystemPrompt, contains('不要重新生成完整报告'));
    });

    test('5. 流式结束后 streamingContent 被清空（避免 UI 重复显示）', () async {
      final analysis = selectAndAnalyze();
      await Future.delayed(const Duration(milliseconds: 50));
      mockRepo.emitChunk('你好');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.state.streamingContent, isNotNull);

      mockRepo.emitDone();
      await analysis;

      expect(controller.state.streamingContent, isNull);
      expect(controller.state.messages.length, equals(2));
      expect(controller.state.isLoading, isFalse);
    });

    test('6. 追问时不会触发第二次初始分析', () async {
      await runAnalysisAndClose();

      final countBefore = mockRepo.callCount;
      final followUp = controller.askQuestion('我的财运如何？');
      await Future.delayed(const Duration(milliseconds: 50));
      mockRepo.emitDone();
      await followUp;

      expect(mockRepo.callCount, equals(countBefore + 1));
    });
  });
}
