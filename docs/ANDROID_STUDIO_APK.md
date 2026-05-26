# 在 Android Studio 里打包 APK

## 0. 打开哪个目录？

**File → Open** → 选：

```text
d:\bazi app\bazi
```

必须是有 **`pubspec.yaml`** 的 Flutter 工程根目录，**不要**只打开里面的 `android` 文件夹。

需已安装 **Flutter**、**Dart** 插件，并配置好 **Flutter SDK**（Settings → Flutter）。

---

## 1. 打包前准备

1. **`secrets.local.env`** 已配置（从 `secrets.example.env` 复制并填好密钥）。
2. （可选）换图标：`assets/icon/app_icon.png` → `.\scripts\update_app_icon.ps1`
3. 建议设置用户环境变量（国内网络）：
   - `PUB_HOSTED_URL` = `https://pub.flutter-io.cn`
   - `FLUTTER_STORAGE_BASE_URL` = `https://storage.flutter-io.cn`

---

## 2. 推荐方式：Android Studio 底部 Terminal

在 AS 里打开 **Terminal**，执行：

### 调试包（自己测、安装快）

```powershell
cd "d:\bazi app\bazi"
.\scripts\build_android.ps1
```

产物：`build\app\outputs\flutter-apk\app-debug.apk`

### 正式包（体积更小，给真机分发）

```powershell
cd "d:\bazi app\bazi"
.\scripts\build_android_release.ps1
```

产物：`build\app\outputs\flutter-apk\app-release.apk`

按 CPU 拆成多个小包（可选）：

```powershell
.\scripts\build_android_release.ps1 -SplitPerAbi
```

产物：`app-armeabi-v7a-release.apk`、`app-arm64-v8a-release.apk` 等。

> **重要**：必须通过上面的脚本或下面的 `flutter build apk` 注入 `--dart-define`。  
> 若只用 Gradle 菜单 **Build APK** 而不带密钥，登录和 AI 会失败。

---

## 3. 用 Android Studio / Flutter 菜单（可选）

部分版本有：

**Build → Flutter → Build APK**

或工具栏 **Flutter** 相关入口。

若菜单里没有，请用第 2 节 Terminal 命令（最稳）。

打包前在 Terminal 先执行一次：

```powershell
.\scripts\sync_dart_defines.ps1
```

手动等价命令：

```powershell
flutter build apk --release --dart-define-from-file=.dart_defines.generated.json
```

---

## 4. 不要用「只编 android 子工程」的方式

**Build → Build Bundle(s) / APK(s) → Build APK(s)**（仅 `android` 模块）  
不会自动带上 Flutter 的 `dart-define`，**不适合**本项目。

请始终用 **Flutter 的 `flutter build apk`**（或项目脚本）。

---

## 5. 找到 APK 并安装

打包成功后，在资源管理器打开：

```text
d:\bazi app\bazi\build\app\outputs\flutter-apk\
```

- 拖到模拟器窗口安装，或  
- `adb install build\app\outputs\flutter-apk\app-release.apk`

安装前建议**卸载**旧版「八字排盘」，避免图标/缓存异常。

---

## 6. 上架 Google Play（以后）

当前 Release 用的是 **debug 签名**（`build.gradle.kts` 里临时配置），仅适合内测分发。

上架商店需要：

1. 生成自己的 **keystore**
2. 在 `android/app/build.gradle.kts` 配置 `signingConfigs`
3. 使用 `flutter build appbundle` 打 **AAB**

---

## 7. 常见问题

| 问题 | 处理 |
|------|------|
| Gradle 下载失败 | 确认镜像环境变量；`.\scripts\fix_gradle_lock.ps1` 后重试 |
| 装完无法登录 / AI 无密钥 | 打包时未带 `dart-define`，用 `build_android_release.ps1` |
| 图标仍是 Flutter 蓝标 | 先 `update_app_icon.ps1` 再重新 `build apk` |
| 模拟器黑屏 | 用 `Pixel_6_API_35`，见 [ANDROID_DEV.md](ANDROID_DEV.md) |
