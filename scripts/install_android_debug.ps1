# 将已编译的 Debug APK 安装到当前连接的 Android 设备/模拟器
Set-Location $PSScriptRoot\..

$apk = Join-Path $PSScriptRoot "..\build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path $apk)) {
  Write-Host "APK not found. Building first..."
  & "$PSScriptRoot\build_android.ps1"
  if (-not $?) { exit 1 }
}

$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
  Write-Error "adb not found. Install Android SDK platform-tools."
  exit 1
}

$devices = & $adb devices 2>&1 | Out-String
if ($devices -notmatch 'emulator-\d+\s+device|device$') {
  Write-Error "No Android device/emulator online. Run: .\scripts\start_emulator.ps1"
  exit 1
}

Write-Host "Installing $apk ..."
& $adb install -r $apk
if (-not $?) { exit 1 }

Write-Host ""
Write-Host "Installed. On emulator home screen, open app: 八字排盘"
Write-Host "(Flutter default blue icon; package: com.example.bazi_app)"
