# 完整重启 Web（热重载不会更新 web/index.html、flutter_bootstrap.js、--dart-define）
Set-Location $PSScriptRoot\..

Write-Host "Stopping old Chrome debug sessions is manual: press Stop in VS Code first." -ForegroundColor Yellow
& (Join-Path $PSScriptRoot 'run_web.ps1')
