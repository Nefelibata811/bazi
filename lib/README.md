# lib 源码说明

本目录为 App 全部 Dart 代码，采用 **Flutter + Riverpod + 分层架构**。

详细目录说明、技术框架、重点模块与数据流见：

**[docs/PROJECT_STRUCTURE.md](../docs/PROJECT_STRUCTURE.md)**

## 快速分层

| 目录 | 职责 |
|------|------|
| `main.dart` | 入口 |
| `app/` | 主题、路由、启动与 Supabase 初始化 |
| `core/` | 密钥、文案、调试工具 |
| `domain/` | 实体、用例、抽象接口（无 Flutter UI） |
| `infrastructure/` | 农历排盘、Supabase、AI 实现 |
| `features/` | 按功能划分的页面与状态管理 |
