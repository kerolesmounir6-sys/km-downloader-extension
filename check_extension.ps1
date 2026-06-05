#Requires -RunAsAdministrator

$EXT_ID   = "ceojdhgfbcnbfdipehfdfalmcpjjnglg"
$UPDATE_URL = "https://kerolesmounir6-sys.github.io/km-downloader-extension/update.xml"

$BROWSERS = @(
    @{ Name = "Chrome";  PolicyKey = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\Google\Chrome\NativeMessagingHosts\com.km.downloader"; Process = "chrome.exe";  CheckPath = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe" }
    @{ Name = "Edge";    PolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\com.km.downloader"; Process = "msedge.exe";  CheckPath = "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe" }
    @{ Name = "Brave";   PolicyKey = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\BraveSoftware\Brave\NativeMessagingHosts\com.km.downloader"; Process = "brave.exe";   CheckPath = "$env:LocalAppData\BraveSoftware\Brave-Browser\Application\brave.exe" }
    @{ Name = "Vivaldi"; PolicyKey = "HKLM:\SOFTWARE\Policies\Vivaldi\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\Vivaldi\NativeMessagingHosts\com.km.downloader"; Process = "vivaldi.exe"; CheckPath = "$env:LocalAppData\Vivaldi\Application\vivaldi.exe" }
    @{ Name = "Opera";   PolicyKey = "HKLM:\SOFTWARE\Policies\Opera Software\Opera\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\Opera Software\Opera\NativeMessagingHosts\com.km.downloader"; Process = "opera.exe";   CheckPath = "$env:ProgramFiles\Opera\launcher.exe" }
)

$ErrorActionPreference = "SilentlyContinue"
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

$form = New-Object System.Windows.Forms.Form
$form.Text = "KM Downloader - Extension Check"
$form.ClientSize = New-Object System.Drawing.Size(520, 480)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.ControlBox = $false
$form.ShowIcon = $false
$form.BackColor = [System.Drawing.Color]::White

$header = New-Object System.Windows.Forms.Label
$header.Text = "Extension Installation Report"
$header.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$header.TextAlign = "MiddleCenter"
$header.Location = New-Object System.Drawing.Point(10, 15)
$header.Size = New-Object System.Drawing.Size(500, 35)
$header.ForeColor = [System.Drawing.Color]::FromArgb(33, 33, 33)
$form.Controls.Add($header)

$y = 60

foreach ($b in $BROWSERS) {
    $installed = Test-Path $b.CheckPath
    $policyExists = $false
    $policyValue = $null
    $nmhExists = $false

    try { $policyValue = (Get-ItemProperty -Path $b.PolicyKey -Name "1" -ErrorAction Stop)."1"; $policyExists = $true } catch {}
    try { $nmhExists = Test-Path $b.NMHKey } catch {}

    $bgColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
    $borderColor = [System.Drawing.Color]::FromArgb(220, 220, 220)

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(15, $y)
    $panel.Size = New-Object System.Drawing.Size(490, 60)
    $panel.BackColor = $bgColor
    $panel.BorderStyle = "FixedSingle"
    $form.Controls.Add($panel)

    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Text = "$($b.Name)"
    $nameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $nameLabel.Location = New-Object System.Drawing.Point(10, 5)
    $nameLabel.Size = New-Object System.Drawing.Size(80, 25)
    $nameLabel.ForeColor = [System.Drawing.Color]::FromArgb(33, 33, 33)
    $panel.Controls.Add($nameLabel)

    $browserIcon = if ($installed) { "INSTALLED" } else { "NOT FOUND" }
    $browserColor = if ($installed) { [System.Drawing.Color]::FromArgb(34, 139, 34) } else { [System.Drawing.Color]::FromArgb(180, 180, 180) }
    $browserStatus = New-Object System.Windows.Forms.Label
    $browserStatus.Text = $browserIcon
    $browserStatus.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Regular)
    $browserStatus.Location = New-Object System.Drawing.Point(10, 30)
    $browserStatus.Size = New-Object System.Drawing.Size(80, 20)
    $browserStatus.ForeColor = $browserColor
    $panel.Controls.Add($browserStatus)

    $regIcon = if ($policyExists) { "Policy: OK" } else { "Policy: MISSING" }
    $regColor = if ($policyExists) { [System.Drawing.Color]::FromArgb(34, 139, 34) } else { [System.Drawing.Color]::FromArgb(200, 50, 50) }
    $regLabel = New-Object System.Windows.Forms.Label
    $regLabel.Text = $regIcon
    $regLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $regLabel.Location = New-Object System.Drawing.Point(110, 5)
    $regLabel.Size = New-Object System.Drawing.Size(130, 20)
    $regLabel.ForeColor = $regColor
    $panel.Controls.Add($regLabel)

    $nmhIcon = if ($nmhExists) { "NMH: OK" } else { "NMH: MISSING" }
    $nmhColor = if ($nmhExists) { [System.Drawing.Color]::FromArgb(34, 139, 34) } else { [System.Drawing.Color]::FromArgb(200, 50, 50) }
    $nmhLabel = New-Object System.Windows.Forms.Label
    $nmhLabel.Text = $nmhIcon
    $nmhLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $nmhLabel.Location = New-Object System.Drawing.Point(110, 28)
    $nmhLabel.Size = New-Object System.Drawing.Size(130, 20)
    $nmhLabel.ForeColor = $nmhColor
    $panel.Controls.Add($nmhLabel)

    $extIdLabel = New-Object System.Windows.Forms.Label
    $extIdLabel.Text = "ID: $EXT_ID"
    $extIdLabel.Font = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Regular)
    $extIdLabel.Location = New-Object System.Drawing.Point(260, 5)
    $extIdLabel.Size = New-Object System.Drawing.Size(220, 20)
    $extIdLabel.ForeColor = [System.Drawing.Color]::FromArgb(120, 120, 120)
    $panel.Controls.Add($extIdLabel)

    $urlLabel = New-Object System.Windows.Forms.Label
    $urlLabel.Text = "URL: $UPDATE_URL"
    $urlLabel.Font = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Regular)
    $urlLabel.Location = New-Object System.Drawing.Point(260, 25)
    $urlLabel.Size = New-Object System.Drawing.Size(220, 30)
    $urlLabel.ForeColor = [System.Drawing.Color]::FromArgb(120, 120, 120)
    $panel.Controls.Add($urlLabel)

    $y += 70
}

$networkPanel = New-Object System.Windows.Forms.Panel
$networkPanel.Location = New-Object System.Drawing.Point(15, $y + 5)
$networkPanel.Size = New-Object System.Drawing.Size(490, 70)
$networkPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 248, 255)
$networkPanel.BorderStyle = "FixedSingle"
$form.Controls.Add($networkPanel)

$netLabel = New-Object System.Windows.Forms.Label
$netLabel.Text = "Network Test"
$netLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$netLabel.Location = New-Object System.Drawing.Point(10, 8)
$netLabel.Size = New-Object System.Drawing.Size(200, 20)
$netLabel.ForeColor = [System.Drawing.Color]::FromArgb(33, 33, 33)
$networkPanel.Controls.Add($netLabel)

try {
    $req = [System.Net.WebRequest]::Create($UPDATE_URL)
    $req.Method = "HEAD"
    $req.Timeout = 5000
    $resp = $req.GetResponse()
    $statusCode = [int]$resp.StatusCode
    $resp.Close()
    if ($statusCode -eq 200) {
        $netStatus = "ONLINE (HTTP $statusCode)"
        $netColor = [System.Drawing.Color]::FromArgb(34, 139, 34)
    } else {
        $netStatus = "HTTP $statusCode"
        $netColor = [System.Drawing.Color]::FromArgb(200, 150, 50)
    }
} catch {
    $netStatus = "OFFLINE - GitHub Pages not active"
    $netColor = [System.Drawing.Color]::FromArgb(200, 50, 50)
}

$netResult = New-Object System.Windows.Forms.Label
$netResult.Text = $netStatus
$netResult.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$netResult.Location = New-Object System.Drawing.Point(10, 35)
$netResult.Size = New-Object System.Drawing.Size(460, 25)
$netResult.ForeColor = $netColor
$networkPanel.Controls.Add($netResult)

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close"
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$closeButton.Location = New-Object System.Drawing.Point(210, $y + 85)
$closeButton.Size = New-Object System.Drawing.Size(100, 35)
$closeButton.BackColor = [System.Drawing.Color]::FromArgb(66, 133, 244)
$closeButton.ForeColor = [System.Drawing.Color]::White
$closeButton.Cursor = "Hand"
$closeButton.FlatStyle = "Flat"
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.Add_Click({ $form.Close() })
$form.Controls.Add($closeButton)

$closeButton.Add_MouseEnter({ $closeButton.BackColor = [System.Drawing.Color]::FromArgb(50, 110, 220) })
$closeButton.Add_MouseLeave({ $closeButton.BackColor = [System.Drawing.Color]::FromArgb(66, 133, 244) })

$form.ShowDialog() | Out-Null
