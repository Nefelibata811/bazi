import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/bazi_chart.dart';
import '../../../../domain/entities/bazi_report.dart';
import '../../../../domain/entities/pillar.dart';
import '../../../../domain/value_objects/calendar_precision.dart';
import '../../../../domain/value_objects/calendar_type.dart';
import '../../../../domain/value_objects/gender.dart';
import '../../../../infrastructure/database/supabase_bazi_record_repository.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../chart/presentation/widgets/bazi_core_chart_card.dart';
import '../../../history/presentation/pages/people_list_page.dart';
import '../../../input/application/bazi_input_controller.dart';
import '../widgets/luck_cycle_timeline.dart';
import '../widgets/pattern_card.dart';
import '../widgets/shensha_card.dart';
import '../widgets/useful_god_card.dart';

class BaziResultPage extends ConsumerStatefulWidget {
  const BaziResultPage({super.key, this.isFromHistory = false});

  final bool isFromHistory;

  @override
  ConsumerState<BaziResultPage> createState() => _BaziResultPageState();
}

class _BaziResultPageState extends ConsumerState<BaziResultPage> {
  bool _isSaving = false;
  bool _hasSaved = false;
  DateTime _lastTap = DateTime(2000);

  @override
  void initState() {
    super.initState();
    if (widget.isFromHistory) {
      _hasSaved = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(baziInputControllerProvider);
    final report = state.report;
    final textTheme = Theme.of(context).textTheme;

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('排盘结果')),
        body: const Center(child: Text('暂无排盘数据')),
      );
    }

    final genderLabel = report.request.gender == Gender.male ? '男' : '女';
    final calendarLabel = report.request.calendarType == CalendarType.solar
        ? '公历'
        : '农历';
    final birthDate = report.calendarSnapshot.solarDateTime;
    final dateText =
        '${birthDate.year}年${birthDate.month}月${birthDate.day}日';
    final timeText =
        '${birthDate.hour.toString().padLeft(2, '0')}:${birthDate.minute.toString().padLeft(2, '0')}';

    final precisionLabel = switch (report.calendarSnapshot.precision) {
      CalendarPrecision.exact => '精算',
      CalendarPrecision.approximate => '近似',
      CalendarPrecision.placeholder => '待校准',
    };

    final firstCycle =
        report.luckCycles.isNotEmpty ? report.luckCycles.first : null;
    final startAgeText = firstCycle != null
        ? '${firstCycle.startAge}岁（${firstCycle.startYear}年）'
        : '--';

    return Scaffold(
      appBar: AppBar(
        title: const Text('排盘结果'),
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
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cinnabar.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(genderLabel, style: textTheme.labelMedium?.copyWith(color: AppColors.cinnabar)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.deepGray.withOpacity(0.06), borderRadius: BorderRadius.circular(999)),
                    child: Text('$dateText $timeText', style: textTheme.labelMedium?.copyWith(color: AppColors.ink)),
                  ),
                  const SizedBox(width: 8),
                  Text('· $calendarLabel · $precisionLabel', style: textTheme.bodySmall),
                ]),
              ],
            ),
            const SizedBox(height: 20),
            BaziCoreChartCard(chart: report.chart),
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
            UsefulGodCard(usefulGod: report.analysis.usefulGod),
            const SizedBox(height: 20),
            ShenshaCard(shenshaItems: report.analysis.shenshaItems),
            if (_hasSaved || _isSaving) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (_) => false);
                },
                icon: const Icon(Icons.home),
                label: const Text('返回命主列表'),
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
    if (_hasSaved) {
      return [
        TextButton.icon(
          onPressed: () {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (_) => false);
          },
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('返回主页'),
          style: TextButton.styleFrom(foregroundColor: AppColors.gold),
        ),
      ];
    }

    return [
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
    ];
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
          const SnackBar(content: Text('请先登录')),
        );
      }
      return;
    }

    final personName =
        state.personName.isNotEmpty ? state.personName : '未命名';

    try {
      final repo = SupabaseBaziRecordRepository(Supabase.instance.client);
      final reqJson = jsonEncode({
        'calendarType': report.request.calendarType == CalendarType.lunar
            ? 'lunar'
            : 'solar',
        'gender':
            report.request.gender == Gender.female ? 'female' : 'male',
        'solarDateTime': report.request.solarDateTime.toIso8601String(),
        'lunarYear': report.request.lunarYear,
        'lunarMonth': report.request.lunarMonth,
        'lunarDay': report.request.lunarDay,
        'isLeapMonth': report.request.isLeapMonth,
        'personName': personName,
      });
      final repJson = jsonEncode({
        'dayMaster': report.chart.dayMaster,
        'year': {'stem': report.chart.year.stem, 'branch': report.chart.year.branch},
        'month': {'stem': report.chart.month.stem, 'branch': report.chart.month.branch},
        'day': {'stem': report.chart.day.stem, 'branch': report.chart.day.branch},
        'hour': {'stem': report.chart.hour.stem, 'branch': report.chart.hour.branch},
      });
      await repo.save(
        userId: user.id,
        personName: personName,
        requestJson: reqJson,
        reportJson: repJson,
      );

      if (!mounted) return;
      ref.read(refreshPeopleListProvider.notifier).state++;
      setState(() {
        _isSaving = false;
        _hasSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('保存成功'),
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

class _StemBranchHintCard extends StatelessWidget {
  const _StemBranchHintCard({required this.chart});

  final BaziChart chart;

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
            ...pillars.map((pillar) {
              final stemColor =
                  AppColors.fiveElementByStem(pillar.stem);
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
                        const SizedBox(width: 10),
                        Text(
                          pillar.stem,
                          style: textTheme.headlineSmall?.copyWith(
                              color: stemColor),
                        ),
                        const SizedBox(width: 6),
                        Text(pillar.branch,
                            style: textTheme.headlineSmall),
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
                      value: '${pillar.branch}（${pillar.branchHint}，藏干${pillar.hiddenStems.map((h) => h.stem).join('、')}）',
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
                      label: '长生',
                      value: pillar.growthPhase,
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

class _HintRow extends StatelessWidget {
  const _HintRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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

class _BoneWeightCard extends StatelessWidget {
  const _BoneWeightCard({
    required this.boneWeight,
    required this.isMale,
  });

  final BoneWeight boneWeight;
  final bool isMale;

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
                        ? AppColors.water.withOpacity(0.1)
                        : AppColors.cinnabar.withOpacity(0.1),
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
                  color: AppColors.gold.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.gold.withOpacity(0.2)),
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
