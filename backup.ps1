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

param (
    [ValidateSet("env", "games", "all")]
    [string]$Section = "all"
)

# 📁 Initialisation du dossier de staging
$backupFolder = Init-BackupFolder

# 🔁 Exécution des blocs selon la section
switch ($Section) {
    "env"   { Invoke-BackupEnv -backupFolder $backupFolder }
    "games" { Invoke-BackupGames -backupFolder $backupFolder }
    "all"   {
        Invoke-BackupEnv -backupFolder (Init-StagingFolder -folderName "env")
        Invoke-BackupGames -backupFolder (Init-StagingFolder -folderName "games")
    }
}
