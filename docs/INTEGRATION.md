# bazi_core 与生产排盘路径

## 结论

本应用**不**整体替换 `package:lunar` 生产链，而是在 `LunarBaziCalculator` / `LunarLuckCycleCalculator` 上按需补齐 `bazi_core-main` 中已有、且 lunar 已暴露的能力。

| 能力 | 生产实现 | 参考来源 |
|------|----------|----------|
| 四柱 | `LunarBaziCalculator` | lunar `EightChar` |
| 命宫/身宫/胎元/胎息 | `extraPillars` | lunar `getMingGong` 等 |
| 大运/流年/小运 | `LunarLuckCycleCalculator` | lunar `Yun` / `DaYun` / `LiuNian` |
| 流月 | `FlowingMonth` ← `LiuNian.getLiuYue()` | lunar |
| 格局/用神/神煞/刑冲 | 自研 Rule* | 应用独有 |
| 称骨 | `LunarBaziCalculator.calculateBoneWeight` | lunar |

## P3（已接入）

| 能力 | 生产实现 | 说明 |
|------|----------|------|
| 八字反查 | `LunarBaziReverseLookup` + `ReverseLookupPage` | 四柱齐全时用 `Solar.fromBaZi`；否则逐日/五鼠遁补时 |
| 人元司令 | `AstroRenYuanSiLingCalculator` | 节气起算 24 小时一日，常用版分野表；注于月柱 |

## 未接入

- **PreciseFourPillarsCalculator / RealLuckCycleCalculator**：仅作单测基准，与 lunar 对照，不进入 `BuildBaziReportUseCase`。

## 依赖原则

1. 优先调用 lunar 已验证 API，避免复制 `bazi_core` 整表。
2. 领域实体（`BaziChart.extraPillars`、`FlowingYear.flowingMonths`）与 UI 解耦，便于单测。
3. 神煞扫描使用 `chart.allPillars` 语义时，在 `RuleShenshaCalculator` 中显式处理 `extraPillars`，避免漏算。
