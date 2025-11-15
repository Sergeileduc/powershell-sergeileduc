# Chemin vers le dossier OneDrive Documents
$oneDriveDocs = Join-Path "$env:USERPROFILE\OneDrive\Documents" "Scripts\Powershell"
# Importe les fonctions
Import-Module (Join-Path $oneDriveDocs "SergeBackup")

# Dossier temporaire local
$staging = Init-StagingFolder -customPath "$env:USERPROFILE"

# Sauvegarde des jeux
$gameConfig = "$oneDriveDocs\game-saves.yaml"
Backup-GameSaves -configPath $gameConfig -stagingRoot $staging

Write-Host "`n🎮 Sauvegarde des jeux terminée dans : $staging" -ForegroundColor Cyan
