# Android 模拟器 / 真机：同步密钥后 flutter run（默认任意已连接的 Android 设备）
Set-Location $PSScriptRoot\..

# 国内网络：Flutter 引擎与 Pub 镜像（与 flutter doctor 中 pub.flutter-io.cn 一致）
if (-not $env:FLUTTER_STORAGE_BASE_URL) {
  $env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
}
if (-not $env:PUB_HOSTED_URL) {
  $env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
}

& "$PSScriptRoot\sync_dart_defines.ps1"
if (-not $?) { exit 1 }

$env:GRADLE_USER_HOME = if ($env:GRADLE_USER_HOME) { $env:GRADLE_USER_HOME } else { "$env:USERPROFILE\.gradle" }

$flutterArgs = @(
  "run",
  "--no-enable-impeller",
  "--enable-software-rendering",
  "--dart-define-from-file=.dart_defines.generated.json"
)

# 未指定 -d 时，优先使用已连接的 Android 设备
$hasDevice = $false
foreach ($a in $args) {
  if ($a -eq "-d" -or $a.StartsWith("-d")) { $hasDevice = $true; break }
}
if (-not $hasDevice) {
  $devices = flutter devices 2>&1 | Out-String
  if ($devices -match '(emulator-\d+)') {
    $id = $Matches[1]
    Write-Host "Using Android device: $id"
    $flutterArgs += "-d", $id
  } else {
    Write-Host "No emulator in flutter devices. Start one: .\scripts\start_emulator.ps1"
    $flutterArgs += "-d", "android"
  }
}

Write-Host "GRADLE_USER_HOME=$env:GRADLE_USER_HOME"
flutter @flutterArgs @args
