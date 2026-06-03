// 文件：首页录入页面
//
// 页面：负责 UI 展示与用户操作。
// 路径：`lib/features/input/presentation/pages/home_input_page.dart`。
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../domain/value_objects/bazi_sect.dart';
import '../../../../domain/value_objects/calendar_type.dart';
import '../../../../domain/value_objects/gender.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../../core/app_strings.dart';
import '../../../history/application/save_bazi_record.dart';
import '../../../reverse_lookup/presentation/pages/reverse_lookup_page.dart';
import '../../../result/presentation/pages/bazi_result_page.dart';
import '../../application/bazi_input_controller.dart';
import '../widgets/birth_place_field.dart';

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

/// 下拉框横向间距；略小于 12 可减少窄屏 Row 子像素溢出。
const _pickerGap = 8.0;

/// 低于此宽度时，三个选择器改为「年单独一行 + 月日一行」。
const _narrowPickerBreakpoint = 400.0;

/// 公历/农历日期行：窄屏堆叠首项，宽屏按 [flexes] 横排。
class _ResponsivePickerRow extends StatelessWidget {
  const _ResponsivePickerRow({
    required this.children,
    this.flexes,
  });

  final List<Widget> children;
  final List<int>? flexes;

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    assert(children.isNotEmpty);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final narrow = maxW < _narrowPickerBreakpoint;

        if (children.length == 3 && narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              children[0],
              const SizedBox(height: _pickerGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: children[1]),
                  const SizedBox(width: _pickerGap),
                  Expanded(child: children[2]),
                ],
              ),
            ],
          );
        }

        if (children.length == 2 && narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              children[0],
              const SizedBox(height: _pickerGap),
              children[1],
            ],
          );
        }

        final flexList = flexes ?? List.filled(children.length, 1);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: _pickerGap),
              Expanded(
                flex: i < flexList.length ? flexList[i] : 1,
                child: children[i],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 类 `HomeInputPage`：实现 Home Input Page 相关逻辑。
class HomeInputPage extends ConsumerStatefulWidget {
  const HomeInputPage({super.key, this.initialPersonName});

  final String? initialPersonName;

  @override
  ConsumerState<HomeInputPage> createState() => _HomeInputPageState();
}

/// 私有类 `_HomeInputPageState`：Home Input Page State。
class _HomeInputPageState extends ConsumerState<HomeInputPage> {
  bool _isSubmitting = false;
  int _formGeneration = 0;
  late final TextEditingController _nameController;
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareForm());
  }

  void _prepareForm() {
    if (!mounted) return;
    final notifier = ref.read(baziInputControllerProvider.notifier);
    if (widget.initialPersonName != null) {
      notifier.setPersonName(widget.initialPersonName!);
      _nameController.text = widget.initialPersonName!;
    } else {
      notifier.resetForNewEntry();
      _nameController.clear();
      setState(() => _formGeneration++);
    }
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(baziInputControllerProvider);
    final controller = ref.read(baziInputControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final isBusy = state.loading || _isSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('排盘录入'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回主页',
          onPressed: isBusy ? null : () => navigateToHomeTab(context, ref),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _dismissKeyboard,
          child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                      key: ValueKey('name-$_formGeneration'),
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      decoration: const InputDecoration(
                        labelText: '姓名',
                        hintText: '请输入姓名（用于记录管理）',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: controller.setPersonName,
                      onFieldSubmitted: (_) => _dismissKeyboard(),
                      onTapOutside: (_) => _dismissKeyboard(),
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
                        _dismissKeyboard();
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
                        _dismissKeyboard();
                        controller.setGender(value.first);
                      },
                    ),
                    const SizedBox(height: 18),
                    BirthPlaceField(
                      key: ValueKey('birth-place-$_formGeneration'),
                      useTrueSolarTime: state.useTrueSolarTime,
                      birthPlaceName: state.birthPlaceName,
                      longitude: state.longitude,
                      clockDateTime: state.solarDateTime,
                      onUseTrueSolarTimeChanged: (v) {
                        _dismissKeyboard();
                        controller.setUseTrueSolarTime(v);
                      },
                      onPlaceSelected: controller.setBirthPlace,
                      onManualLongitudeChanged: controller.setManualLongitude,
                    ),
                    const SizedBox(height: 20),
                    if (state.calendarType == CalendarType.solar)
                      _SolarDropdownPanel(
                        dateTime: state.solarDateTime,
                        onYearChanged: (v) {
                          _dismissKeyboard();
                          controller.setSolarYear(v);
                        },
                        onMonthChanged: (v) {
                          _dismissKeyboard();
                          controller.setSolarMonth(v);
                        },
                        onDayChanged: (v) {
                          _dismissKeyboard();
                          controller.setSolarDay(v);
                        },
                        onHourChanged: (v) {
                          _dismissKeyboard();
                          controller.setSolarHour(v);
                        },
                        onMinuteChanged: (v) {
                          _dismissKeyboard();
                          controller.setSolarMinute(v);
                        },
                        baziSect: state.baziSect,
                        onBaziSectChanged: (v) {
                          _dismissKeyboard();
                          controller.setBaziSect(v);
                        },
                      )
                    else
                      _LunarPanel(
                        lunarYear: state.lunarYear,
                        lunarMonth: state.lunarMonth,
                        lunarDay: state.lunarDay,
                        isLeapMonth: state.isLeapMonth,
                        onYearChanged: (v) {
                          _dismissKeyboard();
                          controller.setLunarYear(v);
                        },
                        onMonthChanged: (v) {
                          _dismissKeyboard();
                          controller.setLunarMonth(v);
                        },
                        onDayChanged: (v) {
                          _dismissKeyboard();
                          controller.setLunarDay(v);
                        },
                        onLeapChanged: (v) {
                          _dismissKeyboard();
                          controller.setLeapMonth(v);
                        },
                        hour: state.solarDateTime.hour,
                        minute: state.solarDateTime.minute,
                        onHourChanged: (v) {
                          _dismissKeyboard();
                          controller.setSolarHour(v);
                        },
                        onMinuteChanged: (v) {
                          _dismissKeyboard();
                          controller.setSolarMinute(v);
                        },
                        baziSect: state.baziSect,
                        onBaziSectChanged: (v) {
                          _dismissKeyboard();
                          controller.setBaziSect(v);
                        },
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: isBusy
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ReverseLookupPage(),
                                ),
                              );
                            },
                      icon: const Icon(Icons.search),
                      label: const Text('八字反查'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isBusy
                          ? null
                          : () async {
                              setState(() => _isSubmitting = true);
                              try {
                                await controller.submit();
                                if (!context.mounted) return;

                                final inputState =
                                    ref.read(baziInputControllerProvider);
                                if (inputState.report != null) {
                                  final outcome = await saveBaziReport(
                                    ref,
                                    report: inputState.report!,
                                    personName: inputState.personName,
                                  );
                                  if (!context.mounted) return;
                                  if (outcome == null &&
                                      ref
                                          .read(authControllerProvider)
                                          .isLoggedIn) {
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
                                              ? AppStrings
                                                  .chartCreatedLoggedIn
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
                                      builder: (_) => const BaziResultPage(
                                        isAutoSaved: true,
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isSubmitting = false);
                                }
                              }
                            },
                      child: Text(isBusy ? '排盘中...' : '开始排盘'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
          if (isBusy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.12),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.loading ? '正在排盘…' : '正在保存命盘…',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.deepGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 私有类 `_ZiHourSectPicker`：Zi Hour Sect Picker。
class _ZiHourSectPicker extends StatelessWidget {
  const _ZiHourSectPicker({
    required this.hour,
    required this.baziSect,
    required this.onBaziSectChanged,
  });

  final int hour;
  final BaziSect baziSect;
  final ValueChanged<BaziSect> onBaziSectChanged;

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    if (!isZiHour(hour)) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('子时流派', style: textTheme.labelMedium),
        const SizedBox(height: 8),
        SegmentedButton<BaziSect>(
          segments: BaziSect.values
              .map((s) => ButtonSegment(value: s, label: Text(s.label)))
              .toList(),
          selected: {baziSect},
          onSelectionChanged: (v) => onBaziSectChanged(v.first),
        ),
        const SizedBox(height: 4),
        Text(
          '23:00–01:00 出生时，日柱按当天或次日',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// 私有类 `_SolarDropdownPanel`：Solar Dropdown Panel。
class _SolarDropdownPanel extends StatelessWidget {
  const _SolarDropdownPanel({
    required this.dateTime,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onDayChanged,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.baziSect,
    required this.onBaziSectChanged,
  });

  final DateTime dateTime;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final BaziSect baziSect;
  final ValueChanged<BaziSect> onBaziSectChanged;

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    final years = _yearRange();
    final months = _monthRange();
    final days = _dayRange(dateTime.year, dateTime.month);
    final hours = _hourRange();
    final minutes = _minuteRange();

    return Column(
      children: [
        _ResponsivePickerRow(
          flexes: const [3, 2, 2],
          children: [
            DropdownButtonFormField<int>(
              key: ValueKey('solar-year-${dateTime.year}'),
              isExpanded: true,
              initialValue: dateTime.year,
              decoration: const InputDecoration(
                labelText: '年',
                isDense: true,
              ),
              items: years
                  .map((y) => DropdownMenuItem(
                      value: y, child: Text('$y年')))
                  .toList(),
              onChanged: (v) {
                if (v != null) onYearChanged(v);
              },
            ),
            DropdownButtonFormField<int>(
              key: ValueKey('solar-month-${dateTime.year}-${dateTime.month}'),
              isExpanded: true,
              initialValue: dateTime.month,
              decoration: const InputDecoration(
                labelText: '月',
                isDense: true,
              ),
              items: months
                  .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(_solarMonthNames[m - 1])))
                  .toList(),
              onChanged: (v) {
                if (v != null) onMonthChanged(v);
              },
            ),
            DropdownButtonFormField<int>(
              key: ValueKey(
                  'solar-day-${dateTime.year}-${dateTime.month}-${days.contains(dateTime.day) ? dateTime.day : days.last}'),
              isExpanded: true,
              initialValue:
                  days.contains(dateTime.day) ? dateTime.day : days.last,
              decoration: const InputDecoration(
                labelText: '日',
                isDense: true,
              ),
              items: days
                  .map((d) => DropdownMenuItem(
                      value: d, child: Text('$d日')))
                  .toList(),
              onChanged: (v) {
                if (v != null) onDayChanged(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ResponsivePickerRow(
          children: [
            DropdownButtonFormField<int>(
              key: ValueKey('solar-hour-${dateTime.hour}'),
              isExpanded: true,
              initialValue: dateTime.hour,
              decoration: const InputDecoration(
                labelText: '时',
                isDense: true,
              ),
              items: hours
                  .map((h) => DropdownMenuItem(
                      value: h,
                      child: Text('${h.toString().padLeft(2, '0')}时')))
                  .toList(),
              onChanged: (v) {
                if (v != null) onHourChanged(v);
              },
            ),
            DropdownButtonFormField<int>(
              key: ValueKey(
                  'solar-minute-${_nearestMinute(dateTime.minute, minutes)}'),
              isExpanded: true,
              initialValue: _nearestMinute(dateTime.minute, minutes),
              decoration: const InputDecoration(
                labelText: '分',
                isDense: true,
              ),
              items: minutes
                  .map((m) => DropdownMenuItem(
                      value: m, child: Text(_minuteLabel(m))))
                  .toList(),
              onChanged: (v) {
                if (v != null) onMinuteChanged(v);
              },
            ),
          ],
        ),
        _ZiHourSectPicker(
          hour: dateTime.hour,
          baziSect: baziSect,
          onBaziSectChanged: onBaziSectChanged,
        ),
      ],
    );
  }
}

/// 私有类 `_LunarPanel`：Lunar Panel。
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
    required this.baziSect,
    required this.onBaziSectChanged,
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
  final BaziSect baziSect;
  final ValueChanged<BaziSect> onBaziSectChanged;

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    final years = _yearRange();
    final months = _monthRange();
    final days = List<int>.generate(30, (i) => i + 1);
    final hours = _hourRange();
    final minutes = _minuteRange();

    return Column(
      children: [
        _ResponsivePickerRow(
          flexes: const [2, 2],
          children: [
            DropdownButtonFormField<int>(
              key: ValueKey('lunar-year-$lunarYear'),
              isExpanded: true,
              initialValue: lunarYear,
              decoration: const InputDecoration(
                labelText: '农历年',
                isDense: true,
              ),
              items: years
                  .map((year) =>
                      DropdownMenuItem(value: year, child: Text('$year')))
                  .toList(),
              onChanged: (value) {
                if (value != null) onYearChanged(value);
              },
            ),
            DropdownButtonFormField<int>(
              key: ValueKey('lunar-month-$lunarYear-$lunarMonth'),
              isExpanded: true,
              initialValue: lunarMonth,
              decoration: const InputDecoration(
                labelText: '农历月',
                isDense: true,
              ),
              items: months
                  .map((month) => DropdownMenuItem(
                      value: month,
                      child: Text(_lunarMonthNames[month - 1])))
                  .toList(),
              onChanged: (value) {
                if (value != null) onMonthChanged(value);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ResponsivePickerRow(
          children: [
            DropdownButtonFormField<int>(
              key: ValueKey('lunar-day-$lunarYear-$lunarMonth-$lunarDay'),
              isExpanded: true,
              initialValue: lunarDay,
              decoration: const InputDecoration(
                labelText: '农历日',
                isDense: true,
              ),
              items: days
                  .map((day) =>
                      DropdownMenuItem(value: day, child: Text('$day')))
                  .toList(),
              onChanged: (value) {
                if (value != null) onDayChanged(value);
              },
            ),
            DropdownButtonFormField<int>(
              key: ValueKey('lunar-hour-$hour'),
              isExpanded: true,
              initialValue: hour,
              decoration: const InputDecoration(
                labelText: '时',
                isDense: true,
              ),
              items: hours
                  .map((h) => DropdownMenuItem(
                      value: h,
                      child: Text('${h.toString().padLeft(2, '0')}时')))
                  .toList(),
              onChanged: (v) {
                if (v != null) onHourChanged(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey('lunar-minute-${_nearestMinute(minute, minutes)}'),
          isExpanded: true,
          initialValue: _nearestMinute(minute, minutes),
          decoration: const InputDecoration(
            labelText: '分',
            isDense: true,
          ),
          items: minutes
              .map((m) => DropdownMenuItem(
                  value: m, child: Text(_minuteLabel(m))))
              .toList(),
          onChanged: (v) {
            if (v != null) onMinuteChanged(v);
          },
        ),
        _ZiHourSectPicker(
          hour: hour,
          baziSect: baziSect,
          onBaziSectChanged: onBaziSectChanged,
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
