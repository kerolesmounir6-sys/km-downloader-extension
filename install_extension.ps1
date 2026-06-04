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

# ── Step 1: ExtensionInstallForcelist ──
Write-Host "[1/3] Adding ExtensionInstallForcelist..." -ForegroundColor Yellow
foreach ($b in $BROWSERS) {
    $path = $b.PolicyKey
    try {
        $null = New-Item -Path $path -Force -ErrorAction Stop
        $null = New-ItemProperty -Path $path -Name "1" -Value "$($EXT_ID);$($UPDATE_URL)" -PropertyType String -Force -ErrorAction Stop
        Write-Host "  [OK] $($b.Name)" -ForegroundColor Green
    } catch {
        Write-Host "  [!!] $($b.Name) - $_" -ForegroundColor Red
    }
}

# ── Step 2: Native Messaging Hosts ──
Write-Host "[2/3] Adding NativeMessagingHosts..." -ForegroundColor Yellow
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

# ── Step 3: Restart browsers? ──
Write-Host "[3/3] Restart browsers to apply changes?" -ForegroundColor Yellow
Write-Host ""
Write-Host "Select browsers to restart (comma-separated numbers, or A for all, or 0 to skip):" -ForegroundColor White
for ($i = 0; $i -lt $BROWSERS.Count; $i++) {
    $proc = Get-Process -Name ($BROWSERS[$i].Process -replace '\.exe$', '') -ErrorAction SilentlyContinue
    $status = if ($proc) { "RUNNING" } else { "not running" }
    Write-Host "  [$($i+1)] $($BROWSERS[$i].Name)`t($status)" -ForegroundColor $(if ($proc) { "Green" } else { "Gray" })
}
Write-Host "  [A] All browsers"
Write-Host "  [0] Skip restart"
Write-Host ""
$choice = Read-Host "Enter choice"

if ($choice -ne "0") {
    $toRestart = @()
    if ($choice -eq "A" -or $choice -eq "a") {
        $toRestart = $BROWSERS
    } else {
        $indices = $choice -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
        foreach ($i in $indices) {
            $idx = [int]$i - 1
            if ($idx -ge 0 -and $idx -lt $BROWSERS.Count) {
                $toRestart += $BROWSERS[$idx]
            }
        }
    }

    if ($toRestart.Count -gt 0) {
        Write-Host "`nKilling browsers..." -ForegroundColor Yellow
        foreach ($b in $toRestart) {
            Stop-Process -Name ($b.Process -replace '\.exe$', '') -Force -ErrorAction SilentlyContinue
            Write-Host "  [KILLED] $($b.Name)" -ForegroundColor DarkYellow
        }

        Start-Sleep -Seconds 2

        Write-Host "`nRestarting browsers..." -ForegroundColor Green
        $firstBrowser = $toRestart[0]
        foreach ($b in $toRestart) {
            try {
                Start-Process $b.Process -ErrorAction Stop
                Write-Host "  [STARTED] $($b.Name)" -ForegroundColor Green
            } catch {
                Write-Host "  [!] $($b.Name) - not found in PATH" -ForegroundColor DarkYellow
            }
        }

                        # Open extensions page for the first browser
                            try {
                                Start-Process $firstBrowser.Process -ArgumentList "--new-window $($firstBrowser.ExtPage)"
                            } catch { }
    }
}

Write-Host "`nDone!" -ForegroundColor Cyan
Write-Host "Open the extensions page in each browser to verify installation." -ForegroundColor White
Read-Host "`nPress Enter to exit"
