# 应用图标（Android APK）

桌面图标来自 **`android/app/src/main/res/mipmap-*/ic_launcher.png`**，不是 Flutter 默认蓝标。打包 APK 前需生成各尺寸图标。

## 用自己的图（推荐）

1. 准备一张 **1024×1024** 的 PNG（正方形、主体居中，四周留边，避免圆角裁切）。
2. 覆盖保存为：

   ```text
   bazi/assets/icon/app_icon.png
   ```

3. 生成 Android 图标并重新打 APK：

   ```powershell
   cd "d:\bazi app\bazi"
   .\scripts\update_app_icon.ps1
   .\scripts\build_android.ps1
   ```

4. 在模拟器/真机上 **卸载旧 App** 再安装新 APK（系统会缓存旧图标）。

## 配置说明

`pubspec.yaml` 里使用 [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons)：

- `image_path`：主图标
- `adaptive_icon_background`：自适应图标背景色（米色 `#F7F3EC`，与 App 主题一致）
- `AndroidManifest.xml` 已引用 `@mipmap/ic_launcher`，无需手改

## Android Studio 里改（可选）

**File → New → Image Asset** → Launcher Icons → 选你的 PNG → 会写入 `mipmap-*`。  
若与脚本并用，以最后一次生成为准。

## Web 图标（另算）

浏览器标签图标在 `web/icons/`，与 APK 桌面图标无关；改 Web 需单独替换 `Icon-192.png` 等。
