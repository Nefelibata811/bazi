// 文件：反查lookup页面
//
// 页面：负责 UI 展示与用户操作。
// 路径：`lib/features/reverse_lookup/presentation/pages/reverse_lookup_page.dart`。
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/bazi_reverse_candidate.dart';
import '../../../../domain/entities/bazi_reverse_query.dart';
import '../../../../domain/services/bazi_reverse_lookup.dart';
import '../../../../domain/value_objects/bazi_sect.dart';
import '../../../../domain/value_objects/gender.dart';
import '../../../../infrastructure/calendar/lunar_bazi_reverse_lookup.dart';
import '../../../input/application/bazi_input_controller.dart';
import '../../../result/presentation/pages/bazi_result_page.dart';
import '../widgets/gan_zhi_picker.dart';

final baziReverseLookupProvider = Provider<BaziReverseLookup>(
  (ref) => const LunarBaziReverseLookup(),
);

/// 类 `ReverseLookupPage`：实现 Reverse Lookup Page 相关逻辑。
class ReverseLookupPage extends ConsumerStatefulWidget {
  const ReverseLookupPage({super.key});

  @override
  ConsumerState<ReverseLookupPage> createState() => _ReverseLookupPageState();
}

/// 私有类 `_ReverseLookupPageState`：Reverse Lookup Page State。
class _ReverseLookupPageState extends ConsumerState<ReverseLookupPage> {
  String? _yearGz = '甲子';
  String? _monthGz;
  String? _dayGz;
  String? _timeGz;
  int _startYear = 1950;
  int _endYear = 2030;
  Gender _gender = Gender.male;
  BaziSect _baziSect = BaziSect.sameDay;
  bool _searching = false;
  List<BaziReverseCandidate> _results = const [];
  String? _error;

  Future<void> _search() async {
    if (_yearGz == null || _yearGz!.length != 2) {
      setState(() => _error = '请至少选择年柱干支');
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
      _results = const [];
    });

    try {
      final lookup = ref.read(baziReverseLookupProvider);
      final list = await lookup.search(
        BaziReverseQuery(
          yearGanZhi: _yearGz!,
          monthGanZhi: _monthGz,
          dayGanZhi: _dayGz,
          timeGanZhi: _timeGz,
          startYear: _startYear,
          endYear: _endYear,
          gender: _gender,
          baziSect: _baziSect,
        ),
      );
      if (!mounted) return;
      setState(() {
        _results = list;
        _searching = false;
        if (list.isEmpty) _error = '未找到匹配日期，可放宽条件或扩大年份范围';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _useCandidate(BaziReverseCandidate candidate) async {
    final input = ref.read(baziInputControllerProvider.notifier);
    await input.applyFromReverseCandidate(candidate);
    if (!mounted) return;
    final report = ref.read(baziInputControllerProvider).report;
    if (report == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BaziResultPage(
          isAutoSaved: false,
        ),
      ),
    );
  }

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final years = List<int>.generate(151, (i) => 1900 + i);

    return Scaffold(
      appBar: AppBar(title: const Text('八字反查')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              '输入已知四柱干支，反推可能的公历出生时刻。年柱必填；月、日、时可逐步收窄。',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.deepGray),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    GanZhiPicker(
                      label: '年柱 *',
                      ganZhi: _yearGz,
                      onChanged: (v) => setState(() => _yearGz = v),
                    ),
                    const SizedBox(height: 14),
                    GanZhiPicker(
                      label: '月柱（可选）',
                      ganZhi: _monthGz,
                      onChanged: (v) => setState(() => _monthGz = v),
                    ),
                    const SizedBox(height: 14),
                    GanZhiPicker(
                      label: '日柱（可选）',
                      ganZhi: _dayGz,
                      onChanged: (v) => setState(() => _dayGz = v),
                    ),
                    const SizedBox(height: 14),
                    GanZhiPicker(
                      label: '时柱（可选）',
                      ganZhi: _timeGz,
                      onChanged: (v) => setState(() => _timeGz = v),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _startYear,
                            decoration: const InputDecoration(labelText: '起始年'),
                            items: years
                                .map((y) => DropdownMenuItem(
                                      value: y,
                                      child: Text('$y'),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _startYear = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _endYear,
                            decoration: const InputDecoration(labelText: '结束年'),
                            items: years
                                .map((y) => DropdownMenuItem(
                                      value: y,
                                      child: Text('$y'),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _endYear = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<Gender>(
                      segments: const [
                        ButtonSegment(value: Gender.male, label: Text('男')),
                        ButtonSegment(value: Gender.female, label: Text('女')),
                      ],
                      selected: {_gender},
                      onSelectionChanged: (v) =>
                          setState(() => _gender = v.first),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<BaziSect>(
                      segments: BaziSect.values
                          .map(
                            (s) => ButtonSegment(
                              value: s,
                              label: Text(s.label, style: const TextStyle(fontSize: 12)),
                            ),
                          )
                          .toList(),
                      selected: {_baziSect},
                      onSelectionChanged: (v) =>
                          setState(() => _baziSect = v.first),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _searching ? null : _search,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _searching
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('开始反查'),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: textTheme.bodySmall?.copyWith(color: AppColors.cinnabar)),
            ],
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('候选 ${_results.length} 条', style: textTheme.titleMedium),
              const SizedBox(height: 10),
              ..._results.map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(c.dateLabel),
                    subtitle: Text(c.ganZhiLine),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _useCandidate(c),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
