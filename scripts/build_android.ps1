# 仅编译 Android Debug APK（不启动模拟器）
Set-Location $PSScriptRoot\..

if (-not $env:FLUTTER_STORAGE_BASE_URL) {
  $env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
}
if (-not $env:PUB_HOSTED_URL) {
  $env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
}
$env:GRADLE_USER_HOME = if ($env:GRADLE_USER_HOME) { $env:GRADLE_USER_HOME } else { "$env:USERPROFILE\.gradle" }

& "$PSScriptRoot\sync_dart_defines.ps1"
if (-not $?) { exit 1 }

flutter build apk --debug --dart-define-from-file=.dart_defines.generated.json @args
Write-Host ""
Write-Host "APK: build\app\outputs\flutter-apk\app-debug.apk"
