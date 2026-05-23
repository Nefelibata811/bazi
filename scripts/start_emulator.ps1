# 启动 Android 模拟器（-gpu host 缓解 Flutter 黑屏）
# 默认 Pixel_6_API_35：标准 4KB 页大小，Flutter 兼容好；勿用 Pixel_9_Pro（16KB/API37 易黑屏）
param(
  [string]$Id = "Pixel_6_API_35"
)

Set-Location $PSScriptRoot\..

$emu = Join-Path $env:LOCALAPPDATA "Android\Sdk\emulator\emulator.exe"
if (Test-Path $emu) {
  Write-Host "Launching $Id with -gpu host ..."
  Start-Process -FilePath $emu -ArgumentList "-avd", $Id, "-gpu", "host" -WindowStyle Normal
} else {
  Write-Host "Launching via flutter emulators --launch $Id"
  flutter emulators --launch $Id
}

Write-Host "Waiting for device (up to 90s)..."
$deadline = (Get-Date).AddSeconds(90)
do {
  Start-Sleep -Seconds 3
  $out = flutter devices 2>&1 | Out-String
  if ($out -match 'emulator-\d+') {
    Write-Host $out
    Write-Host "Emulator ready. Run: .\scripts\run_android.ps1"
    exit 0
  }
} while ((Get-Date) -lt $deadline)

Write-Host $out
Write-Error "Emulator did not appear in 'flutter devices' within 90s."
exit 1
