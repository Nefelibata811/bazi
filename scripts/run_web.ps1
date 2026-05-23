# Web dev: inject secrets via --dart-define (reliable when path has spaces).
Set-Location $PSScriptRoot\..

$envPath = Join-Path $PSScriptRoot "..\secrets.local.env"
& "$PSScriptRoot\sync_dart_defines.ps1"
if (-not $?) { exit 1 }

$defines = @()
if (Test-Path $envPath) {
  Get-Content $envPath | ForEach-Object {
    if ($_ -match '^\s*#' -or $_ -notmatch '^\s*(\w+)=(.*)$') { return }
    $key = $Matches[1].Trim()
    $val = $Matches[2].Trim().Trim('"').Trim("'")
    if ($key) { $defines += "--dart-define=${key}=${val}" }
  }
}

if ($defines.Count -eq 0) {
  Write-Error "No dart-define entries from secrets.local.env"
  exit 1
}

Write-Host "Starting with $($defines.Count) dart-define(s) from secrets.local.env"
flutter run -d chrome --no-web-resources-cdn --web-port=8080 @defines @args
