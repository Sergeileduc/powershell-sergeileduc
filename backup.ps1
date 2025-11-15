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
$staging = Init-StagingFolder -folderName $Section

# 🔁 Exécution des blocs selon la section
switch ($Section) {
    "env"   { Invoke-BackupEnv -stagingRoot $staging }
    "games" { Invoke-BackupGames -stagingRoot $staging }
    "all"   {
        Invoke-BackupEnv -stagingRoot (Init-StagingFolder -folderName "env")
        Invoke-BackupGames -stagingRoot (Init-StagingFolder -folderName "games")
    }
}
