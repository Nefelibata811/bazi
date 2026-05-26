# 根据 assets/icon/app_icon.png 生成 Android 各尺寸启动图标
Set-Location $PSScriptRoot\..

if (-not (Test-Path "assets\icon\app_icon.png")) {
  Write-Error "Missing assets/icon/app_icon.png — place a 1024x1024 PNG there first."
  exit 1
}

flutter pub get
if (-not $?) { exit 1 }

dart run flutter_launcher_icons
if (-not $?) { exit 1 }

Write-Host ""
Write-Host "Android icons updated under android/app/src/main/res/mipmap-*"
Write-Host "Rebuild APK: .\scripts\build_android.ps1"
