# Chemin vers le dossier OneDrive Documents
$oneDriveDocs = Join-Path "$env:USERPROFILE\OneDrive\Documents" "Scripts\Powershell"
# Importe les fonctions
Import-Module (Join-Path $oneDriveDocs "SergeBackup")

# Dossier de backup local
if (-not $BackupFolder) {
    $BackupFolder = Init-BackupFolder -Name $Name -Path $Path
}
Write-Host "📂 Dossier de backup créé : $backupFolder" -ForegroundColor Cyan

# Sauvegarde des jeux
$gameConfig = "$oneDriveDocs\game-saves.yaml"
Backup-GameSaves -configPath $gameConfig -stagingRoot $backupFolder

Write-Host "`n🎮 Sauvegarde des jeux terminée dans : $backupFolder" -ForegroundColor Cyan
