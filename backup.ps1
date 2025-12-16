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

function Finalize-Backup {
    <#
    .SYNOPSIS
        Finalise une sauvegarde en copiant les fichiers vers un dossier horodaté et un dossier 'latest'.

    .DESCRIPTION
        Cette fonction prend un dossier de staging contenant les fichiers sauvegardés, et les copie dans deux emplacements :
        - Un dossier horodaté (format YYYY-MM-DD_HH-mm) pour archivage
        - Un dossier 'latest' qui reflète la dernière sauvegarde
        Les deux dossiers sont créés dans un répertoire racine, par défaut dans OneDrive.

    .PARAMETER BackupFolder
        Chemin du dossier temporaire contenant les fichiers à sauvegarder.

    .PARAMETER Root
        Répertoire racine dans lequel seront créés les dossiers horodaté et 'latest'. Par défaut : $env:USERPROFILE\OneDrive\Documents\AAA-important\geek\backup.

    .EXAMPLE
        Finalize-Backup -BackupFolder 'C:\Temp\backup-staging'
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$BackupFolder,

        [string]$Root = "$env:USERPROFILE\OneDrive\Documents\AAA-important\geek\backup"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $target = Join-Path $Root $timestamp
    $latest = Join-Path $Root "latest"

    Write-Host "📁 Création du dossier horodaté : $target"
    New-Item -ItemType Directory -Path $target -Force | Out-Null

    Write-Host "📁 Mise à jour du dossier latest : $latest"
    if (Test-Path $latest) {
        Remove-Item $latest -Recurse -Force
    }
    New-Item -ItemType Directory -Path $latest | Out-Null

    Write-Host "🚚 Déplacement du staging vers le dossier horodaté..."
    Copy-Item -Path "$BackupFolder\*" -Destination $target -Recurse -Force

    Write-Host "📋 Copie vers le dossier latest..."
    Copy-Item -Path "$target\*" -Destination $latest -Recurse -Force

    return $target
}

# Chemin vers le dossier OneDrive Documents
$oneDriveDocs = Join-Path "$env:USERPROFILE\OneDrive\Documents" "Scripts\Powershell"
# Importe les fonctions
Import-Module (Join-Path $oneDriveDocs "SergeBackup")

# 📁 Initialisation du dossier de backup/staging
$backupFolder = Init-BackupFolder

# 🔁 Exécution des blocs selon la section
switch ($Section) {
    'env' {
        Invoke-BackupEnv -BackupFolder $backupFolder
        $target = Finalize-Backup -BackupFolder $backupFolder
    }
    'games' {
        Invoke-BackupGames -BackupFolder $backupFolder
        $target = Finalize-Backup -BackupFolder $backupFolder
    }
    "all"   {
        Invoke-BackupEnv -backupFolder $backupFolder
        Invoke-BackupGames -backupFolder $backupFolder
        $target = Finalize-Backup -BackupFolder $backupFolder
    }
}

# Fin du script
$fileCount = (Get-ChildItem -Recurse $target).Count

Write-Host "📊 $fileCount fichiers sauvegardés dans :"
Write-Host "   $target"
