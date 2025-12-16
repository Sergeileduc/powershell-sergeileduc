# BackupLauncher.ps1 — minimal WinForms GUI for backup tasks

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Start-BackupEnv {
    & "$PSScriptRoot\backup.ps1" -Section env
}

function Start-BackupEnvAppData {
    & "$PSScriptRoot\backup.ps1" -Section envappdata
}

function Start-BackupGames {
    & "$PSScriptRoot\backup.ps1" -Section games
}

function Start-BackupAll {
    & "$PSScriptRoot\backup.ps1" -Section all
}


# --- Helpers ---
function Invoke-Backup {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [scriptblock]$Action,
        [System.Windows.Forms.Label]$StatusLabel,
        [System.Windows.Forms.TextBox]$LogBox,
        [System.Windows.Forms.Form]$Form,
        [System.Windows.Forms.Button[]]$Buttons
    )

    # Disable UI during run
    foreach ($b in $Buttons) { $b.Enabled = $false }
    $Form.UseWaitCursor = $true
    $StatusLabel.Text = "Running: $Name …"

    try {
        $start = Get-Date
        # Capture all output (stdout+stderr) to append in the log box
        $output = & $Action 2>&1
        if ($output) {
            $LogBox.AppendText( ([string]::Join([Environment]::NewLine, $output)) + [Environment]::NewLine )
        }
        $elapsed = (Get-Date) - $start
        $StatusLabel.Text = "Done: $Name ($( [math]::Round($elapsed.TotalSeconds,1) ) s)"
    } catch {
        $StatusLabel.Text = "Error: $Name"
        $LogBox.AppendText("[ERROR] $($_.Exception.Message)" + [Environment]::NewLine)
    } finally {
        $Form.UseWaitCursor = $false
        foreach ($b in $Buttons) { $b.Enabled = $true }
    }
}

function Resolve-Task {
    param([string]$FuncName)
    if (Get-Command $FuncName -ErrorAction SilentlyContinue) {
        return (Get-Item "Function:\$FuncName").ScriptBlock
    }
    else {
        return { Write-Output "Function '$FuncName' not found. Please define it before running the GUI." }
    }
}

# --- UI ---
$form              = New-Object System.Windows.Forms.Form
$form.Text         = "Backup launcher"
$form.Size         = New-Object System.Drawing.Size(600,430)
$form.StartPosition= "CenterScreen"

$btnEnv            = New-Object System.Windows.Forms.Button
$btnEnv.Text       = "Backup env"
$btnEnv.Size       = New-Object System.Drawing.Size(260,40)
$btnEnv.Location   = New-Object System.Drawing.Point(20,20)

$btnEnvApp         = New-Object System.Windows.Forms.Button
$btnEnvApp.Text    = "Backup env + AppData"
$btnEnvApp.Size    = New-Object System.Drawing.Size(260,40)
$btnEnvApp.Location= New-Object System.Drawing.Point(300,20)

$btnGames          = New-Object System.Windows.Forms.Button
$btnGames.Text     = "Backup games"
$btnGames.Size     = New-Object System.Drawing.Size(260,40)
$btnGames.Location = New-Object System.Drawing.Point(20,70)

$btnAll            = New-Object System.Windows.Forms.Button
$btnAll.Text       = "Backup all"
$btnAll.Size       = New-Object System.Drawing.Size(260,40)
$btnAll.Location   = New-Object System.Drawing.Point(300,70)

$logBox            = New-Object System.Windows.Forms.TextBox
$logBox.Multiline  = $true
$logBox.ScrollBars = "Vertical"
$logBox.ReadOnly   = $true
$logBox.Font       = New-Object System.Drawing.Font("Consolas", 10)
$logBox.Size       = New-Object System.Drawing.Size(540,250)
$logBox.Location   = New-Object System.Drawing.Point(20,120)

$statusLabel       = New-Object System.Windows.Forms.Label
$statusLabel.Text  = "Idle"
$statusLabel.AutoSize = $true
$statusLabel.Location  = New-Object System.Drawing.Point(20,380)

$form.Controls.AddRange(@($btnEnv,$btnEnvApp,$btnGames,$btnAll,$logBox,$statusLabel))

# --- Wire buttons ---
$buttons = @($btnEnv,$btnEnvApp,$btnGames,$btnAll)

$btnEnv.Add_Click({
    $action = Resolve-Task -FuncName 'Start-BackupEnv'
    Invoke-Backup -Name 'env' -Action $action -StatusLabel $statusLabel -LogBox $logBox -Form $form -Buttons $buttons
})

$btnEnvApp.Add_Click({
    $action = Resolve-Task -FuncName 'Start-BackupEnvAppData'
    Invoke-Backup -Name 'env + AppData' -Action $action -StatusLabel $statusLabel -LogBox $logBox -Form $form -Buttons $buttons
})

$btnGames.Add_Click({
    $action = Resolve-Task -FuncName 'Start-BackupGames'
    Invoke-Backup -Name 'games' -Action $action -StatusLabel $statusLabel -LogBox $logBox -Form $form -Buttons $buttons
})

$btnAll.Add_Click({
    $action = Resolve-Task -FuncName 'Start-BackupAll'
    Invoke-Backup -Name 'all' -Action $action -StatusLabel $statusLabel -LogBox $logBox -Form $form -Buttons $buttons
})

# --- Show ---
[void]$form.ShowDialog()
