# 创建 Flutter 友好的标准模拟器（API 35，非 16KB 页大小）
# 若已存在 Pixel_6_API_35 会跳过创建
param(
  [string]$AvdName = "Pixel_6_API_35",
  [string]$Package = "system-images;android-35;google_apis;x86_64"
)

$sdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$sdkmanager = Get-ChildItem "$sdkRoot\cmdline-tools" -Recurse -Filter sdkmanager.bat -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
$avdmanager = Get-ChildItem "$sdkRoot\cmdline-tools" -Recurse -Filter avdmanager.bat -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
$emu = Join-Path $sdkRoot "emulator\emulator.exe"

if (-not $sdkmanager -or -not $avdmanager) {
  Write-Error "Android cmdline-tools not found. Install via Android Studio SDK Manager."
  exit 1
}

$existing = & $emu -list-avds 2>&1 | Out-String
if ($existing -match [regex]::Escape($AvdName)) {
  Write-Host "AVD already exists: $AvdName"
  exit 0
}

Write-Host "Installing system image (may take a few minutes): $Package"
& $sdkmanager $Package
if (-not $?) { exit 1 }

Write-Host "Creating AVD: $AvdName"
echo "no" | & $avdmanager create avd -n $AvdName -k $Package -d "pixel_6"
if (-not $?) { exit 1 }

Write-Host "Done. Start with: .\scripts\start_emulator.ps1"
