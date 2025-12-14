param (
    [ValidateSet("env", "envappdata", "games", "all")]
    [string]$Section = "all"
)

<#
.SYNOPSIS
    Script principal de sauvegarde modulaire : environnement, jeux, ou les deux.

.DESCRIPTION
    Ce script permet de lancer la sauvegarde des fichiers de configuration, de l’environnement,
    et des sauvegardes de jeux selon un paramètre `-Section`. Chaque section utilise son propre dossier
    de staging et de destination (`latest` et horodaté), évitant les conflits.

.PARAMETER Section
    Choix de la section à sauvegarder : "env", "games", ou "all".

.EXAMPLE
    .\backup.ps1 -Section env
    .\backup.ps1 -Section games
    .\backup.ps1 -Section all
#>

# Chemin vers le dossier OneDrive Documents
$oneDriveScripts = Join-Path "$env:USERPROFILE\OneDrive\Documents" "Scripts\Powershell"
# Importe les fonctions
Import-Module (Join-Path $oneDriveScripts "SergeBackup")

# 📁 Initialisation du dossier de backup/staging
$backupFolder = Init-BackupFolder -folderName "MyBackups"

# 📁 Dossier final de destination des backups -> à changer selon vos préférences
$CloudDir = "$env:USERPROFILE\OneDrive\Documents\AAA-important\geek\backup"

# 🔁 Exécution des blocs selon la section
switch ($Section) {
    'env' {
        Invoke-BackupEnv -LocalRoot $backupFolder -Name "env-perso" -CloudRoot $CloudDir
    }
    'envappdata' {
        Invoke-BackupEnv -LocalRoot $backupFolder -Name "env-perso" -CloudRoot $CloudDir -IncludeAppData
    }
    'games' {
        Invoke-BackupGames -LocalRoot $backupFolder -Name "games-perso" -CloudRoot $CloudDir
    }
    "all"   {
        Invoke-BackupGames -LocalRoot $backupFolder -Name "games-perso" -CloudRoot $CloudDir
        Invoke-BackupEnv -LocalRoot $backupFolder -Name "env-perso" -CloudRoot $CloudDir -IncludeAppData
    }
}

# Fin du script
$fileCount = (Get-ChildItem -Recurse "$CloudDir\").Count

Write-Host "Fin du backup. Total fichiers sauvegardés : $fileCount" -ForegroundColor Green
