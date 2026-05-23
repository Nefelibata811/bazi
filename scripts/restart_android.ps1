# 启动模拟器并运行 App（首次 Gradle 编译可能需 5–15 分钟）
Set-Location $PSScriptRoot\..

& "$PSScriptRoot\start_emulator.ps1"
if (-not $?) { exit 1 }

& "$PSScriptRoot\run_android.ps1" @args
