// 文件：干支选择器
//
// UI 组件：可复用的界面片段。
// 路径：`lib/features/reverse_lookup/presentation/widgets/gan_zhi_picker.dart`。
//
import 'package:flutter/material.dart';

const ganList = '甲乙丙丁戊己庚辛壬癸';
const zhiList = '子丑寅卯辰巳午未申酉戌亥';

/// 类 `GanZhiPicker`：实现 Gan Zhi Picker 相关逻辑。
class GanZhiPicker extends StatelessWidget {
  const GanZhiPicker({
    super.key,
    required this.label,
    required this.ganZhi,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String? ganZhi;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  // 构建界面布局。

  @override
  Widget build(BuildContext context) {
    final stem = ganZhi != null && ganZhi!.isNotEmpty ? ganZhi![0] : null;
    final branch =
        ganZhi != null && ganZhi!.length >= 2 ? ganZhi![1] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: stem,
                decoration: const InputDecoration(labelText: '干'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  ...ganList.split('').map(
                        (g) => DropdownMenuItem(value: g, child: Text(g)),
                      ),
                ],
                onChanged: enabled
                    ? (g) {
                        if (g == null) {
                          onChanged(null);
                        } else {
                          onChanged('$g${branch ?? '子'}');
                        }
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: branch,
                decoration: const InputDecoration(labelText: '支'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  ...zhiList.split('').map(
                        (z) => DropdownMenuItem(value: z, child: Text(z)),
                      ),
                ],
                onChanged: enabled
                    ? (z) {
                        if (z == null) {
                          onChanged(null);
                        } else {
                          onChanged('${stem ?? '甲'}$z');
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
