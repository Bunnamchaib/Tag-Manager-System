param(
    [string]$RepoPath = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$gitDir = Join-Path $RepoPath ".git"
if (-not (Test-Path -LiteralPath $gitDir)) {
    Write-Host "[ERROR] .git not found at: $RepoPath" -ForegroundColor Red
    Write-Host "Run this script after 'git init' or inside your git repository." -ForegroundColor Yellow
    exit 1
}

$hookPath = Join-Path $RepoPath ".git\hooks\pre-push"
$hookContent = @"
#!/bin/sh
REPO_ROOT="\$(cd "\$(dirname "\$0")/../.." && pwd)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "\$REPO_ROOT/pre_push_check.ps1"
status=\$?
if [ \$status -ne 0 ]; then
  echo "Push stopped: pre_push_check failed."
  exit \$status
fi
exit 0
"@

Set-Content -LiteralPath $hookPath -Value $hookContent -Encoding ASCII

Write-Host "[OK] Installed pre-push hook at: $hookPath" -ForegroundColor Green
Write-Host "[INFO] Hook will run pre_push_check.ps1 before every push." -ForegroundColor Cyan
exit 0
