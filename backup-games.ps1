# Chemin vers le dossier OneDrive Documents
$oneDriveDocs = Join-Path "$env:USERPROFILE\OneDrive\Documents" "Scripts\Powershell"
# Importe les fonctions
Import-Module (Join-Path $oneDriveDocs "SergeBackup")

# Timestamp du jour
$timestamp = Get-Date -Format "yyyy-MM-dd"
$root = Join-Path "$env:USERPROFILE\OneDrive\Documents" "AAA-important\geek\backup"
$global:backupTimestamped = Join-Path $root "backup-$timestamp"
$global:backupLatest = Join-Path $root "backup-latest"

# Crée les dossiers si besoin
foreach ($path in @($global:backupTimestamped, $global:backupLatest)) {
    if (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

# Sauvegarde des jeux
$gameConfig = "$oneDriveDocs\game-saves.json"
Backup-GameSaves -configPath $gameConfig


Write-Host "`n🎮 Sauvegarde des jeux terminée dans : $backupTimestamped" -ForegroundColor Cyan
