<#
.SYNOPSIS
    Obsidian Libraries — Vault Cloner for Windows
    Clones selected vaults into %USERPROFILE%\Documents\Obsidian Libraries

.DESCRIPTION
    This script downloads the Obsidian Libraries catalog, presents you with
    a list of available vaults, and copies your selection into your Documents
    folder for use in Obsidian.

.NOTES
    Requires PowerShell 5.0 or later and Git for Windows.
    Run with:  .\clone-vault.ps1
#>

$ErrorActionPreference = "Stop"
$RepoUrl = "https://github.com/Winters-Glade/Obsidian-Libraries.git"
$RepoName = "Obsidian-Libraries"
$DestBase = Join-Path $env:USERPROFILE "Documents" "Obsidian Libraries"
$TempDir = Join-Path $env:TEMP "$RepoName-$([System.IO.Path]::GetRandomFileName())"

Write-Host "══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   🏛️  Obsidian Libraries — Vault Cloner" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check for git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Error: git is not installed." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Download it from: https://git-scm.com/"
    Write-Host ""
    Write-Host "After installing, restart PowerShell and run this script again."
    pause
    exit 1
}

# Step 1 — Clone (shallow) to temp
Write-Host "📥 Downloading vault catalog... " -NoNewline
git clone --depth 1 --quiet $RepoUrl $TempDir 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "failed!" -ForegroundColor Red
    Write-Host "Check your internet connection and try again." -ForegroundColor Yellow
    pause
    exit 1
}
Write-Host "done ✓" -ForegroundColor Green
Write-Host ""

# Step 2 — List available vaults
$Vaults = Get-ChildItem -Path $TempDir -Directory | Where-Object { $_.Name -notmatch '^\.' -and $_.Name -ne 'scripts' } | Sort-Object Name
Write-Host "📚 Available Vaults:" -ForegroundColor Cyan
Write-Host ""

$Index = 1
$VaultList = @()
foreach ($vault in $Vaults) {
    $desc = ""
    $readme = Join-Path $vault.FullName "README.md"
    if (Test-Path $readme) {
        $content = Get-Content $readme -TotalCount 5 -ErrorAction SilentlyContinue
        $match = $content | Select-String '^> ' | Select-Object -First 1
        if ($match) {
            $desc = $match.ToString().Substring(2)
        }
    }
    if ([string]::IsNullOrEmpty($desc)) {
        $fileCount = (Get-ChildItem -Path $vault.FullName -Filter "*.md" -File).Count
        $desc = "$fileCount markdown files"
    }
    Write-Host "  $Index. $($vault.Name) — $desc"
    $VaultList += $vault
    $Index++
}
Write-Host ""

# Step 3 — Let user choose
$Selection = Read-Host "Enter the number(s) of the vault(s) you want (e.g., 1, '1 3', or 'all')"
Write-Host ""

$SelectedVaults = @()
if ($Selection -eq "all") {
    $SelectedVaults = $VaultList
} else {
    $Selection.Split(' ', ',') | ForEach-Object {
        $num = $_ -as [int]
        if ($num -and $num -ge 1 -and $num -le $VaultList.Count) {
            $SelectedVaults += $VaultList[$num - 1]
        }
    }
}

if ($SelectedVaults.Count -eq 0) {
    Write-Host "No valid vaults selected. Exiting." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
    pause
    exit 0
}

Write-Host "📋 Copying $($SelectedVaults.Count) vault(s) to $DestBase ..." -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $DestBase)) {
    New-Item -ItemType Directory -Path $DestBase -Force | Out-Null
}

foreach ($vault in $SelectedVaults) {
    $target = Join-Path $DestBase $vault.Name
    Write-Host "  $($vault.Name) ... " -NoNewline
    if (Test-Path $target) {
        Write-Host "already exists, skipping." -ForegroundColor Yellow
    } else {
        Copy-Item -Recurse $vault.FullName $target
        Write-Host "done ✓" -ForegroundColor Green
    }
}

Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "✅ All done! Your vault(s) are in: $DestBase" -ForegroundColor Green
Write-Host ""
Write-Host "📖 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open Obsidian"
Write-Host "  2. Click the folder icon (Open another vault) in the bottom-left"
Write-Host "  3. Select 'Open folder as vault'"
Write-Host "  4. Navigate to: $DestBase"
Write-Host "  5. Pick the vault folder and open it"
Write-Host ""
Write-Host "🔄 To update later, re-run this script."
Write-Host ""

# Open the destination in File Explorer
if (Test-Path $DestBase) {
    Invoke-Item $DestBase
}

pause
