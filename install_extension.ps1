#Requires -RunAsAdministrator

# ============================================================
#  KM Downloader — Browser Extension Installer (PowerShell)
#  Silent mode - No technical details shown to user
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

# ── Silent mode: No console output ──
$ErrorActionPreference = "SilentlyContinue"

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

# ── Show success message (simple popup) ──
if ($successCount -gt 0) {
    # Create a simple popup using Windows Forms
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "KM Downloader"
    $form.Width = 400
    $form.Height = 250
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ControlBox = $true
    
    # Background color
    $form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
    
    # Icon label
    $iconLabel = New-Object System.Windows.Forms.Label
    $iconLabel.Text = "✅"
    $iconLabel.Font = New-Object System.Drawing.Font("Arial", 48)
    $iconLabel.TextAlign = "MiddleCenter"
    $iconLabel.Location = New-Object System.Drawing.Point(150, 20)
    $iconLabel.Size = New-Object System.Drawing.Size(100, 60)
    $form.Controls.Add($iconLabel)
    
    # Title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "تم التثبيت بنجاح!"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 18, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = "MiddleCenter"
    $titleLabel.Location = New-Object System.Drawing.Point(10, 80)
    $titleLabel.Size = New-Object System.Drawing.Size(380, 40)
    $form.Controls.Add($titleLabel)
    
    # Message label
    $messageLabel = New-Object System.Windows.Forms.Label
    $messageLabel.Text = "تم تثبيت التوسيع في متصفحك.`r`nسيتم فتحه تلقائياً الآن."
    $messageLabel.Font = New-Object System.Drawing.Font("Arial", 12)
    $messageLabel.TextAlign = "MiddleCenter"
    $messageLabel.Location = New-Object System.Drawing.Point(10, 120)
    $messageLabel.Size = New-Object System.Drawing.Size(380, 60)
    $form.Controls.Add($messageLabel)
    
    # OK button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "حسناً"
    $okButton.Font = New-Object System.Drawing.Font("Arial", 12)
    $okButton.Location = New-Object System.Drawing.Point(150, 190)
    $okButton.Size = New-Object System.Drawing.Size(100, 40)
    $okButton.BackColor = [System.Drawing.Color]::FromArgb(66, 133, 244)
    $okButton.ForeColor = [System.Drawing.Color]::White
    $okButton.Cursor = "Hand"
    $okButton.Add_Click({ $form.Close() })
    $form.Controls.Add($okButton)
    
    $form.ShowDialog() | Out-Null
}

# ── Open extensions page ──
if ($toRestart.Count -gt 0) {
    Start-Sleep -Seconds 2
    if ($toRestart[0].Name -eq "Chrome") {
        Start-Process "chrome.exe" -ArgumentList "chrome://extensions" -ErrorAction SilentlyContinue
    } elseif ($toRestart[0].Name -eq "Edge") {
        Start-Process "msedge.exe" -ArgumentList "edge://extensions" -ErrorAction SilentlyContinue
    }
}
