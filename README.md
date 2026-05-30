# 八字排盘 · BaZi Chart

<p align="center">
  <img src="assets/icon/app_icon.png" alt="App Icon" width="88" /><br/>
  <em>Chinese BaZi charting app with AI-powered readings</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Supabase-Auth%20%26%20DB-3FCF8E?logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/AI-DeepSeek-blueviolet" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Web-lightgrey" />
</p>

<p align="center">
  录入生辰 → 生成命盘 → 规则分析 → AI 解读 · 云端同步 · 命盘合集
</p>

---

## 目录

- [项目简介](#项目简介)
- [界面预览](#界面预览)
- [功能一览](#功能一览)
- [技术架构](#技术架构)
- [本地运行](#本地运行)
- [文档](#文档)
- [声明](#声明)

---

## 项目简介

**八字排盘** 是一款中式极简风格的命理应用。用户输入出生信息后即可获得完整八字命盘，包括四柱、大运流年、用神格局、神煞与刑冲合害等分析；登录账号后，还可对任意已保存命盘发起 **AI 流式解读**，并跨设备同步数据。

本项目由个人独立开发并开源，涵盖 **Flutter 客户端、历法算法、Supabase 后端与大模型集成**，可作为移动端 + 领域建模 + AI 应用的参考实现。

---

## 界面预览

### 登录与录入

| 登录 | 排盘录入 |
|:---:|:---:|
| <a href="docs/screenshots/login.png"><img src="docs/screenshots/login.png" width="280" alt="登录" /></a> | <a href="docs/screenshots/input.png"><img src="docs/screenshots/input.png" width="280" alt="排盘录入" /></a> |
| 邮箱 / 手机验证码登录 | 公历农历 · 真太阳时 · 八字反查 |

### 主页

<p align="center">
  <a href="docs/screenshots/home.png">
    <img src="docs/screenshots/home.png" width="280" alt="命主列表" />
  </a>
</p>
<p align="center"><sub>命盘合集 · 保存记录 · 一键进入 AI 看盘</sub></p>

### 排盘结果

<p align="center">
  <a href="docs/screenshots/result_part.jpg"><img src="docs/screenshots/result_part.jpg" width="400" alt="排盘结果" /></a>
</p>
<p align="center"><sub>四柱 · 大运 · 神煞 · 刑冲合害 · 用神格局</sub></p>

### AI 看盘

| 选盘入口 | 选择命盘 |
|:---:|:---:|
| <a href="docs/screenshots/ai_select.png"><img src="docs/screenshots/ai_select.png" width="280" alt="AI 选盘" /></a> | <a href="docs/screenshots/picker.png"><img src="docs/screenshots/picker.png" width="280" alt="选择排盘" /></a> |

<p align="center">
  <a href="docs/screenshots/ai_chat.jpg"><img src="docs/screenshots/ai_chat.jpg" width="400" alt="AI 对话" /></a>
</p>
<p align="center"><sub>流式解读 · 追问 · 历史恢复</sub></p>

---

## 功能一览

### 排盘与分析

| 功能 | 说明 |
|------|------|
| 生辰录入 | 公历 / 农历、性别、出生地与真太阳时 |
| 八字命盘 | 四柱、藏干、纳音、大运、流年、流月 |
| 辅宫展示 | 命宫、身宫、胎元、胎息 |
| 规则引擎 | 用神、格局、神煞、刑冲合害 |
| 八字反查 | 已知四柱，反查可能公历时刻 |

### 数据与 AI

| 功能 | 说明 |
|------|------|
| 命主管理 | 保存、搜索、删除；同名同生辰自动去重 |
| 命盘合集 | 自定义分组，批量管理多份命盘 |
| AI 看盘 | DeepSeek 流式分析，支持追问与历史恢复 |
| 云端同步 | Supabase 登录，命盘与对话跨设备同步 |

---

## 技术架构

```mermaid
flowchart LR
  UI[Flutter UI] --> RP[Riverpod]
  RP --> UC[Use Cases]
  UC --> DOM[Domain]
  DOM --> INF[Infrastructure]
  INF --> Lunar[lunar 历法]
  INF --> Rules[规则引擎]
  INF --> SB[(Supabase)]
  INF --> AI[DeepSeek API]
```

| 层级 | 选型 |
|------|------|
| 前端 | Flutter 3.x · Material 3 · 中式纸色主题 |
| 状态 | Riverpod（Provider / Notifier） |
| 结构 | Domain → Infrastructure → Features |
| 历法 | [lunar](https://pub.dev/packages/lunar) + 自研 Rule* 分析器 |
| 后端 | Supabase Auth · PostgreSQL · RLS |
| AI | DeepSeek Chat API（流式 HTTP） |
| 测试 | 200+ 单元 / Widget 测试 |

算法细节见 [docs/ALGORITHMS.md](docs/ALGORITHMS.md)。

---

## 本地运行

> 仓库内**不含**任何 API 密钥，需自行注册 Supabase 与 DeepSeek 并填入配置。

**环境：** Flutter ≥ 3.20 · Android SDK 或 Chrome

```bash
git clone https://github.com/Nefelibata811/bazi.git
cd bazi
flutter pub get

cp secrets.example.env secrets.local.env
# 编辑 secrets.local.env → SUPABASE_URL / SUPABASE_ANON_KEY / DEEPSEEK_API_KEY
```

**启动（Windows）：**

```powershell
.\scripts\sync_dart_defines.ps1
.\scripts\run_android.ps1   # Android
.\scripts\run_web.ps1       # Web
```

**数据库：** 在 Supabase SQL Editor 执行 [`supabase_schema.sql`](supabase_schema.sql)。

**打包 Release：**

```powershell
.\scripts\sync_dart_defines.ps1
.\scripts\build_android_release.ps1   # APK → build\app\outputs\flutter-apk\
.\scripts\build_web_release.ps1       # Web → build\web\
```

请勿将 `secrets.local.env` 提交到 Git。

---

## 文档

| 文档 | 内容 |
|------|------|
| [PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md) | 目录与模块说明 |
| [ALGORITHMS.md](docs/ALGORITHMS.md) | 排盘与规则算法 |

---

## 声明

- 本项目仅供 **学习、研究与交流**，分析结果仅供参考，不构成专业命理或人生建议。
- Supabase、DeepSeek 等第三方服务需自行注册，可能产生费用。
- 如有问题或建议，欢迎提交 [Issue](https://github.com/Nefelibata811/bazi/issues)；觉得有用可以点个 Star。

---

<p align="center">Made with Flutter · 2025–2026</p>
