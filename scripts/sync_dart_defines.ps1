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

$json = $map | ConvertTo-Json -Compress
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Resolve-Path $OutPath).Path, $json, $utf8NoBom)
Write-Host "Wrote $OutPath"
