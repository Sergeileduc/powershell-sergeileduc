# Chemin vers le dossier OneDrive Documents
$oneDriveDocs = Join-Path "$env:USERPROFILE\OneDrive\Documents" "Scripts\Powershell"
# Importe les fonctions
Import-Module (Join-Path $oneDriveDocs "SergeBackup")

# Dossier temporaire local
# c'est un peu du bricolage
$staging = "$env:USERPROFILE\TempBackupStaging"
if (Test-Path $staging) {
    Write-Host "🧹 Suppression du dossier temporaire existant..."
    Remove-Item $staging -Recurse -Force
}
Write-Host "📁 Création du dossier temporaire : $staging"
New-Item -ItemType Directory -Path $staging | Out-Null

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
$gameConfig = "$oneDriveDocs\game-saves.yaml"
Backup-GameSaves -configPath $gameConfig


Write-Host "`n🎮 Sauvegarde des jeux terminée dans : $backupTimestamped" -ForegroundColor Cyan
