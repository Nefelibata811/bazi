param(
  [string]$EnvPath = (Join-Path $PSScriptRoot "..\secrets.local.env"),
  [string]$OutPath = (Join-Path $PSScriptRoot "..\.dart_defines.generated.json")
)

if (-not (Test-Path $EnvPath)) {
  Write-Error "Missing secrets.local.env - copy secrets.example.env and set DEEPSEEK_API_KEY"
  exit 1
}

$map = [ordered]@{}
Get-Content $EnvPath | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -notmatch '^\s*(\w+)=(.*)$') { return }
  $key = $Matches[1].Trim()
  $val = $Matches[2].Trim().Trim('"').Trim("'")
  if ($key) { $map[$key] = $val }
}

if (-not $map.Contains('DEEPSEEK_API_KEY') -or [string]::IsNullOrWhiteSpace($map['DEEPSEEK_API_KEY'])) {
  Write-Error "DEEPSEEK_API_KEY is empty in secrets.local.env"
  exit 1
}

foreach ($key in @('SUPABASE_URL', 'SUPABASE_ANON_KEY')) {
  if (-not $map.Contains($key) -or [string]::IsNullOrWhiteSpace($map[$key])) {
    Write-Error "$key is empty in secrets.local.env"
    exit 1
  }
}

$url = $map['SUPABASE_URL']
$anon = $map['SUPABASE_ANON_KEY']
if ($url -match 'your-project\.supabase\.co' -or $anon -match '^your_supabase') {
  Write-Error @"
secrets.local.env still uses placeholder values from secrets.example.env.
Open Supabase Dashboard -> Project Settings -> API, copy Project URL and anon public key,
then edit secrets.local.env and run this script again before building release.
"@
  exit 1
}

$json = $map | ConvertTo-Json -Compress
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Resolve-Path $OutPath).Path, $json, $utf8NoBom)
Write-Host "Wrote $OutPath"
