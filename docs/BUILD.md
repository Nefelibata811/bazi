# 构建与密钥

## 开发运行

### Web

```powershell
cd "d:\bazi app\bazi"
.\scripts\run_web.ps1
```

### Android 模拟器

详见 [ANDROID_DEV.md](ANDROID_DEV.md)。**请用 `Pixel_6_API_35`**（不要用带 16KB 页大小的 `Pixel_9_Pro`，会黑屏）。

```powershell
cd "d:\bazi app\bazi"
.\scripts\restart_android.ps1
```

或：先 `.\scripts\start_emulator.ps1`，再 `.\scripts\run_android.ps1`。  
仅编译 APK：`.\scripts\build_android.ps1`。  
VS Code / Trae 选 **「bazi Android (模拟器)」** 后 F5（需模拟器已启动；建议先设好上面的两个环境变量）。

脚本会读取 `secrets.local.env` 并注入 `SUPABASE_*`、`DEEPSEEK_API_KEY`（AI 看盘必需）。勿直接 `flutter run`，否则 AI 会用空密钥或旧缓存。

或使用 VS Code 配置 **bazi Web (Chrome)**（需自行加上与 `secrets.local.env` 等价的 `--dart-define`）。

**Release 必须**通过 `--dart-define` 注入密钥（见 `build_web_release.ps1`）。

## Release Web 构建

1. 复制 `secrets.example.env` 为 `secrets.local.env`，填入真实值（勿提交 Git）。
2. 执行：

```powershell
.\scripts\build_web_release.ps1
```

或手动：

```powershell
flutter build web --release --no-web-resources-cdn `
  --dart-define=SUPABASE_URL=https://xxx.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJ... `
  --dart-define=DEEPSEEK_API_KEY=sk-...
```

产物目录：`build/web`。

## Web 字体（国内、尽量快）

- **界面中文**：系统字体（微软雅黑 → 苹方 → 黑体），不打包 Noto。
- **引擎**：`web/flutter_bootstrap.js` 里 `fontFallbackBaseUrl: ''`，**不拉** gstatic 的 Roboto / Noto Sans SC 分片（避免 `Failed to parse fallback font Noto Sans SC`）。
- 启动请带 **`--no-web-resources-cdn`**（`run_web.ps1` / VS Code **bazi Web (Chrome)** 已包含），并**完全重启**应用（不要只热重载）。

## Supabase 认证（Web）

- **Site URL**：与部署域名一致，本地开发可用 `http://localhost:<端口>`
- **Redirect URLs**：`http://localhost:**/**` 与生产 `https://你的域名/**`
- 重置密码邮件会跳转到当前页面的 `Uri.base.origin`（随 Flutter Web 端口变化）
