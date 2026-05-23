# 修复 Gradle「Timeout waiting for exclusive access」：结束占用并清理不完整下载
Write-Host "Stopping Gradle-related Java processes..."
Get-Process -Name "java" -ErrorAction SilentlyContinue | ForEach-Object {
  $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
  if ($cmd -match 'gradle|GradleWrapper') {
    Write-Host "Stopping PID $($_.Id): gradle"
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
  }
}

$distRoot = Join-Path $env:USERPROFILE ".gradle\wrapper\dists\gradle-8.14-all"
if (Test-Path $distRoot) {
  Get-ChildItem $distRoot -Recurse -Filter "*.lck" -ErrorAction SilentlyContinue | Remove-Force -ErrorAction SilentlyContinue
  Get-ChildItem $distRoot -Recurse -Filter "*.part" -ErrorAction SilentlyContinue | Remove-Force -ErrorAction SilentlyContinue
  $dirs = Get-ChildItem $distRoot -Directory -ErrorAction SilentlyContinue
  foreach ($d in $dirs) {
    $zip = Join-Path $d.FullName "gradle-8.14-all.zip"
    if (Test-Path $zip) {
      $len = (Get-Item $zip).Length
      # 完整包约 150MB+；过小视为损坏，删除以便重新下载
      if ($len -lt 50MB) {
        Write-Host "Removing incomplete zip ($len bytes): $zip"
        Remove-Item $zip -Force -ErrorAction SilentlyContinue
      } else {
        Write-Host "Gradle zip looks complete ($([math]::Round($len/1MB)) MB): $zip"
      }
    }
  }
}

Write-Host ""
Write-Host "Done. Retry: .\scripts\run_android.ps1"
Write-Host "Keep only one flutter/gradle build at a time."
