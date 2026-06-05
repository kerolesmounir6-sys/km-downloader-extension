#Requires -RunAsAdministrator

$UPDATE_URL = "https://kerolesmounir6-sys.github.io/km-downloader-extension/update.xml"
$EXT_ID     = "ceojdhgfbcnbfdipehfdfalmcpjjnglg"
$NMH_PATH   = "$env:ProgramFiles\KM Downloader\com.km.downloader.json"

$BROWSERS = @(
    @{ Name = "Chrome";  PolicyKey = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\Google\Chrome\NativeMessagingHosts\com.km.downloader"; Process = "chrome.exe";  ExtPage = "chrome://extensions";  CheckPath = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe" }
    @{ Name = "Edge";    PolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\com.km.downloader"; Process = "msedge.exe";  ExtPage = "edge://extensions";    CheckPath = "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe" }
    @{ Name = "Brave";   PolicyKey = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\BraveSoftware\Brave\NativeMessagingHosts\com.km.downloader"; Process = "brave.exe";   ExtPage = "brave://extensions";   CheckPath = "$env:LocalAppData\BraveSoftware\Brave-Browser\Application\brave.exe" }
    @{ Name = "Vivaldi"; PolicyKey = "HKLM:\SOFTWARE\Policies\Vivaldi\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\Vivaldi\NativeMessagingHosts\com.km.downloader"; Process = "vivaldi.exe"; ExtPage = "vivaldi://extensions"; CheckPath = "$env:LocalAppData\Vivaldi\Application\vivaldi.exe" }
    @{ Name = "Opera";   PolicyKey = "HKLM:\SOFTWARE\Policies\Opera Software\Opera\ExtensionInstallForcelist"; NMHKey = "HKLM:\SOFTWARE\Opera Software\Opera\NativeMessagingHosts\com.km.downloader"; Process = "opera.exe";   ExtPage = "opera://extensions";   CheckPath = "$env:ProgramFiles\Opera\launcher.exe" }
)

$ErrorActionPreference = "SilentlyContinue"
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

$installedBrowsers = @()
foreach ($b in $BROWSERS) {
    if (Test-Path $b.CheckPath) {
        $installedBrowsers += $b
    }
}

if ($installedBrowsers.Count -eq 0) {
    Exit
}

$result = [System.Windows.Forms.MessageBox]::Show(
    "The browser will close now to install the extension.`nPlease save your work before continuing.",
    "KM Downloader Setup",
    [System.Windows.Forms.MessageBoxButtons]::OKCancel,
    [System.Windows.Forms.MessageBoxIcon]::Warning
)

if ($result -eq "Cancel") {
    Exit
}

foreach ($b in $installedBrowsers) {
    Stop-Process -Name ($b.Process -replace '\.exe$', '') -Force -ErrorAction SilentlyContinue
}

Start-Sleep -Seconds 1

$successCount = 0
foreach ($b in $BROWSERS) {
    try {
        $null = New-Item -Path $b.PolicyKey -Force -ErrorAction Stop
        $null = New-ItemProperty -Path $b.PolicyKey -Name "1" -Value "$($EXT_ID);$($UPDATE_URL)" -PropertyType String -Force -ErrorAction Stop
        $successCount++
    } catch { }
}

foreach ($b in $BROWSERS) {
    try {
        $null = New-Item -Path $b.NMHKey -Force -ErrorAction Stop
        $null = New-ItemProperty -Path $b.NMHKey -Name "(default)" -Value $NMH_PATH -PropertyType String -Force -ErrorAction Stop
    } catch { }
}

# Chrome/Edge: Forcelist blocked on non-managed devices → use --load-extension
$EXT_SRC = Join-Path $PSScriptRoot "chrome_extension"
$EXT_DEST = "$env:LOCALAPPDATA\KM Downloader\chrome_extension"

if (Test-Path $EXT_SRC) {
    if (Test-Path $EXT_DEST) { Remove-Item $EXT_DEST -Recurse -Force }
    Copy-Item $EXT_SRC $EXT_DEST -Recurse -Force

    $loaderBrowsers = @(
        @{ Name = "Chrome";  Cmd = "chrome.exe";  ShortName = "Google Chrome.lnk";  WinName = "Google Chrome" }
        @{ Name = "Edge";    Cmd = "msedge.exe";   ShortName = "Microsoft Edge.lnk"; WinName = "Microsoft Edge" }
    )

    foreach ($lb in $loaderBrowsers) {
        $bPath = ($BROWSERS | Where-Object { $_.Name -eq $lb.Name }).CheckPath
        if (-not (Test-Path $bPath)) { continue }

        $loadArg = "--load-extension=`"$EXT_DEST`""
        $searched = @{}

        $searchPaths = @(
            [Environment]::GetFolderPath("CommonStartMenu") + "\Programs\$($lb.WinName).lnk"
            [Environment]::GetFolderPath("Desktop") + "\$($lb.WinName).lnk"
            [Environment]::GetFolderPath("CommonDesktop") + "\$($lb.ShortName)"
        )

        foreach ($lnkSrc in $searchPaths) {
            if (-not (Test-Path $lnkSrc)) { continue }
            if ($searched[$lnkSrc]) { continue }
            $searched[$lnkSrc] = $true

            try {
                $shell = New-Object -ComObject WScript.Shell
                $lnk = $shell.CreateShortcut($lnkSrc)
                $oldArgs = $lnk.Arguments
                if ($oldArgs -notmatch "--load-extension") {
                    $lnk.Arguments = "$oldArgs $loadArg".Trim()
                    $lnk.Save()
                }
            } catch { }
        }

        # Create desktop helper
        try {
            $helperPath = "$([Environment]::GetFolderPath('Desktop'))\KM Downloader - $($lb.Name).lnk"
            if (-not (Test-Path $helperPath)) {
                $shell = New-Object -ComObject WScript.Shell
                $lnk = $shell.CreateShortcut($helperPath)
                $lnk.TargetPath = $bPath
                $lnk.Arguments = "--load-extension=`"$EXT_DEST`""
                $lnk.Save()
            }
        } catch { }
    }
}

Start-Sleep -Seconds 2

foreach ($b in $installedBrowsers) {
    Start-Process $b.Process -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
}

if ($successCount -gt 0) {
    Start-Sleep -Seconds 2

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "KM Downloader Setup"
    $form.ClientSize = New-Object System.Drawing.Size(400, 200)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ControlBox = $false
    $form.ShowIcon = $false
    $form.BackColor = [System.Drawing.Color]::White

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Installation Complete"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = "MiddleCenter"
    $titleLabel.Location = New-Object System.Drawing.Point(10, 30)
    $titleLabel.Size = New-Object System.Drawing.Size(380, 40)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(34, 139, 34)
    $form.Controls.Add($titleLabel)

    $messageLabel = New-Object System.Windows.Forms.Label
    $messageLabel.Text = "The extension has been successfully installed.`r`nYour browser will open shortly."
    $messageLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $messageLabel.TextAlign = "MiddleCenter"
    $messageLabel.Location = New-Object System.Drawing.Point(10, 75)
    $messageLabel.Size = New-Object System.Drawing.Size(380, 60)
    $messageLabel.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
    $form.Controls.Add($messageLabel)

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
    $finishButton.Add_Click({ $form.Close() })
    $form.Controls.Add($finishButton)

    $finishButton.Add_MouseEnter({ $finishButton.BackColor = [System.Drawing.Color]::FromArgb(50, 110, 220) })
    $finishButton.Add_MouseLeave({ $finishButton.BackColor = [System.Drawing.Color]::FromArgb(66, 133, 244) })

    $form.ShowDialog() | Out-Null
}

foreach ($b in $installedBrowsers) {
    try {
        Start-Process $b.Process -ArgumentList "--new-window $($b.ExtPage)" -ErrorAction Stop
    } catch { }
    break
}

Exit
