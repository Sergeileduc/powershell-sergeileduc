param (
    [string]$LocalRoot   = "$env:USERPROFILE\MyBackups",
    [string]$Name        = 'games-perso',
    [string]$CloudRoot   = "$env:USERPROFILE\OneDrive\Documents\AAA-important\geek\backup",
    [int]$Rotation       = 2
)

function Finalize-Games {
    param(
        [string]$LocalFolder,
        [string]$CloudRoot,
        [int]$Rotation = 2
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmm"
    $destRoot  = Join-Path $CloudRoot "games"
    $latest    = Join-Path $destRoot "latest"
    $snapshot  = Join-Path $destRoot $timestamp

    Write-Host "🎮 Finalisation GAMES → $latest et $snapshot"

    # Prune le dossier latest avant copie
    if (Test-Path $latest) {
        Remove-Item -LiteralPath $latest -Recurse -Force
        Write-Host "🧹 Dossier latest Games nettoyé."
    }

    foreach ($p in @($latest, $snapshot)) {
        if (-not (Test-Path $p)) {
            New-Item -ItemType Directory -Path $p -Force | Out-Null
        }
    }

    # Copie incrémentale vers latest
    robocopy $LocalFolder $latest /MIR /XO /R:1 /W:1 | Out-Null

    # Copie snapshot horodaté
    robocopy $LocalFolder $snapshot /MIR /R:1 /W:1 | Out-Null

    # Rotation
    $snapshots = Get-ChildItem $destRoot -Directory |
                 Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}_\d{4}$' } |
                 Sort-Object Name
    if ($snapshots.Count -gt $Rotation) {
        $toDelete = $snapshots | Select-Object -First ($snapshots.Count - $Rotation)
        foreach ($d in $toDelete) {
            Write-Host "🗑️ Suppression snapshot ancien : $($d.FullName)"
            Remove-Item $d.FullName -Recurse -Force
        }
    }
}

# ------------------------ Main Script Logic ------------------------------
# Chemin vers le dossier OneDrive Documents
$oneDriveScripts = Join-Path "$env:USERPROFILE\OneDrive\Documents" "Scripts\Powershell"
# Importe les fonctions
Import-Module (Join-Path $oneDriveScripts "SergeBackup")

$localFolder = Join-Path $LocalRoot $Name
if (-not (Test-Path $localFolder)) {
    New-Item -ItemType Directory -Path $localFolder -Force | Out-Null
}
Write-Host "📂 Dossier local de backup : $localFolder" -ForegroundColor Cyan

# Sauvegarde des jeux dans le staging local
$gameConfig = "$env:USERPROFILE\OneDrive\Documents\Scripts\Powershell\game-saves.yaml"
Backup-GameSaves -configPath $gameConfig -stagingRoot $localFolder
Write-Host "`n🎮 Sauvegarde des jeux terminée dans : $localFolder" -ForegroundColor Cyan

# Finalisation vers OneDrive
Finalize-Games -LocalFolder $localFolder -CloudRoot $CloudRoot -Rotation $Rotation
Write-Host "✅ Backup GAMES terminé."
