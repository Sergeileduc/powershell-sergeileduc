Add-Type -AssemblyName System.Windows.Forms

# Crée la fenêtre principale
$form = New-Object Windows.Forms.Form
$form.Text = "🛡️ Backup Dev Environment"
$form.Width = 420
$form.Height = 240
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Crée le bouton de lancement
$button = New-Object Windows.Forms.Button
$button.Text = "🛠️ Lancer la sauvegarde"
$button.Width = 200
$button.Height = 40
$button.Top = 30
$button.Left = 110

# Crée la zone de log
$logBox = New-Object Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ReadOnly = $true
$logBox.ScrollBars = "Vertical"
$logBox.Width = 380
$logBox.Height = 100
$logBox.Top = 90
$logBox.Left = 10
$logBox.Font = 'Consolas,10'

# Action du bouton
$button.Add_Click({
    $logBox.AppendText("⏳ Sauvegarde en cours..." + [Environment]::NewLine)

    $scriptPath = Join-Path $env:USERPROFILE "OneDrive\Documents\Scripts\Powershell\backup-ultime.ps1"

    if (Test-Path $scriptPath) {
        try {
            & $scriptPath
            $logBox.AppendText("✅ Sauvegarde terminée." + [Environment]::NewLine)
        } catch {
            $logBox.AppendText("❌ Erreur pendant l’exécution : $($_.Exception.Message)" + [Environment]::NewLine)
        }
    } else {
        $logBox.AppendText("❌ Script introuvable : $scriptPath" + [Environment]::NewLine)
    }
})

# Ajoute les éléments à la fenêtre
$form.Controls.Add($button)
$form.Controls.Add($logBox)

# Affiche la fenêtre
$form.ShowDialog()
