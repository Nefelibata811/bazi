// 文件：八字结果页面
//
// 页面：负责 UI 展示与用户操作。
// 路径：`lib/features/result/presentation/pages/bazi_result_page.dart`。
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/app.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/five_element_colors.dart';
import '../../../chart/presentation/widgets/five_element_char.dart';
import '../../../../domain/entities/bazi_chart.dart';
import '../../../../domain/entities/bazi_report.dart';
import '../../../../domain/services/bazi_rule_engine.dart';
import '../../../../domain/value_objects/calendar_precision.dart';
import '../../../../domain/value_objects/calendar_type.dart';
import '../../../../domain/value_objects/gender.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../../core/app_strings.dart';
import '../../../history/application/open_ai_for_record.dart';
import '../../../history/application/save_bazi_record.dart';
import '../../../chart/presentation/widgets/bazi_core_chart_card.dart';
import '../../../chart/presentation/widgets/extra_pillars_card.dart';
import '../../../input/application/bazi_input_controller.dart';
import '../widgets/interaction_card.dart';
import '../widgets/luck_cycle_timeline.dart';
import '../widgets/pattern_card.dart';
import '../widgets/useful_god_card.dart';

const _chartRuleEngine = BaziRuleEngine();

/// 类 `BaziResultPage`：实现 Bazi Result Page 相关逻辑。
class BaziResultPage extends ConsumerStatefulWidget {
  const BaziResultPage({
    super.key,
    this.isFromHistory = false,
    this.isAutoSaved = false,
  });

  final bool isFromHistory;

  /// 排盘提交后已自动保存（主页「开始排盘」流程）。
  final bool isAutoSaved;

  @override
  ConsumerState<BaziResultPage> createState() => _BaziResultPageState();
}

/// 私有类 `_BaziResultPageState`：Bazi Result Page State。
class _BaziResultPageState extends ConsumerState<BaziResultPage> {
  Future<void> _returnToMain({int tabIndex = 0}) async {
    if (tabIndex == 0) {
      await navigateToHomeTab(context, ref);
      return;
    }
    ref.read(mainTabIndexProvider.notifier).state = tabIndex;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_tab_index', tabIndex);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  bool _isSaving = false;
  bool _hasSaved = false;
  bool _isGoingToAi = false;
  DateTime _lastTap = DateTime(2000);

  // 初始化：注册首帧回调、预加载列表数据。

  @override
  void initState() {
    super.initState();
    if (widget.isFromHistory || widget.isAutoSaved) {
      _hasSaved = true;
    }
  }

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(baziInputControllerProvider);
    final report = state.report;
    final textTheme = Theme.of(context).textTheme;

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('排盘结果')),
        body: const Center(child: Text(AppStrings.noChartData)),
      );
    }

    final genderLabel = report.request.gender == Gender.male ? '男' : '女';
    final calendarLabel = report.request.calendarType == CalendarType.solar
        ? '公历'
        : '农历';
    final snapshot = report.calendarSnapshot;
    final chartTime = snapshot.solarDateTime;
    final clockTime = snapshot.clockDateTime ?? chartTime;
    final tst = snapshot.trueSolarTime;
    final lunar = snapshot.lunarDate;
    final dateText = report.request.calendarType == CalendarType.lunar
        ? '农历${lunar.year}年${lunar.month}月${lunar.day}日'
            '（公历${clockTime.year}年${clockTime.month}月${clockTime.day}日）'
        : '${clockTime.year}年${clockTime.month}月${clockTime.day}日';
    final clockTimeText =
        '${clockTime.hour.toString().padLeft(2, '0')}:${clockTime.minute.toString().padLeft(2, '0')}';
    final chartTimeText =
        '${chartTime.hour.toString().padLeft(2, '0')}:${chartTime.minute.toString().padLeft(2, '0')}';
    final timeText = tst != null
        ? '钟表 $clockTimeText · 真太阳时 $chartTimeText'
        : clockTimeText;
    final placeText = report.request.birthPlaceName;

    final precisionLabel = switch (report.calendarSnapshot.precision) {
      CalendarPrecision.exact => '精算',
      CalendarPrecision.approximate => '近似',
      CalendarPrecision.placeholder => '待校准',
    };

    final qiYunCycles = report.luckCycles.where((c) => c.index > 0);
    final startAgeText = qiYunCycles.isNotEmpty
        ? '${qiYunCycles.first.startAge}岁（${qiYunCycles.first.startYear}年）'
        : '--';

    return Scaffold(
      appBar: AppBar(
        title: const Text('排盘结果'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回主界面',
          onPressed: () => _returnToMain(),
        ),
        actions: _buildAppBarActions(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('命主信息', style: textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cinnabar.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        genderLabel,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.cinnabar,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepGray.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        dateText,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      '· $calendarLabel · $precisionLabel',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  timeText,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                ),
                if (placeText != null && placeText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    report.request.useTrueSolarTime
                        ? '出生地 $placeText（东经 ${report.request.longitude?.toStringAsFixed(2) ?? "--"}°）'
                        : '出生地 $placeText',
                    style: textTheme.bodySmall,
                  ),
                ],
                if (tst != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '时辰按真太阳时排盘，较钟表订正 ${tst.totalCorrectionMinutes >= 0 ? "+" : ""}${tst.totalCorrectionMinutes.toStringAsFixed(1)} 分',
                    style: textTheme.bodySmall?.copyWith(color: AppColors.gold),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            BaziCoreChartCard(
              chart: report.chart,
              shenshaItems: report.analysis.shenshaItems,
              renYuanSiLing: report.renYuanSiLing,
            ),
            if (report.chart.extraPillars.isNotEmpty) ...[
              const SizedBox(height: 20),
              ExtraPillarsCard(
                chart: report.chart,
                shenshaItems: report.analysis.shenshaItems,
              ),
            ],
            const SizedBox(height: 20),
            _StemBranchHintCard(chart: report.chart),
            const SizedBox(height: 20),
            if (report.boneWeight != null) ...[
              _BoneWeightCard(
                boneWeight: report.boneWeight!,
                isMale: report.request.gender == Gender.male,
              ),
              const SizedBox(height: 20),
            ],
            LuckCycleTimeline(
              luckCycles: report.luckCycles,
              startAgeText: startAgeText,
            ),
            const SizedBox(height: 20),
            PatternCard(patterns: report.analysis.patterns),
            const SizedBox(height: 20),
            InteractionCard(interactions: report.analysis.interactions),
            const SizedBox(height: 20),
            UsefulGodCard(usefulGod: report.analysis.usefulGod),
            if (_hasSaved || _isSaving) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _returnToMain(),
                icon: const Icon(Icons.home),
                label: Text(
                  widget.isAutoSaved ? '返回主界面' : '返回命主列表',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    final actions = <Widget>[];

    if (!widget.isAutoSaved) {
      actions.add(
        IconButton(
          icon: _isGoingToAi
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_outlined),
          tooltip: 'AI 看盘',
          onPressed: _isGoingToAi ? null : () => _goToAiChat(),
        ),
      );
    }

    if (widget.isAutoSaved || _hasSaved) {
      actions.add(
        TextButton.icon(
          onPressed: () => _returnToMain(),
          icon: Icon(
            widget.isAutoSaved ? Icons.home_outlined : Icons.arrow_back,
            size: 18,
          ),
          label: Text(widget.isAutoSaved ? '返回主界面' : '返回主页'),
          style: TextButton.styleFrom(foregroundColor: AppColors.gold),
        ),
      );
    } else {
      actions.add(
        IconButton(
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          tooltip: '保存排盘',
          onPressed: _isSaving ? null : _onSaveTap,
        ),
      );
    }

    return actions;
  }

  Future<void> _goToAiChat() async {
    if (_isGoingToAi) return;
    _isGoingToAi = true;

    try {
      final state = ref.read(baziInputControllerProvider);
      final report = state.report;
      final user = ref.read(authControllerProvider).user;

      if (report == null || user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.loginRequiredForChart)),
          );
        }
        return;
      }

      final personName =
          state.personName.isNotEmpty ? state.personName : '未命名';

      final existing = findSavedRecord(
        ref,
        report: report,
        personName: personName,
      );
      if (existing != null) {
        await openAiForRecord(context, ref, record: existing);
        return;
      }

      final outcome = await saveBaziReport(
        ref,
        report: report,
        personName: personName,
      );
      if (!mounted) return;
      if (outcome == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.chartSaveFailed)),
        );
        return;
      }
      setState(() => _hasSaved = true);
      await openAiForRecord(context, ref, record: outcome.record);
    } finally {
      if (mounted) {
        _isGoingToAi = false;
      }
    }
  }

  void _onSaveTap() {
    final now = DateTime.now();
    if (now.difference(_lastTap).inMilliseconds < 2000) return;
    _lastTap = now;
    _saveChart();
  }

  Future<void> _saveChart() async {
    if (_isSaving || _hasSaved) return;

    final state = ref.read(baziInputControllerProvider);
    final report = state.report;
    if (report == null) return;

    setState(() => _isSaving = true);

    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.loginRequired)),
        );
      }
      return;
    }

    final personName =
        state.personName.isNotEmpty ? state.personName : '未命名';

    try {
      if (findSavedRecord(ref, report: report, personName: personName) != null) {
        setState(() {
          _isSaving = false;
          _hasSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.chartAlreadySaved)),
        );
        return;
      }

      final outcome = await saveBaziReport(
        ref,
        report: report,
        personName: personName,
      );

      if (!mounted) return;
      if (outcome == null) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.chartSaveFailedRetry)),
        );
        return;
      }
      setState(() {
        _isSaving = false;
        _hasSaved = true;
      });

      final msg = outcome.isNew ? '保存成功' : AppStrings.chartAlreadySaved;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(msg),
            ],
          ),
          backgroundColor: AppColors.gold,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请重试')),
      );
    }
  }
}

/// 私有类 `_StemBranchHintCard`：Stem Branch Hint Card。
class _StemBranchHintCard extends StatelessWidget {
  const _StemBranchHintCard({required this.chart});

  final BaziChart chart;

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pillars = [chart.year, chart.month, chart.day, chart.hour];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('四柱要览', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('天干留意 · 地支留意 · 空亡',
                style: textTheme.bodySmall),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: FiveElementLegend(),
            ),
            ...pillars.map((pillar) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(pillar.label,
                            style: textTheme.titleMedium),
                        const SizedBox(width: 8),
                        FiveElementChar(
                          text: pillar.stem,
                          color: FiveElementColors.byStem(pillar.stem),
                        ),
                        const SizedBox(width: 6),
                        FiveElementChar(
                          text: pillar.branch,
                          color: FiveElementColors.byBranch(pillar.branch),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _HintRow(
                      icon: Icons.wb_sunny_outlined,
                      label: '天干留意',
                      value: '${pillar.stem}（${pillar.stemHint}，十神${pillar.tenGod}）',
                    ),
                    const SizedBox(height: 6),
                    _HintRow(
                      icon: Icons.bedtime_outlined,
                      label: '地支留意',
                      value:
                          '${pillar.branch}（${pillar.branchHint}，藏干${pillar.hiddenStems.map((h) => _chartRuleEngine.stemElementLabel(h.stem)).join('、')}）',
                    ),
                    const SizedBox(height: 6),
                    _HintRow(
                      icon: Icons.nights_stay_outlined,
                      label: '纳音',
                      value: pillar.naYin,
                    ),
                    if (pillar.xunKong.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _HintRow(
                        icon: Icons.hide_source_outlined,
                        label: '空亡',
                        value: pillar.xunKong,
                      ),
                    ],
                    const SizedBox(height: 6),
                    _HintRow(
                      icon: Icons.cyclone_outlined,
                      label: '星运',
                      value: pillar.growthPhase,
                    ),
                    const SizedBox(height: 6),
                    _HintRow(
                      icon: Icons.event_seat_outlined,
                      label: '自坐',
                      value: _chartRuleEngine.growthPhaseFor(
                        dayMasterStem: pillar.stem,
                        branch: pillar.branch,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// 私有类 `_HintRow`：Hint Row。
class _HintRow extends StatelessWidget {
  const _HintRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.deepGray),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(label,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

/// 私有类 `_BoneWeightCard`：Bone Weight Card。
class _BoneWeightCard extends StatelessWidget {
  const _BoneWeightCard({
    required this.boneWeight,
    required this.isMale,
  });

  final BoneWeight boneWeight;
  final bool isMale;

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = boneWeight.weightLabel;
    final comment = boneWeight.commentFor(isMale);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('袁天罡称骨', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('《袁天罡称骨歌》', style: textTheme.bodySmall),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMale
                        ? AppColors.water.withValues(alpha: 0.1)
                        : AppColors.cinnabar.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isMale ? '男命' : '女命',
                    style: textTheme.labelSmall?.copyWith(
                      color: isMale ? AppColors.water : AppColors.cinnabar,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      label,
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('称骨总量',
                        style: textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              comment,
              style: textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

