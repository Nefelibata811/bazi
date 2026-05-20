# Release Web build with secrets from environment or secrets.local.env
param(
  [string]$EnvFile = ""
)

Set-Location $PSScriptRoot\..

function Get-DefineFromEnv($name) {
  $v = [Environment]::GetEnvironmentVariable($name)
  if ($v) { return $v }
  return $null
}

$defines = @()
$envPath = if ($EnvFile) {
  $EnvFile
} else {
  $local = Join-Path $PSScriptRoot "..\secrets.local.env"
  if (Test-Path $local) { $local } else { Join-Path $PSScriptRoot "..\secrets.example.env" }
}

if (Test-Path $envPath) {
  Get-Content $envPath | ForEach-Object {
    if ($_ -match '^\s*#' -or $_ -notmatch '^\s*(\w+)=(.*)$') { return }
    $key = $Matches[1].Trim()
    $val = $Matches[2].Trim().Trim('"').Trim("'")
    [Environment]::SetEnvironmentVariable($key, $val, 'Process')
  }
}

foreach ($key in @('SUPABASE_URL', 'SUPABASE_ANON_KEY', 'DEEPSEEK_API_KEY')) {
  $val = Get-DefineFromEnv $key
  if (-not $val) {
    Write-Error "Missing $key. Set env var or add to secrets.local.env"
    exit 1
  }
  $defines += "--dart-define=$key=$val"
}

$baseUrl = Get-DefineFromEnv 'DEEPSEEK_BASE_URL'
if ($baseUrl) {
  $defines += "--dart-define=DEEPSEEK_BASE_URL=$baseUrl"
}

Write-Host "Building web release with dart-define keys: SUPABASE_URL, SUPABASE_ANON_KEY, DEEPSEEK_API_KEY"

flutter build web --release --no-web-resources-cdn @defines

if ($LASTEXITCODE -eq 0) {
  Write-Host "Output: build\web"
}
