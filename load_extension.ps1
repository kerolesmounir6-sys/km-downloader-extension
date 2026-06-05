#Requires -RunAsAdministrator

$EXT_SRC = "C:\Users\KM Tech\Pictures\New folder\extension_repo_github\chrome_extension"
$EXT_DEST = "$env:LOCALAPPDATA\KM Downloader\chrome_extension"

# ── 1. Copy extension to Program Files ──
Write-Host "[1/4] Copying extension to $EXT_DEST..." -ForegroundColor Yellow
if (Test-Path $EXT_DEST) { Remove-Item $EXT_DEST -Recurse -Force }
Copy-Item $EXT_SRC $EXT_DEST -Recurse -Force
Write-Host "  [OK] Copied" -ForegroundColor Green

# ── 2. Define browsers ──
$BROWSERS = @(
    @{ Name = "Chrome";  ExePath = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe";         StartMenu = "Google Chrome";  SearchPattern = "*chrome*" }
    @{ Name = "Edge";    ExePath = "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe";  StartMenu = "Microsoft Edge"; SearchPattern = "*edge*" }
    @{ Name = "Brave";   ExePath = "$env:LocalAppData\BraveSoftware\Brave-Browser\Application\brave.exe"; StartMenu = "Brave"; SearchPattern = "*brave*" }
    @{ Name = "Vivaldi"; ExePath = "$env:LocalAppData\Vivaldi\Application\vivaldi.exe";           StartMenu = "Vivaldi"; SearchPattern = "*vivaldi*" }
    @{ Name = "Opera";   ExePath = "$env:ProgramFiles\Opera\launcher.exe";                        StartMenu = "Opera"; SearchPattern = "*opera*" }
)

$LOAD_ARG = "--load-extension=`"$EXT_DEST`" --no-first-run --no-default-browser-check"

$modifiedCount = 0

function Modify-Shortcut($shortcutPath, $browserName) {
    if (-not (Test-Path $shortcutPath)) { return $false }
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $existingArgs = $shortcut.Arguments
        if ($existingArgs -match "--load-extension") {
            Write-Host "  [SKIP] $browserName - already configured" -ForegroundColor DarkYellow
            return $true
        }
        $shortcut.Arguments = "$LOAD_ARG $existingArgs".Trim()
        $shortcut.Save()
        Write-Host "  [OK] $browserName - $shortcutPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  [!] $browserName - failed: $_" -ForegroundColor Red
        return $false
    }
}

# ── 3. Scan for shortcuts ──
Write-Host "[2/4] Scanning shortcuts..." -ForegroundColor Yellow

$searchPaths = @(
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
    "$env:AppData\Microsoft\Windows\Start Menu\Programs",
    "$env:Public\Desktop",
    "$env:USERPROFILE\Desktop"
)

$allShortcuts = @()
foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        $allShortcuts += Get-ChildItem -Path $path -Filter "*.lnk" -Recurse -ErrorAction SilentlyContinue
    }
}

$found = @{}
foreach ($b in $BROWSERS) {
    $found[$b.Name] = @()
    $pattern = $b.SearchPattern
    foreach ($sc in $allShortcuts) {
        if ($sc.Name -like $pattern) {
            $found[$b.Name] += $sc.FullName
        }
    }
}

# ── 4. Modify shortcuts ──
Write-Host "[3/4] Modifying shortcuts..." -ForegroundColor Yellow
foreach ($b in $BROWSERS) {
    $installed = Test-Path $b.ExePath
    if (-not $installed) {
        Write-Host "  [!] $($b.Name) - not installed" -ForegroundColor DarkYellow
        continue
    }
    $shortcuts = $found[$b.Name]
    if ($shortcuts.Count -eq 0) {
        Write-Host "  [!] $($b.Name) - no shortcuts found (installed at $($b.ExePath))" -ForegroundColor DarkYellow
    }
    foreach ($scPath in $shortcuts) {
        if (Modify-Shortcut $scPath $b.Name) { $modifiedCount++ }
    }
}

# ── 5. Create helpers ──
Write-Host "[4/4] Creating desktop helpers..." -ForegroundColor Yellow
$shell = New-Object -ComObject WScript.Shell

# Chrome helper
$chromePath = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
if (Test-Path $chromePath) {
    $lnkPath = "$env:USERPROFILE\Desktop\KM Downloader - Chrome.lnk"
    $lnk = $shell.CreateShortcut($lnkPath)
    $lnk.TargetPath = $chromePath
    $lnk.Arguments = $LOAD_ARG
    $lnk.Description = "Chrome with KM Downloader extension"
    $lnk.Save()
    Write-Host "  [OK] Desktop shortcut created: KM Downloader - Chrome" -ForegroundColor Green
}

# Edge helper
$edgePath = "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe"
if (Test-Path $edgePath) {
    $lnkPath = "$env:USERPROFILE\Desktop\KM Downloader - Edge.lnk"
    $lnk = $shell.CreateShortcut($lnkPath)
    $lnk.TargetPath = $edgePath
    $lnk.Arguments = $LOAD_ARG
    $lnk.Description = "Edge with KM Downloader extension"
    $lnk.Save()
    Write-Host "  [OK] Desktop shortcut created: KM Downloader - Edge" -ForegroundColor Green
}

Write-Host "`nDone! Modified $modifiedCount shortcuts." -ForegroundColor Cyan
Write-Host "Use the 'KM Downloader - Chrome' or 'KM Downloader - Edge' desktop shortcuts to open with extension." -ForegroundColor White
Read-Host "`nPress Enter to exit"
