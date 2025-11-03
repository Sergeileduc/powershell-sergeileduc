# Chemin vers le fichier de fonctions gaming
$gamingFunctions = "$env:USERPROFILE\OneDrive\Documents\Scripts\Powershell\backup-games-functions.ps1"

# Charge les fonctions gaming
if (Test-Path $gamingFunctions) {
    . $gamingFunctions
} else {
    Write-Host "❌ Fichier de fonctions introuvable : $gamingFunctions" -ForegroundColor Red
    exit 1
}

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
Backup-GameSaves

Write-Host "`n🎮 Sauvegarde des jeux terminée dans : $backupTimestamped" -ForegroundColor Cyan
