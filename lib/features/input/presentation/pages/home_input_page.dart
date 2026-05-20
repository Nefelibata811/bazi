import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../domain/value_objects/calendar_type.dart';
import '../../../../domain/value_objects/gender.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../../core/app_strings.dart';
import '../../../history/application/save_bazi_record.dart';
import '../../../result/presentation/pages/bazi_result_page.dart';
import '../../application/bazi_input_controller.dart';

const _lunarMonthNames = [
  '正月', '二月', '三月', '四月', '五月', '六月',
  '七月', '八月', '九月', '十月', '冬月', '腊月',
];

const _solarMonthNames = [
  '1月', '2月', '3月', '4月', '5月', '6月',
  '7月', '8月', '9月', '10月', '11月', '12月',
];

List<int> _yearRange() => List<int>.generate(121, (i) => 2026 - 100 + i);

List<int> _monthRange() => List<int>.generate(12, (i) => i + 1);

List<int> _dayRange(int year, int month) {
  final dayCount = DateTime(year, month + 1, 0).day;
  return List<int>.generate(dayCount, (i) => i + 1);
}

List<int> _hourRange() => List<int>.generate(24, (i) => i);

List<int> _minuteRange() => List<int>.generate(12, (i) => i * 5);

String _minuteLabel(int m) => '${m.toString().padLeft(2, '0')}分';

int _nearestMinute(int actual, List<int> options) {
  return options.lastWhere((m) => m <= actual);
}

class HomeInputPage extends ConsumerWidget {
  const HomeInputPage({super.key, this.initialPersonName});

  final String? initialPersonName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(baziInputControllerProvider);
    final controller = ref.read(baziInputControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    if (initialPersonName != null && state.personName.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setPersonName(initialPersonName!);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('排盘录入'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回主页',
          onPressed: () => navigateToHomeTab(context, ref),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text('命主信息', style: textTheme.headlineSmall),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: state.personName,
                      decoration: const InputDecoration(
                        labelText: '姓名',
                        hintText: '请输入姓名（用于记录管理）',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      onChanged: controller.setPersonName,
                    ),
                    const SizedBox(height: 18),
                    Text('历法', style: textTheme.titleMedium),
                    const SizedBox(height: 10),
                    SegmentedButton<CalendarType>(
                      segments: const [
                        ButtonSegment(
                          value: CalendarType.solar,
                          label: Text('公历'),
                        ),
                        ButtonSegment(
                          value: CalendarType.lunar,
                          label: Text('农历'),
                        ),
                      ],
                      selected: {state.calendarType},
                      onSelectionChanged: (value) {
                        controller.setCalendarType(value.first);
                      },
                    ),
                    const SizedBox(height: 18),
                    Text('性别', style: textTheme.titleMedium),
                    const SizedBox(height: 10),
                    SegmentedButton<Gender>(
                      segments: const [
                        ButtonSegment(
                          value: Gender.male,
                          label: Text('男'),
                        ),
                        ButtonSegment(
                          value: Gender.female,
                          label: Text('女'),
                        ),
                      ],
                      selected: {state.gender},
                      onSelectionChanged: (value) {
                        controller.setGender(value.first);
                      },
                    ),
                    const SizedBox(height: 20),
                    if (state.calendarType == CalendarType.solar)
                      _SolarDropdownPanel(
                        dateTime: state.solarDateTime,
                        onYearChanged: controller.setSolarYear,
                        onMonthChanged: controller.setSolarMonth,
                        onDayChanged: controller.setSolarDay,
                        onHourChanged: controller.setSolarHour,
                        onMinuteChanged: controller.setSolarMinute,
                      )
                    else
                      _LunarPanel(
                        lunarYear: state.lunarYear,
                        lunarMonth: state.lunarMonth,
                        lunarDay: state.lunarDay,
                        isLeapMonth: state.isLeapMonth,
                        onYearChanged: controller.setLunarYear,
                        onMonthChanged: controller.setLunarMonth,
                        onDayChanged: controller.setLunarDay,
                        onLeapChanged: controller.setLeapMonth,
                        hour: state.solarDateTime.hour,
                        minute: state.solarDateTime.minute,
                        onHourChanged: controller.setSolarHour,
                        onMinuteChanged: controller.setSolarMinute,
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: state.loading
                          ? null
                          : () async {
                              await controller.submit();
                              if (!context.mounted) return;

                              final inputState =
                                  ref.read(baziInputControllerProvider);
                              if (inputState.report != null) {
                                final record = await saveBaziReport(
                                  ref,
                                  report: inputState.report!,
                                  personName: inputState.personName,
                                );
                                if (!context.mounted) return;
                                if (record == null && ref
                                        .read(authControllerProvider)
                                        .user !=
                                    null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        AppStrings.chartSaveCloudFailed,
                                      ),
                                    ),
                                  );
                                }
                              }

                              if (context.mounted) {
                                final loggedIn = ref
                                    .read(authControllerProvider)
                                    .isLoggedIn;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text(loggedIn
                                            ? AppStrings.chartCreatedLoggedIn
                                            : AppStrings.chartCreatedGuest),
                                      ],
                                    ),
                                    backgroundColor: AppColors.gold,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.fromLTRB(
                                        20, 0, 20, 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const BaziResultPage(),
                                  ),
                                );
                              }
                            },
                      child: Text(state.loading ? '排盘中...' : '开始排盘'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolarDropdownPanel extends StatelessWidget {
  const _SolarDropdownPanel({
    required this.dateTime,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onDayChanged,
    required this.onHourChanged,
    required this.onMinuteChanged,
  });

  final DateTime dateTime;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;

  @override
  Widget build(BuildContext context) {
    final years = _yearRange();
    final months = _monthRange();
    final days = _dayRange(dateTime.year, dateTime.month);
    final hours = _hourRange();
    final minutes = _minuteRange();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('solar-year-${dateTime.year}'),
                initialValue: dateTime.year,
                decoration: const InputDecoration(labelText: '年'),
                items: years
                    .map((y) => DropdownMenuItem(
                        value: y, child: Text('$y年')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onYearChanged(v);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('solar-month-${dateTime.year}-${dateTime.month}'),
                initialValue: dateTime.month,
                decoration: const InputDecoration(labelText: '月'),
                items: months
                    .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(_solarMonthNames[m - 1])))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onMonthChanged(v);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey(
                    'solar-day-${dateTime.year}-${dateTime.month}-${days.contains(dateTime.day) ? dateTime.day : days.last}'),
                initialValue:
                    days.contains(dateTime.day) ? dateTime.day : days.last,
                decoration: const InputDecoration(labelText: '日'),
                items: days
                    .map((d) => DropdownMenuItem(
                        value: d, child: Text('$d日')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onDayChanged(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('solar-hour-${dateTime.hour}'),
                initialValue: dateTime.hour,
                decoration: const InputDecoration(labelText: '时'),
                items: hours
                    .map((h) => DropdownMenuItem(
                        value: h,
                        child: Text(
                            '${h.toString().padLeft(2, '0')}时')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onHourChanged(v);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey(
                    'solar-minute-${_nearestMinute(dateTime.minute, minutes)}'),
                initialValue: _nearestMinute(dateTime.minute, minutes),
                decoration: const InputDecoration(labelText: '分'),
                items: minutes
                    .map((m) => DropdownMenuItem(
                        value: m, child: Text(_minuteLabel(m))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onMinuteChanged(v);
                },
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

class _LunarPanel extends StatelessWidget {
  const _LunarPanel({
    required this.lunarYear,
    required this.lunarMonth,
    required this.lunarDay,
    required this.isLeapMonth,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onDayChanged,
    required this.onLeapChanged,
    required this.hour,
    required this.minute,
    required this.onHourChanged,
    required this.onMinuteChanged,
  });

  final int lunarYear;
  final int lunarMonth;
  final int lunarDay;
  final bool isLeapMonth;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<bool> onLeapChanged;
  final int hour;
  final int minute;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;

  @override
  Widget build(BuildContext context) {
    final years = _yearRange();
    final months = _monthRange();
    final days = List<int>.generate(30, (i) => i + 1);
    final hours = _hourRange();
    final minutes = _minuteRange();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('lunar-year-$lunarYear'),
                initialValue: lunarYear,
                decoration: const InputDecoration(labelText: '农历年'),
                items: years
                    .map((year) =>
                        DropdownMenuItem(value: year, child: Text('$year')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) onYearChanged(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('lunar-month-$lunarYear-$lunarMonth'),
                initialValue: lunarMonth,
                decoration: const InputDecoration(labelText: '农历月'),
                items: months
                    .map((month) => DropdownMenuItem(
                        value: month,
                        child: Text(_lunarMonthNames[month - 1])))
                    .toList(),
                onChanged: (value) {
                  if (value != null) onMonthChanged(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('lunar-day-$lunarYear-$lunarMonth-$lunarDay'),
                initialValue: lunarDay,
                decoration: const InputDecoration(labelText: '农历日'),
                items: days
                    .map((day) =>
                        DropdownMenuItem(value: day, child: Text('$day')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) onDayChanged(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('lunar-hour-$hour'),
                initialValue: hour,
                decoration: const InputDecoration(labelText: '时'),
                items: hours
                    .map((h) => DropdownMenuItem(
                        value: h,
                        child: Text(
                            '${h.toString().padLeft(2, '0')}时')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onHourChanged(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('lunar-minute-${_nearestMinute(minute, minutes)}'),
                initialValue: _nearestMinute(minute, minutes),
                decoration: const InputDecoration(labelText: '分'),
                items: minutes
                    .map((m) => DropdownMenuItem(
                        value: m, child: Text(_minuteLabel(m))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onMinuteChanged(v);
                },
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: isLeapMonth,
          onChanged: onLeapChanged,
          title: const Text('闰月'),
          subtitle: const Text('仅在该农历年存在闰月时开启'),
        ),
      ],
    );
  }
}
