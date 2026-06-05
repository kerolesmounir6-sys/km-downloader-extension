#Requires -RunAsAdministrator

# ============================================================
#  KM Downloader — Browser Extension Installer (PowerShell)
#  Usage: Right-click > "Run with PowerShell" (as Admin)
# ============================================================

$UPDATE_URL = "https://kerolesmounir6-sys.github.io/km-downloader-extension/update.xml"
$EXT_ID     = "ceojdhgfbcnbfdipehfdfalmcpjjnglg"
$NMH_PATH   = "$env:ProgramFiles\KM Downloader\com.km.downloader.json"

$BROWSERS = @(
    @{ Name = "Chrome";  PolicyKey = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\Google\Chrome\NativeMessagingHosts\com.km.downloader"; Process = "chrome.exe"; ExtPage = "chrome://extensions" }
    @{ Name = "Edge";    PolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\com.km.downloader"; Process = "msedge.exe"; ExtPage = "edge://extensions" }
    @{ Name = "Brave";   PolicyKey = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\BraveSoftware\Brave\NativeMessagingHosts\com.km.downloader"; Process = "brave.exe"; ExtPage = "brave://extensions" }
    @{ Name = "Vivaldi"; PolicyKey = "HKLM:\SOFTWARE\Policies\Vivaldi\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\Vivaldi\NativeMessagingHosts\com.km.downloader"; Process = "vivaldi.exe"; ExtPage = "vivaldi://extensions" }
    @{ Name = "Opera";   PolicyKey = "HKLM:\SOFTWARE\Policies\Opera Software\Opera\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\Opera Software\Opera\NativeMessagingHosts\com.km.downloader"; Process = "opera.exe"; ExtPage = "opera://extensions" }
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  KM Downloader - Browser Extension Installer" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Kill all running browsers ──
Write-Host "[1/4] Closing all browsers..." -ForegroundColor Yellow
$browsersClosed = @()
foreach ($b in $BROWSERS) {
    $proc = Get-Process -Name ($b.Process -replace '\.exe$', '') -ErrorAction SilentlyContinue
    if ($proc) {
        Stop-Process -Name ($b.Process -replace '\.exe$', '') -Force -ErrorAction SilentlyContinue
        $browsersClosed += $b.Name
        Write-Host "  [CLOSED] $($b.Name)" -ForegroundColor DarkYellow
    }
}

if ($browsersClosed.Count -eq 0) {
    Write-Host "  [INFO] No browsers running" -ForegroundColor Gray
}

Start-Sleep -Seconds 1

# ── Step 2: ExtensionInstallForcelist ──
Write-Host "`n[2/4] Adding ExtensionInstallForcelist to Registry..." -ForegroundColor Yellow
$successCount = 0
foreach ($b in $BROWSERS) {
    $path = $b.PolicyKey
    try {
        $null = New-Item -Path $path -Force -ErrorAction Stop
        $null = New-ItemProperty -Path $path -Name "1" -Value "$($EXT_ID);$($UPDATE_URL)" -PropertyType String -Force -ErrorAction Stop
        Write-Host "  [OK] $($b.Name)" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "  [!!] $($b.Name) - $_" -ForegroundColor Red
    }
}

# ── Step 3: Native Messaging Hosts ──
Write-Host "`n[3/4] Adding NativeMessagingHosts to Registry..." -ForegroundColor Yellow
foreach ($b in $BROWSERS) {
    $path = $b.NMHKey
    try {
        $null = New-Item -Path $path -Force -ErrorAction Stop
        $null = New-ItemProperty -Path $path -Name "(default)" -Value $NMH_PATH -PropertyType String -Force -ErrorAction Stop
        Write-Host "  [OK] $($b.Name)" -ForegroundColor Green
    } catch {
        Write-Host "  [!] $($b.Name) - may not be installed" -ForegroundColor DarkYellow
    }
}

# ── Step 4: Auto-restart browsers ──
Write-Host "`n[4/4] Restarting browsers..." -ForegroundColor Yellow
Write-Host ""

$toRestart = @()
foreach ($b in $BROWSERS) {
    $path = $b.PolicyKey
    if (Test-Path $path) {
        $toRestart += $b
    }
}

if ($toRestart.Count -gt 0) {
    Start-Sleep -Seconds 2
    
    foreach ($b in $toRestart) {
        try {
            Start-Process $b.Process -ErrorAction SilentlyContinue
            Write-Host "  [STARTED] $($b.Name)" -ForegroundColor Green
            Start-Sleep -Seconds 1
        } catch {
            Write-Host "  [!] $($b.Name) - not found in PATH" -ForegroundColor DarkYellow
        }
    }
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  ✅ Installation Completed Successfully!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Registry keys written:     $successCount browser(s)" -ForegroundColor Green
    Write-Host "  Browsers restarted:        $($toRestart.Count)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Your browsers are restarting now..." -ForegroundColor Cyan
    Write-Host "  The extension will load automatically in a few moments." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Check the extensions page:" -ForegroundColor White
    Write-Host "  Chrome: chrome://extensions" -ForegroundColor White
    Write-Host "  Edge:   edge://extensions" -ForegroundColor White
    Write-Host "  Brave:  brave://extensions" -ForegroundColor White
    Write-Host ""
    
    # Open extensions page for the first browser
    Start-Sleep -Seconds 3
    if ($toRestart[0].Name -eq "Chrome") {
        Start-Process "chrome.exe" -ArgumentList "chrome://extensions" -ErrorAction SilentlyContinue
    } elseif ($toRestart[0].Name -eq "Edge") {
        Start-Process "msedge.exe" -ArgumentList "edge://extensions" -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "  [ERROR] No browsers configured in Registry" -ForegroundColor Red
}

Write-Host "`nPress Enter to exit..." -ForegroundColor Cyan
Read-Host
