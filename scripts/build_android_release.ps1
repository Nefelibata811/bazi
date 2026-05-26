# Release APK（注入 secrets，可安装到真机；上架商店需另行配置签名）
param(
  [switch]$SplitPerAbi
)

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

$args = @(
  "build", "apk", "--release",
  "--dart-define-from-file=.dart_defines.generated.json"
)
if ($SplitPerAbi) { $args += "--split-per-abi" }

flutter @args
if (-not $?) { exit 1 }

Write-Host ""
if ($SplitPerAbi) {
  Write-Host "APK(s): build\app\outputs\flutter-apk\app-*-release.apk"
} else {
  Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk"
}
