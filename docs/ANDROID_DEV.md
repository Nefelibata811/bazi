# Android 模拟器运行指南

## 你需要具备的环境

本机 `flutter doctor` 里 **Android toolchain** 应为 ✓（你已安装 Android SDK）。

**国内网络**（推荐永久设置用户环境变量，或在脚本里已自动带上）：

| 变量 | 值 |
|------|-----|
| `PUB_HOSTED_URL` | `https://pub.flutter-io.cn` |
| `FLUTTER_STORAGE_BASE_URL` | `https://storage.flutter-io.cn` |

Android 编译还会从 `download.flutter.io` 拉引擎 JAR，项目 `android/build.gradle.kts` 已配置镜像。

**推荐模拟器：`Pixel_6_API_35`（Android 15 / API 35，标准 4KB 页大小）**

| 模拟器 | 说明 |
|--------|------|
| **Pixel_6_API_35** ✅ | 已为本项目创建，Flutter 显示正常 |
| **Pixel_9_Pro** ❌ | 系统镜像是 **16 KB Page Size + API 37**，Flutter 在 x86 上易 **整屏黑屏**（App 其实在跑，只是画不出来） |

若只有 `Pixel_9_Pro`：Android Studio → Device Manager → **+** → Pixel 6 → 选 **API 35 Google APIs**（不要选带 **16 KB Page Size** 的镜像）。

## 一次性准备

1. **密钥**（与 Web 相同）  
   复制 `secrets.example.env` → `secrets.local.env`，填好 `SUPABASE_*`、`DEEPSEEK_API_KEY`。

2. **生成 Android 工程**（已完成可跳过）  
   项目曾只有 Web，需有 `android/` 目录。若缺失，在 `bazi` 目录执行：
   ```powershell
   flutter create --platforms=android .
   ```

3. **（可选）Supabase 控制台**  
   若要在手机上测「忘记密码」邮件回调，在 **Authentication → Redirect URLs** 添加：  
   `io.supabase.baziapp://reset-password/**`

## 状态说明

- 项目已生成 `android/` 目录，并配置国内 Gradle / Flutter 引擎镜像。
- 在本机模拟器上 **Debug APK 已能成功编译**（`app-debug.apk`）。

## 1. 安装插件

**Settings → Plugins**，搜索并安装：

- **Flutter**（会连带安装 **Dart**）

装完后重启 Android Studio。

## 2. 打开正确的目录

**File → Open**，选：

```text
d:\bazi app\bazi
```

必须是有 **`pubspec.yaml`** 的这一层，**不要**只打开里面的 `android` 子文件夹（那样不是 Flutter 工程，跑不起来）。

等右下角 **Pub get / Indexing** 完成。

## 3. 配置 Flutter SDK

**Settings → Languages & Frameworks → Flutter**

- Flutter SDK path：`D:\flutter`（与你本机一致即可）

**Settings → Languages & Frameworks → Dart**

- 勾选 **Use Dart SDK from Flutter SDK**

## 4. 环境变量（国内网络，建议设一次）

Windows 用户环境变量（或 Android Studio 运行配置里加）：

| 变量 | 值 |
|------|-----|
| `PUB_HOSTED_URL` | `https://pub.flutter-io.cn` |
| `FLUTTER_STORAGE_BASE_URL` | `https://storage.flutter-io.cn` |

设完**重启 Android Studio**。

## 5. 同步密钥（每次改 secrets 后）

在 Android Studio 底部 **Terminal**：

```powershell
cd "d:\bazi app\bazi"
.\scripts\sync_dart_defines.ps1
```

## 6. 启动模拟器

**View → Tool Windows → Device Manager**（或右侧手机图标）

- 选中 **Pixel 9 Pro**（或你的 AVD）
- 点 **▶ Run**（三角）
- 等模拟器桌面完全进入

顶部工具栏设备下拉框里应出现 `sdk gphone... (emulator-5554)`。

## 7. 配置运行项（带密钥，重要）

**Run → Edit Configurations…**

1. 点 **+** → 选 **Flutter**
2. 名称：`bazi Android`
3. **Dart entrypoint**：`lib/main.dart`
4. **Additional run args** 填：

   ```text
   --no-enable-impeller --dart-define-from-file=.dart_defines.generated.json
   ```

5. **Build flavor** 留空；**Device** 选已启动的模拟器

保存。

> 若不填 `Additional run args`，App 能装但 **登录 / AI 会缺密钥**。

## 8. 点运行

顶部绿色 **▶ Run**（或 **Shift+F10**）。

首次会跑 Gradle，可能要 **5–15 分钟**。成功后模拟器会**自动打开 App**，桌面图标名是 **「八字排盘」**。

---

## 常见问题

| 现象 | 处理 |
|------|------|
| 没有 Flutter 运行配置、只有 Android App | 没装 Flutter 插件，或打开目录不对 |
| 设备列表为空 | Device Manager 里先启动模拟器 |
| Gradle 下载失败 | 确认第 4 步环境变量；Build 窗口看具体报错 |
| 模拟器有桌面但找不到 App | 必须点 **Run** 安装；只 Build APK 不会出现在桌面 |
| 打开 App 后一直黑屏 | 1) 已关 Impeller + 开 **软件渲染**（`--enable-software-rendering`）<br>2) 模拟器用 `start_emulator.ps1`（`-gpu host`）<br>3) 深色模式曾导致窗口纯黑，已改 `values-night`<br>4) 仍黑：Android Studio → Device Manager → 模拟器 ▼ → **Cold Boot Now**，再 `.\scripts\run_android.ps1` |

## 命令行（与 Android Studio 等价）

```powershell
cd "d:\bazi app\bazi"
.\scripts\restart_android.ps1
```

---

## 每次运行（命令行）

### 步骤 1：启动模拟器

任选一种：

```powershell
# 命令行（默认 Pixel_6_API_35）
cd "d:\bazi app\bazi"
flutter emulators --launch Pixel_6_API_35
```

或 **Device Manager** 里启动 **Pixel_6_API_35**（不要启动 Pixel_9_Pro）。

### 步骤 2：确认设备在线

```powershell
flutter devices
```

应出现类似：`sdk gphone64 ... • emulator-5554 • android`。

### 步骤 3：运行 App

```powershell
cd "d:\bazi app\bazi"
.\scripts\run_android.ps1
```

一键（启动模拟器 + 运行）：

```powershell
.\scripts\restart_android.ps1
```

**首次编译**会下载 Gradle / Android 依赖，可能需 **5–15 分钟**，请保持网络畅通。若报错 `Timeout waiting for exclusive access` 到 gradle zip，关闭其它 Android Studio / 旧 `flutter run` 后重试；脚本已设置 `GRADLE_USER_HOME=%USERPROFILE%\.gradle`。

### 模拟器里「找不到项目」？

模拟器桌面**不会出现你的源码文件夹**，只会出现**已安装的 App**。

| 情况 | 原因 | 处理 |
|------|------|------|
| 只跑了 `build_android.ps1` | 只生成了 APK，**没装进模拟器** | `.\scripts\install_android_debug.ps1` 或 `.\scripts\run_android.ps1` |
| 在找「bazi」文件夹名 | 桌面显示名是 **「八字排盘」**，不是项目目录名 | 在应用抽屉里搜「八字」 |
| 图标不好认 | 默认 Flutter 蓝色图标 | 看名称 **八字排盘** |
| `flutter install` 失败 | 它默认找 **release** APK | 用上面的 `install_android_debug.ps1` |

**推荐**：`.\scripts\restart_android.ps1` — 会编译、安装并自动打开 App（`flutter run`）。

首次编译较慢（数分钟正常）。终端里 **`r`** 热重载，**`R`** 热重启。

指定设备 ID（多台时）：

```powershell
.\scripts\run_android.ps1 -d emulator-5554
```

## 用 Trae / VS Code F5

1. 先启动模拟器（见上）。
2. 运行配置选 **「bazi Android (模拟器)」** → F5。  
3. 工作区为 `d:\bazi app` 或 `d:\bazi app\bazi` 均可（已各配 launch.json）。

## 常见问题

| 现象 | 处理 |
|------|------|
| `flutter devices` 没有 Android | 模拟器未开完；或 `adb devices` 为空 → 重启模拟器 / Android Studio |
| `Timeout waiting for exclusive access`（gradle zip） | 同时开了多个编译；执行 `.\scripts\fix_gradle_lock.ps1` 后只保留一个 `flutter run` |
| Gradle 下载 `SocketException` / 超时 | 项目已默认腾讯云 Gradle + 阿里云 Maven；仍失败可开 VPN，或把 `android/gradle/wrapper/gradle-wrapper.properties` 改回官方 `services.gradle.org` |
| 编译 Gradle 失败 | 首次需联网下载 5–15 分钟；勿在 Android Studio 与终端同时编译 |
| `different roots`（C: Pub 与 D: 项目） | 项目已在 `gradle.properties` 关闭 `kotlin.incremental`；仍失败则 `flutter clean` 后重试，或将工程放到 C 盘 |
| 登录/密钥无效 | 必须用 `run_android.ps1` 或带 `preLaunchTask` 的 F5，不能只热重载注入密钥 |
| 只有 Web/Windows | 确认在 `bazi` 目录且存在 `android/` 文件夹 |

## 真机 USB 调试

1. 手机开启开发者选项 + USB 调试。  
2. 数据线连接，`flutter devices` 出现设备名。  
3. `.\scripts\run_android.ps1 -d <设备id>`。
