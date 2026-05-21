# Web 本地调试说明

## 热重载（⚡）解决不了的问题

下面这些改了以后，**必须停止调试 → 重新启动**，热重载无效：

- `web/index.html`、`web/flutter_bootstrap.js`
- `secrets.local.env`、`--dart-define`
- 字体策略、`--no-web-resources-cdn`

推荐一键完整重启：

```powershell
cd "d:\bazi app\bazi"
.\scripts\restart_web.ps1
```

## 工作区在 `d:\bazi app` 时

请用根目录 VS Code 配置 **「bazi Web (Chrome)」**（`cwd` 已指向 `bazi` 子目录），或直接用上面的 `restart_web.ps1`。

若控制台仍出现 `fonts.gstatic.com` 或 `Noto Sans SC 9x`，说明 `flutter_bootstrap.js` 未生效：请**停止调试**后重新 `.\scripts\restart_web.ps1`，不要热重载。

引擎已设置 `fontFallbackBaseUrl: ''`，不再从 Google 下载任何回退字体；缺字由浏览器系统字体显示。
