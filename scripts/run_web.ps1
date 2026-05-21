# Web 开发启动方式（使用 --no-web-resources-cdn 避免从 Google CDN 拉取资源）
Set-Location $PSScriptRoot\..

$defines = @()
$envPath = Join-Path $PSScriptRoot "..\secrets.local.env"
if (Test-Path $envPath) {
  Get-Content $envPath | ForEach-Object {
    if ($_ -match '^\s*#' -or $_ -notmatch '^\s*(\w+)=(.*)$') { return }
    $key = $Matches[1].Trim()
    $val = $Matches[2].Trim().Trim('"').Trim("'")
    $defines += "--dart-define=$key=$val"
  }
}

flutter run -d chrome --no-web-resources-cdn --web-port=8080 @defines @args
