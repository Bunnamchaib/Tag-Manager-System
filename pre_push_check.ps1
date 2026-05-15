param(
    [string]$ProjectPath = $PSScriptRoot,
    [switch]$SkipBackup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-ErrorMsg([string]$msg) {
    $errors.Add($msg) | Out-Null
    Write-Host "[ERROR] $msg" -ForegroundColor Red
}

function Add-WarnMsg([string]$msg) {
    $warnings.Add($msg) | Out-Null
    Write-Host "[WARN ] $msg" -ForegroundColor Yellow
}

function Add-InfoMsg([string]$msg) {
    Write-Host "[INFO ] $msg" -ForegroundColor Cyan
}

function Get-CheckFiles([string]$rootPath) {
    $gitRoot = $null
    try {
        $gitRoot = (git -C $rootPath rev-parse --show-toplevel 2>$null).Trim()
    } catch {
        $gitRoot = $null
    }

    if ($gitRoot) {
        $staged = @(git -C $rootPath diff --cached --name-only)
        if ($staged.Count -gt 0) {
            Add-InfoMsg "Using staged files from git index."
            return $staged | ForEach-Object { Join-Path $gitRoot $_ } | Where-Object { Test-Path -LiteralPath $_ }
        }

        Add-WarnMsg "No staged files found. Falling back to all project files."
    } else {
        Add-WarnMsg "Not in a git repository. Falling back to all project files."
    }

    return Get-ChildItem -Path $rootPath -Recurse -File |
        Where-Object { $_.FullName -notmatch "\\.git\\" } |
        Select-Object -ExpandProperty FullName
}

function Check-MergeConflicts([string[]]$files) {
    foreach ($file in $files) {
        try {
            $hits = Select-String -Path $file -Pattern '^\s*(<<<<<<< .+|=======|>>>>>>> .+)\s*$'
            if ($hits) {
                Add-ErrorMsg "Merge conflict marker found: $file"
            }
        } catch {
            Add-WarnMsg "Skip conflict check (unreadable): $file"
        }
    }
}

function Check-PythonSyntax([string[]]$files) {
    $pyFiles = $files | Where-Object { $_.ToLower().EndsWith('.py') }
    foreach ($file in $pyFiles) {
        & python -m py_compile $file
        if ($LASTEXITCODE -ne 0) {
            Add-ErrorMsg "Python syntax failed: $file"
        } else {
            Add-InfoMsg "Python syntax OK: $file"
        }
    }
}

function Check-NodeSyntax([string[]]$files) {
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeCmd) {
        Add-WarnMsg "Node.js not found. Skipping JS/GS/inline-script syntax checks."
        return
    }

    $jsLike = $files | Where-Object {
        $lower = $_.ToLower()
        $lower.EndsWith('.js') -or $lower.EndsWith('.gs')
    }

    foreach ($file in $jsLike) {
        & node --check $file
        if ($LASTEXITCODE -ne 0) {
            Add-ErrorMsg "Node syntax failed: $file"
        } else {
            Add-InfoMsg "Node syntax OK: $file"
        }
    }

    $htmlFiles = $files | Where-Object { $_.ToLower().EndsWith('.html') }
    foreach ($file in $htmlFiles) {
        $content = Get-Content -Raw -LiteralPath $file
        $openCount = ([regex]::Matches($content, '(?i)<script\b')).Count
        $closeCount = ([regex]::Matches($content, '(?i)</script>')).Count
        if ($openCount -ne $closeCount) {
            Add-ErrorMsg "Unbalanced <script> tags: $file (open=$openCount, close=$closeCount)"
        }

        $matches = [regex]::Matches($content, '(?is)<script\b[^>]*>(.*?)</script>')
        $idx = 0
        foreach ($m in $matches) {
            $idx++
            $inlineJs = $m.Groups[1].Value.Trim()
            if ([string]::IsNullOrWhiteSpace($inlineJs)) {
                continue
            }

            $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("prepush_inline_{0}_{1}.js" -f [System.IO.Path]::GetFileNameWithoutExtension($file), $idx)
            Set-Content -LiteralPath $tmp -Value $inlineJs -Encoding UTF8
            & node --check $tmp
            if ($LASTEXITCODE -ne 0) {
                Add-ErrorMsg "Inline <script> syntax failed: $file (block $idx)"
            } else {
                Add-InfoMsg "Inline <script> syntax OK: $file (block $idx)"
            }
            Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
        }
    }
}

function Run-BackupIfAvailable([string]$rootPath) {
    if ($SkipBackup) {
        Add-InfoMsg "Skip backup by option."
        return
    }

    $backupPath = Join-Path (Split-Path $rootPath -Parent) "backup.py"
    if (-not (Test-Path -LiteralPath $backupPath)) {
        Add-WarnMsg "backup.py not found at expected path: $backupPath"
        return
    }

    Add-InfoMsg "Running backup script: $backupPath"
    & python $backupPath
    if ($LASTEXITCODE -ne 0) {
        Add-ErrorMsg "backup.py failed (exit code $LASTEXITCODE)."
    } else {
        Add-InfoMsg "backup.py completed."
    }
}

Write-Host "=== Pre-push Check Start ===" -ForegroundColor Green
Add-InfoMsg "Project path: $ProjectPath"

Run-BackupIfAvailable -rootPath $ProjectPath
$files = @(Get-CheckFiles -rootPath $ProjectPath)

if ($files.Count -eq 0) {
    Add-WarnMsg "No files found to check."
} else {
    Add-InfoMsg ("Files to check: {0}" -f $files.Count)
    Check-MergeConflicts -files $files
    Check-PythonSyntax -files $files
    Check-NodeSyntax -files $files
}

Write-Host "=== Pre-push Check Summary ===" -ForegroundColor Green
Write-Host ("Errors  : {0}" -f $errors.Count)
Write-Host ("Warnings: {0}" -f $warnings.Count)

if ($errors.Count -gt 0) {
    Write-Host "Pre-push check FAILED." -ForegroundColor Red
    exit 1
}

Write-Host "Pre-push check PASSED." -ForegroundColor Green
exit 0
