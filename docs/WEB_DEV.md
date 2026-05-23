# Web 本地调试说明

## F5 也显示「找不到设备」

按下面顺序排查（本项目命令行 `flutter run` 已验证可用，问题多在编辑器配置）：

1. **确认已装扩展**（Trae 与 VS Code 相同）：**Dart** + **Flutter**（发布者 Dart Code）。未安装时 F5 无法识别 `type: dart` 的启动项。
2. **看工作区打开的是哪一层文件夹**  
   - 打开 **`d:\bazi app`**：用根目录 **「bazi Web (Chrome)」**，不要用子目录里重复的配置。  
   - 只打开 **`d:\bazi app\bazi`**：用本目录 **「bazi Web (Chrome)」**；此前 `bazi/.vscode/settings.json` 误用了 `secrets.local.env`，会导致启动失败，已改为 `.dart_defines.generated.json`。
3. **先同步密钥再 F5**：在 `bazi` 目录执行 `.\scripts\sync_dart_defines.ps1`，或 F5 时允许运行 preLaunchTask **bazi: sync dart defines**。
4. **系统 PATH 里的 Dart 与 Flutter 冲突**：`flutter doctor` 若提示 `dart` 指向 `D:\Dart\...`，已在 `.vscode/settings.json` 指定 `dart.sdkPath` 为 Flutter 自带 SDK；**重载窗口**后重试 F5。
5. **看「调试控制台」完整报错**（不是只看弹窗「no device」）。把第一行红色错误复制出来便于定位。

仍失败时，用脚本启动（不依赖 IDE 设备列表）：

```powershell
cd "d:\bazi app\bazi"
.\scripts\restart_web.ps1
```

终端里按 `r` 热重载。

## Trae / VS Code 点热重载显示「no device」

**原因**：编辑器里的热重载按钮只作用于 **F5 启动的调试会话**，不会连到你用 PowerShell / 终端里单独跑的 `flutter run`。

| 现象 | 处理 |
|------|------|
| 没按 F5，直接点 ⚡ 热重载 | 选 **「bazi Web (Chrome)」** → **启动调试 (F5)**，等 Chrome 打开且底部调试栏出现后再点热重载 |
| 用 `.\scripts\restart_web.ps1` 或终端 `flutter run` 起的应用 | 在**该终端**里按 `r` 热重载；或在命令面板执行 **Dart: Attach to Flutter on Chrome** 后再用 IDE 热重载 |
| 调试已停（红方块已点过） | 重新 F5，不要只点热重载 |
| 工作区打开了 `bazi` 子文件夹 | 用本目录 `.vscode` 里的 **bazi Web (Chrome)**；根目录 `d:\bazi app` 则用上一级配置（`cwd` 已指向 `bazi`） |
| 状态栏设备是「No Device」且未在调试 | 先 F5；仅 `flutter devices` 有设备不够，必须有**活跃调试会话** |

确认设备（可选）：

```powershell
cd "d:\bazi app\bazi"
flutter devices
```

应能看到 `Chrome` / `Windows`。看不到时先 `flutter doctor`，不要先点热重载。

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
