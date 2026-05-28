// 文件：出生地点field
//
// UI 组件：可复用的界面片段。
// 路径：`lib/features/input/presentation/widgets/birth_place_field.dart`。
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/birth_place.dart';
import '../../../../infrastructure/calendar/astro_true_solar_time_calculator.dart';
import '../../../../infrastructure/geo/china_birth_places.dart';

/// 出生地选择 + 真太阳时开关、手动经度与订正预览。
class BirthPlaceField extends StatefulWidget {
  const BirthPlaceField({
    super.key,
    required this.useTrueSolarTime,
    required this.birthPlaceName,
    required this.longitude,
    required this.clockDateTime,
    required this.onUseTrueSolarTimeChanged,
    required this.onPlaceSelected,
    required this.onManualLongitudeChanged,
  });

  final bool useTrueSolarTime;
  final String? birthPlaceName;
  final double? longitude;
  final DateTime clockDateTime;
  final ValueChanged<bool> onUseTrueSolarTimeChanged;
  final ValueChanged<BirthPlace> onPlaceSelected;
  final ValueChanged<double> onManualLongitudeChanged;

  @override
  State<BirthPlaceField> createState() => _BirthPlaceFieldState();
}

/// 私有类 `_BirthPlaceFieldState`：Birth Place Field State。
class _BirthPlaceFieldState extends State<BirthPlaceField> {
  late final TextEditingController _lonController;

  // 初始化：注册首帧回调、预加载列表数据。

  @override
  void initState() {
    super.initState();
    _lonController = TextEditingController(text: _lonText(widget.longitude));
  }

  @override
  void didUpdateWidget(BirthPlaceField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.longitude != oldWidget.longitude) {
      final next = _lonText(widget.longitude);
      if (_lonController.text != next) {
        _lonController.text = next;
      }
    }
  }

  // 释放监听器与控制器资源。

  @override
  void dispose() {
    _lonController.dispose();
    super.dispose();
  }

  String _lonText(double? lon) =>
      lon == null ? '' : lon.toStringAsFixed(2);

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final correctionPreview = _correctionPreview();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('真太阳时'),
          subtitle: const Text('按出生地经度与均时差订正时辰后再排盘'),
          value: widget.useTrueSolarTime,
          onChanged: widget.onUseTrueSolarTimeChanged,
        ),
        if (widget.useTrueSolarTime) ...[
          const SizedBox(height: 8),
          Autocomplete<BirthPlace>(
            displayStringForOption: (p) => p.displayLabel,
            optionsBuilder: (query) {
              final text = query.text.trim();
              if (text.isEmpty) {
                return ChinaBirthPlaces.hotCities;
              }
              return ChinaBirthPlaces.search(text);
            },
            initialValue: TextEditingValue(
              text: widget.birthPlaceName ??
                  ChinaBirthPlaces.defaultPlace.displayLabel,
            ),
            onSelected: widget.onPlaceSelected,
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: '出生地点',
                  hintText: '搜索省 / 市 / 区县，如：海淀、义乌、喀什',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                onFieldSubmitted: (_) => onSubmitted(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 240, maxWidth: 400),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final place = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          title: Text(place.displayLabel),
                          subtitle: Text(
                            '东经 ${place.longitude.toStringAsFixed(2)}°',
                            style: textTheme.bodySmall,
                          ),
                          onTap: () => onSelected(place),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lonController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: const InputDecoration(
              labelText: '手动东经（°）',
              hintText: '73–135，海外或库中无地点时可填',
              prefixIcon: Icon(Icons.explore_outlined),
              helperText: '修改后失焦生效；与上方地点二选一或覆盖经度',
            ),
            onFieldSubmitted: (_) => _applyManualLongitude(),
            onEditingComplete: _applyManualLongitude,
          ),
          if (correctionPreview != null) ...[
            const SizedBox(height: 8),
            Text(
              correctionPreview,
              style: textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ],
        ],
      ],
    );
  }

  void _applyManualLongitude() {
    final raw = _lonController.text.trim();
    if (raw.isEmpty) return;
    final value = double.tryParse(raw);
    if (value == null || value < 73 || value > 135) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('东经请填写 73–135 之间的数字')),
      );
      return;
    }
    widget.onManualLongitudeChanged(value);
  }

  String? _correctionPreview() {
    final lon = widget.longitude;
    if (!widget.useTrueSolarTime || lon == null) return null;
    const calc = AstroTrueSolarTimeCalculator();
    final info = calc.computeInfo(
      clockLocal: widget.clockDateTime,
      longitude: lon,
      birthPlaceName: widget.birthPlaceName ?? '当地',
    );
    final trueDt = info.trueSolarDateTime;
    final trueText =
        '${trueDt.hour.toString().padLeft(2, '0')}:${trueDt.minute.toString().padLeft(2, '0')}';
    final clockText =
        '${widget.clockDateTime.hour.toString().padLeft(2, '0')}:${widget.clockDateTime.minute.toString().padLeft(2, '0')}';
    final total = info.totalCorrectionMinutes;
    final sign = total >= 0 ? '+' : '';
    return '钟表 $clockText → 真太阳时 $trueText（订正 $sign${total.toStringAsFixed(1)} 分）';
  }
}
