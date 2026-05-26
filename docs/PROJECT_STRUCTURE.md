# 八字排盘 App — 项目结构与说明

> 工程根目录：`d:\bazi app\bazi`（含 `pubspec.yaml` 的 Flutter 工程）  
> 上级目录 `d:\bazi app` 可能还包含脚本、文档等，**以 `bazi/` 为 App 本体**。

---

## 1. 技术框架（重点）

| 层级 | 技术 | 作用 |
|------|------|------|
| **UI 框架** | [Flutter](https://flutter.dev) 3.x | 跨平台界面（Android / Web / Windows） |
| **语言** | Dart 3.4+ | 业务与 UI 逻辑 |
| **状态管理** | [Riverpod](https://riverpod.dev) 2.x | `Provider` / `StateNotifier` / `Notifier`，依赖注入与页面状态 |
| **架构风格** | **分层 + Feature 模块化** | `domain`（领域）← `infrastructure`（实现）← `features`（功能 UI） |
| **农历排盘** | [lunar](https://pub.dev/packages/lunar) | 四柱、大运、命宫身宫等历法数据 |
| **后端 / 云** | [Supabase](https://supabase.com) | 登录、命盘记录云端存储 |
| **AI 看盘** | DeepSeek API（HTTP） | 流式对话，密钥经 `--dart-define` 注入 |
| **本地缓存** | `shared_preferences` | Tab 索引、登录偏好、记录列表缓存等 |

**不属于本项目的框架：** 无 React/Vue；无 GetX/Bloc（选用 Riverpod）；无服务端自研后端（业务 API 主要是 Supabase + DeepSeek）。

---

## 2. 目录总览

```
bazi/
├── lib/                    # ★ 全部 Dart 源码（核心）
│   ├── main.dart           # ★ 程序入口
│   ├── app/                # ★ 应用壳：主题、路由、启动
│   ├── core/               # 配置、文案、工具（无 UI）
│   ├── domain/             # ★ 领域层：实体、用例、抽象接口
│   ├── infrastructure/     # ★ 基础设施：算法实现、Supabase、AI
│   └── features/           # ★ 功能模块：按业务划分的 UI + Controller
├── android/                # Android 原生工程（Gradle）
├── web/                    # Web 部署
├── test/                   # 单元 / Widget 测试
├── scripts/                # ★ 开发脚本（运行、打包、密钥同步）
├── docs/                   # 文档（本文档、算法、Android 指南等）
├── assets/                 # 图标等资源
├── pubspec.yaml            # ★ 依赖与版本
└── secrets.local.env       # 本地密钥（勿提交 Git）
```

---

## 3. 启动与导航流程（重点）

```
main.dart
  └─ ProviderScope（Riverpod 根）
       └─ BootstrapApp          # 后台初始化 Supabase，避免首屏白屏
            └─ BaziApp / MaterialApp
                 ├─ 未登录 → LoginPage
                 └─ 已登录 → _MainShell（底部双 Tab）
                      ├─ Tab0: PeopleListPage（命主列表 + 合集入口）
                      └─ Tab1: ChatPage（AI 看盘）
```

**命名路由（`app.dart` → `onGenerateRoute`）：**

| 路由 | 页面 | 说明 |
|------|------|------|
| `/input` | 排盘录入 | 新建八字 |
| `/history` | 排盘记录列表 | |
| `/collections` | 命盘合集 | |
| `/collection_detail` | 合集详情 | |
| `/profile` | 个人信息 | |
| `/reverse_lookup` | 八字反查 | |
| 排盘结果 | `BaziResultPage` | 多由 `Navigator.push` 进入，非具名路由 |

---

## 4. `lib/` 各层说明

### 4.1 `lib/main.dart` — 程序入口

- 初始化 Flutter 绑定
- 注册全局错误日志
- 挂载 `ProviderScope` + `BootstrapApp`

### 4.2 `lib/app/` — 应用壳

| 文件/目录 | 作用 |
|-----------|------|
| `bootstrap_app.dart` | **重点**：异步 `Supabase.initialize`，完成后通知 `AuthController` |
| `app.dart` | `MaterialApp`、登录态切换首页、`onGenerateRoute`、`_MainShell`（IndexedStack 保 Tab 状态） |
| `theme/` | 中国风配色 `AppColors`、主题 `AppTheme`、排盘字体 `AppFonts` / `BaziChartTextStyles` |
| `widgets/app_splash.dart` | 恢复 Session 时的启动页 |

### 4.3 `lib/core/` — 横切配置（无业务 UI）

| 文件 | 作用 |
|------|------|
| `api_config.dart` | 从编译期环境读取 `SUPABASE_*`、`DEEPSEEK_API_KEY` |
| `app_secrets.dart` | 封装密钥访问 |
| `app_strings.dart` | 用户可见固定文案 |
| `auth_messages.dart` | 登录/注册错误文案映射 |
| `debug_log.dart` | 调试日志 |

### 4.4 `lib/domain/` — 领域层（重点，不依赖 Flutter UI）

**原则：** 只放业务概念与抽象；不 import `package:flutter`。

#### `domain/entities/` — 数据模型

| 实体 | 说明 |
|------|------|
| `bazi_request.dart` | 排盘请求：公历/农历、性别、时辰、子时流派等 |
| `bazi_chart.dart` | 四柱盘 + 命宫/身宫/胎元/胎息 |
| `pillar.dart` | 单柱：干支、十神、藏干、纳音、星运、自坐、空亡 |
| `bazi_report.dart` | 完整报告：盘 + 分析 + 大运 + 称骨等 |
| `bazi_record.dart` | 云端/本地一条保存记录 |
| `luck_cycle.dart` / `flowing_year.dart` | 大运、流年 |
| `bazi_reverse_*` | 反查候选与查询 |

#### `domain/value_objects/` — 值对象

如 `Gender`、`CalendarType`、`BaziSect`（子时换日）、`FiveElement` 等。

#### `domain/services/` — 抽象接口（端口）

| 接口 | 实现位置（infrastructure） |
|------|---------------------------|
| `BaziCalculator` | `lunar_bazi_calculator.dart` |
| `BaziRuleEngine` | 规则表：十神、纳音、十二长生、藏干 |
| `LuckCycleCalculator` | `lunar_luck_cycle_calculator.dart` |
| `ShenshaCalculator` | `rule_shensha_calculator.dart` |
| `PatternAnalyzer` / `UsefulGodAnalyzer` | `rule_pattern_analyzer.dart` 等 |
| `AuthRepository` / `BaziRecordRepository` | `supabase_*_repository.dart` |
| `BaziReverseLookup` | `lunar_bazi_reverse_lookup.dart` |

#### `domain/usecases/` — 用例（编排）

| 用例 | **重点** |
|------|----------|
| `BuildBaziChartUseCase` | 请求 → `BaziChart` |
| `AnalyzeBaziUseCase` | 格局、神煞、用神 |
| `BuildBaziReportUseCase` | **总编排**：历法 → 四柱 → 大运 → 分析 → `BaziReport` |

---

### 4.5 `lib/infrastructure/` — 基础设施实现

#### `infrastructure/calendar/` — **排盘算法核心（重点）**

| 文件 | 作用 |
|------|------|
| `lunar_eight_char_factory.dart` | 从 `BaziRequest` 构造 lunar `EightChar` |
| `lunar_bazi_calculator.dart` | **四柱主实现**：年/月/日/时 + 辅柱 |
| `lunar_luck_cycle_calculator.dart` | 大运起运、干支 |
| `rule_shensha_calculator.dart` | 神煞规则 |
| `rule_pattern_analyzer.dart` | 格局 |
| `rule_useful_god_analyzer.dart` | 用神 |
| `interaction_calculator.dart` | 刑冲合害等 |
| `lunar_bazi_reverse_lookup.dart` | 八字反查 |
| `astro_ren_yuan_si_ling_calculator.dart` | 人元司令 |
| `precise_four_pillars_calculator.dart` | 儒略日等精确推算（辅助/测试） |

#### `infrastructure/database/` — Supabase

| 文件 | 作用 |
|------|------|
| `supabase_auth_repository.dart` | 邮箱/手机登录、注册、头像 |
| `supabase_bazi_record_repository.dart` | 命盘 CRUD |
| `inactive_auth_repository.dart` | Supabase 未就绪时的空实现 |

#### `infrastructure/ai/`

DeepSeek 流式聊天请求封装。

---

### 4.6 `lib/features/` — 功能模块（Feature-First）

每个 feature 常见结构：

```
features/<name>/
  application/     # Riverpod Controller / Notifier（状态与用例调用）
  presentation/    # 页面 pages/、组件 widgets/
  infrastructure/  # 仅本 feature 的编解码、平台回调等
```

#### `features/auth/` — 登录注册（重点）

| 部分 | 作用 |
|------|------|
| `auth_controller.dart` | 登录态、`logout`、`onSupabaseReady`、手机验证码 |
| `presentation/pages/` | login / register / profile / reset_password |
| `infrastructure/` | Web 端 OAuth 回调处理 |

#### `features/input/` — 排盘录入（重点）

| 部分 | 作用 |
|------|------|
| `bazi_input_controller.dart` | 表单状态、调用 `BuildBaziReportUseCase` |
| `home_input_page.dart` | 录入 UI → 跳转 `BaziResultPage` |

#### `features/chart/` — 四柱展示 UI

| 部分 | 作用 |
|------|------|
| `bazi_core_chart_card.dart` | **表格式四柱**（主星/干支/藏干/副星/星运/自坐/神煞） |
| `extra_pillars_card.dart` | 命宫、身宫、胎元、胎息 |

#### `features/result/` — 排盘结果页（重点）

| 部分 | 作用 |
|------|------|
| `bazi_result_page.dart` | 汇总展示盘、大运、格局、保存、跳转 AI |
| `widgets/` | 大运时间轴、格局卡、用神、互动等 |

#### `features/history/` — 命主与记录（重点）

| 部分 | 作用 |
|------|------|
| `bazi_records_list_controller.dart` | 命主列表 `keepAlive` 预加载 |
| `collections_list_controller.dart` | 合集列表预加载 |
| `save_bazi_record.dart` | 保存到 Supabase + 去重逻辑 |
| `person_identity.dart` | 同一命主去重 |
| `people_list_page.dart` | 主页 Tab0 |
| `chart_history_page.dart` | 历史记录 |

#### `features/collection/` — 命盘合集

合集 CRUD、合集内记录关联。

#### `features/ai_chat/` — AI 看盘（重点）

| 部分 | 作用 |
|------|------|
| `chat_controller.dart` | 选盘、拼 prompt、流式回复 |
| `chat_page.dart` | 主页 Tab1 |

#### `features/reverse_lookup/` — 八字反查

按四柱反查可能的公历时间。

---

## 5. `scripts/` 脚本（重点）

| 脚本 | 用途 |
|------|------|
| `sync_dart_defines.ps1` | `secrets.local.env` → `.dart_defines.generated.json` |
| `run_android.ps1` | 调试运行 Android（含密钥、关 Impeller） |
| `restart_android.ps1` | 启模拟器 + run |
| `start_emulator.ps1` | 启动 `Pixel_6_API_35` |
| `build_android_release.ps1` | **Release APK** |
| `build_android.ps1` | Debug APK |
| `run_web.ps1` | Web 调试 |

详见 `docs/ANDROID_DEV.md`、`docs/WEB_DEV.md`。

---

## 6. 密钥与编译配置（重点）

1. 复制 `secrets.example.env` → `secrets.local.env`
2. 填写 `SUPABASE_URL`、`SUPABASE_ANON_KEY`、`DEEPSEEK_API_KEY`
3. 运行前执行 `.\scripts\sync_dart_defines.ps1`
4. 使用 `--dart-define-from-file=.dart_defines.generated.json` 启动/打包

**切勿将 `secrets.local.env` 提交到 Git。**

---

## 7. 数据流：一次完整排盘（重点）

```
HomeInputPage 点击「开始排盘」
  → BaziInputController.submit()
  → BuildBaziReportUseCase.call(BaziRequest)
       ├─ CalendarConverter  → 统一公历时刻
       ├─ BuildBaziChartUseCase → LunarBaziCalculator → BaziChart
       ├─ LuckCycleCalculator → 大运
       ├─ AnalyzeBaziUseCase → 格局/神煞/用神
       └─ 组装 BaziReport
  → Navigator → BaziResultPage 展示
  → 可选 SaveBaziReport → SupabaseBaziRecordRepository
```

---

## 8. 测试

| 目录 | 内容 |
|------|------|
| `test/units/` | 规则引擎、四柱、神煞、大运等算法单测 |
| `test/widget/` | 少量 Widget 测试 |

运行：`flutter test`

---

## 9. 相关文档索引

| 文档 | 主题 |
|------|------|
| [ALGORITHMS.md](./ALGORITHMS.md) | 算法说明 |
| [ANDROID_DEV.md](./ANDROID_DEV.md) | 模拟器与调试 |
| [ANDROID_STUDIO_APK.md](./ANDROID_STUDIO_APK.md) | Android Studio 打包 |
| [WEB_DEV.md](./WEB_DEV.md) | Web 开发 |
| [INTEGRATION.md](./INTEGRATION.md) | 集成说明 |

---

## 10. 维护建议

- **改排盘逻辑**：优先 `infrastructure/calendar/` + `domain/services/bazi_rule_engine.dart`
- **改 UI 展示**：对应 `features/*/presentation/`
- **改登录/云存储**：`features/auth` + `infrastructure/database/`
- **新增功能**：在 `features/` 下新建模块，用例放 `domain/usecases/`，通过 Riverpod 在 `application/` 注入

---

*文档随代码演进更新；若目录有增删，以 `lib/` 实际结构为准。*
