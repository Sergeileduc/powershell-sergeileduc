param (
    [ValidateSet("env", "games", "all")]
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

# 🔁 Exécution des blocs selon la section
switch ($Section) {
    'env' {
        Invoke-BackupEnv -BackupFolder $backupFolder
    }
    'envappdata' {
        Invoke-BackupEnv -BackupFolder $backupFolder -IncludeAppData
    }
    'games' {
        Invoke-BackupGames -BackupFolder $backupFolder
    }
    "all"   {
        Invoke-BackupGames -BackupFolder $backupFolder
        Invoke-BackupEnv -BackupFolder $backupFolder  -IncludeAppData
    }
}

# Fin du script
$fileCount = (Get-ChildItem -Recurse $target).Count

Write-Host "📊 $fileCount fichiers sauvegardés dans :"
Write-Host "   $target"
