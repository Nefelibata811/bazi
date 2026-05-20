# Web 开发推荐启动方式（避免 CanvasKit 从 gstatic 加载失败导致白屏）
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

flutter run -d chrome --no-web-resources-cdn @defines @args
