Import-Module powershell-yaml

# 💾=============================
# Function: Save-Text
# ===============================
<#
.SYNOPSIS
Sauvegarde du contenu texte dans un fichier cible.

.DESCRIPTION
Cette fonction prend une chaîne de texte et l’écrit dans un fichier à l’emplacement spécifié.
Elle crée automatiquement le dossier parent si nécessaire, et encode le fichier en UTF-8.

.PARAMETER content
Le contenu texte à sauvegarder. Peut être une chaîne simple ou multi-ligne.

.PARAMETER targetPath
Chemin absolu ou relatif du fichier dans lequel le contenu sera écrit.

.EXAMPLE
Save-Text -content "Hello world" -targetPath "backup\latest\hello.txt"

.EXAMPLE
Save-Text -content "choco list --local-only" -targetPath "backup\packages\choco.txt"

.NOTES
Le dossier parent est créé automatiquement si absent. Le fichier est écrasé s’il existe déjà.
#>
function Save-Text {
    param (
        [Parameter(Mandatory = $true)]
        [string]$content,

        [Parameter(Mandatory = $true)]
        [string]$targetPath
    )

    $parent = Split-Path $targetPath -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    try {
        $content | Out-File -FilePath $targetPath -Encoding UTF8
    } catch {
        Write-Error "💥 Échec de l'écriture dans '$targetPath' : $_"
    }
}

# 💾=============================
# Function: Save-Item
# ===============================
<#
.SYNOPSIS
Copie un fichier ou un dossier vers un chemin de destination.

.DESCRIPTION
Cette fonction prend un chemin source (fichier ou dossier) et le copie vers un chemin cible.
Elle gère la récursivité pour les dossiers et force l'écrasement si le fichier ou dossier existe déjà.

.PARAMETER sourcePath
Chemin absolu du fichier ou dossier à sauvegarder.

.PARAMETER targetPath
Chemin absolu ou relatif vers lequel le contenu doit être copié.

.EXAMPLE
Save-Item -sourcePath "C:\Users\Serge\Documents\config.json" -targetPath "backup\latest\config.json"

.EXAMPLE
Save-Item -sourcePath "C:\Users\Serge\.config" -targetPath "backup\archive\dotfiles"

.NOTES
Ne vérifie pas si le type est fichier ou dossier — utilise Copy-Item avec -Recurse pour tout.
#>
function Save-Item {
    param (
        [Parameter(Mandatory = $true)]
        [string]$sourcePath,

        [Parameter(Mandatory = $true)]
        [string]$targetPath
    )

    # --- Guard clause : si le fichier n'existe pas, on sort
    if (-not (Test-Path $sourcePath)) {
        Write-Host "⚠️ Pas trouvé : $sourcePath" -ForegroundColor Yellow
        return
    }

    # --- Comportement normal (pas besoin de else)
    try {
        Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
    } catch {
        Write-Error "💥 Échec de la copie de '$sourcePath' vers '$targetPath' : $_"
    }

  Write-Host "✅ Sauvegarde : $relativeTarget" -ForegroundColor Green
}

# 💾=============================
# Function: Save-ItemWithExclusions
# ===============================
<#
.SYNOPSIS
Copie un dossier en excluant certains fichiers ou sous-dossiers.

.DESCRIPTION
Cette fonction copie récursivement le contenu d’un dossier source vers un dossier cible,
en excluant les fichiers ou dossiers dont le nom correspond à ceux spécifiés dans -exclusions.

Le dossier cible est créé automatiquement si nécessaire. Les exclusions sont basées sur le nom exact
(pas de wildcards ni de correspondance partielle).

.PARAMETER sourcePath
Chemin du dossier source à copier.

.PARAMETER targetPath
Chemin du dossier de destination.

.PARAMETER exclusions
Liste de noms de fichiers ou dossiers à exclure (exact match).

.EXAMPLE
Save-ItemWithExclusions -sourcePath "$env:USERPROFILE\.ssh" -targetPath "$staging\ssh" -exclusions @("known_hosts", "config.old")

.NOTES
Les exclusions ne s’appliquent que sur le nom (pas le chemin complet).
#>
function Save-ItemWithExclusions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$sourcePath,

        [Parameter(Mandatory = $true)]
        [string]$targetPath,

        [string[]]$exclusions
    )

    # --- Guard clause : si le fichier n'existe pas, on sort
    if (-not (Test-Path $sourcePath)) {
        Write-Host "⚠️ Pas trouvé : $sourcePath" -ForegroundColor Yellow
        return
    }

    # --- Comportement normal (pas besoin de else)
    $items = Get-ChildItem -Path $sourcePath -Recurse

    # Exclusion magique : ignore l'élément si son nom ou son chemin correspond à une règle d'exclusion.
    # Gère les cas où les fichiers sont dans des sous-dossiers (genre "bin/flyctl.exe").
    foreach ($item in $items) {
        if ($exclusions | Where-Object { 
            $_ -ieq $item.Name -or 
            $item.FullName -like "*\$_" -or 
            $item.FullName -like "*\$_\*" -or 
            $item.FullName -like "*\$_.*"
        }) {
            continue
        }

        $relative = $item.FullName.Substring($sourcePath.Length).TrimStart("\")
        $dest = Join-Path $targetPath $relative
        $destParent = Split-Path $dest -Parent

        if (-not (Test-Path $destParent)) {
            New-Item -ItemType Directory -Path $destParent -Force | Out-Null
        }

        Copy-Item -Path $item.FullName -Destination $dest -Force
    }
}

# 💾=============================
# Function: Save
# ===============================
<#
.SYNOPSIS
Sauvegarde du contenu texte ou copie d’un fichier/dossier, avec exclusions optionnelles.

.DESCRIPTION
Cette fonction unifie trois comportements :
- Si -textContent est fourni, écrit le texte dans le fichier cible.
- Si -sourcePath est fourni sans exclusions, copie le fichier ou dossier vers le chemin cible.
- Si -sourcePath et -exclusions sont fournis, délègue à Save-ItemWithExclusions pour filtrer les fichiers.

Le dossier parent est créé automatiquement si nécessaire.

.PARAMETER textContent
Contenu texte à écrire dans le fichier cible.

.PARAMETER sourcePath
Fichier ou dossier à copier.

.PARAMETER targetPath
Chemin absolu ou relatif du fichier ou dossier de destination.

.PARAMETER exclusions
Liste de noms de fichiers/dossiers à exclure (exact match).

.EXAMPLE
Save -textContent "Hello world" -targetPath "$staging\notes\hello.txt"

.EXAMPLE
Save -sourcePath "$env:USERPROFILE\.ssh" -targetPath "$staging\ssh" -exclusions @("known_hosts", "config.old")

.NOTES
Le paramètre -textContent a priorité sur -sourcePath.
#>
function Save {
    param (
        [string]$sourcePath,
        [string]$textContent,
        [Parameter(Mandatory = $true)]
        [string]$targetPath,
        [string[]]$exclusions
    )

    $parent = Split-Path $targetPath -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if ($textContent) {
        try {
            $textContent | Out-File -FilePath $targetPath -Encoding UTF8
        } catch {
            Write-Error "💥 Échec de l'écriture dans '$targetPath' : $_"
        }
        return
    }

    # --- Guard clause : si le fichier n'existe pas, on sort
    if (-not (Test-Path $sourcePath)) {
        Write-Host "⚠️ Pas trouvé : $sourcePath" -ForegroundColor Yellow
        Write-Warning "⚠️ Aucun contenu à sauvegarder : ni -textContent ni -sourcePath n'ont été fournis."
        return
    }

    # --- Comportement normal (pas besoin de else)
    if ($exclusions) {
        Save-ItemWithExclusions -sourcePath $sourcePath -targetPath $targetPath -exclusions $exclusions
    }
    else {
        try {
            Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
        } catch {
            Write-Error "💥 Échec de la copie de '$sourcePath' vers '$targetPath' : $_"
        }
    }
}


<#
.SYNOPSIS
Copie tous les fichiers .env* depuis un dossier source vers un dossier cible, en conservant la structure relative.

.DESCRIPTION
Parcourt récursivement le dossier source à la recherche de fichiers `.env*` (ex: `.env`, `.env.local`, etc.).
Chaque fichier trouvé est copié dans le dossier cible, en respectant sa structure relative d'origine.
Si `-DryRun` est activé, affiche les chemins sans effectuer la copie.

.PARAMETER targetPath
Chemin de destination où les fichiers seront copiés.

.PARAMETER sourcePath
Chemin source à parcourir. Par défaut : dossier courant.

.PARAMETER DryRun
Affiche les fichiers qui seraient copiés, sans effectuer d'action.

.EXAMPLE
Copy-EnvFiles -targetPath "D:\Backups\env" -sourcePath "$env:USERPROFILE\Dev"

.EXAMPLE
Copy-EnvFiles -targetPath "D:\Backups\env" -sourcePath "$env:USERPROFILE\Dev" -DryRun

.NOTES
- Crée les dossiers intermédiaires si nécessaire.
- Écrase les fichiers existants dans le dossier cible, sauf en mode DryRun.
#>
function Copy-EnvFiles {
    [CmdletBinding()]
    param (
        [string]$targetPath,
        [string]$sourcePath = (Get-Location).Path,
        [switch]$DryRun
    )

    if (-not (Test-Path -Path $targetPath) -and -not $DryRun) {
        New-Item -Path $targetPath -ItemType Directory | Out-Null
    }

    $dotenvFiles = Get-ChildItem -Path $sourcePath -Filter "*.env*" -Recurse -File -ErrorAction SilentlyContinue

    foreach ($file in $dotenvFiles) {
        $relativePath = $file.FullName.Substring($sourcePath.Length).TrimStart("\")
        $destination = Join-Path -Path $targetPath -ChildPath $relativePath

        if ($DryRun) {
            Write-Host "[DryRun] $($file.FullName) → $destination"
        } else {
            $destinationFolder = Split-Path -Path $destination -Parent
            if (-not (Test-Path -Path $destinationFolder)) {
                New-Item -Path $destinationFolder -ItemType Directory -Force | Out-Null
            }

            Copy-Item -Path $file.FullName -Destination $destination -Force
        }
    }
}


function Backup-GameSaves {
    <#
    .SYNOPSIS
        Sauvegarde les fichiers de sauvegarde de jeux vidéo selon une configuration YAML.

    .DESCRIPTION
        Cette fonction lit un fichier YAML contenant une liste de jeux et leurs chemins de sauvegarde.
        Pour chaque jeu, elle étend les variables d’environnement dans le chemin, construit un chemin
        de destination explicite dans le dossier de staging, puis appelle la fonction `Save` pour effectuer la copie.

    .PARAMETER configPath
        Chemin vers le fichier YAML de configuration des jeux à sauvegarder.

    .PARAMETER stagingRoot
        Dossier racine de staging où les sauvegardes seront enregistrées.

    .EXAMPLE
        $staging = Init-StagingFolder -folderName "games" -customPath "$env:USERPROFILE\TempBackupStaging"
        Backup-GameSaves -configPath "$PSScriptRoot\games-backup.yaml" -stagingRoot $staging

    .NOTES
        Le fichier YAML doit être une map simple : nom du jeu → chemin source.
        Exemple :
            Skyrim: "%USERPROFILE%\Documents\My Games\Skyrim\Saves"
            Stardew: "%APPDATA%\StardewValley\Saves"
    #>
    param (
        [string]$configPath,
        [string]$stagingRoot
    )

    if (!(Test-Path $configPath)) {
        Write-Host "❌ Fichier de config introuvable : $configPath" -ForegroundColor Red
        return
    }

    try {
        $gameSaves = Get-Content $configPath -Raw | ConvertFrom-Yaml
    } catch {
        Write-Host "❌ Erreur de lecture du fichier YAML : $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    foreach ($game in $gameSaves.GetEnumerator()) {
        $gameName = $game.Key
        $rawPath = $game.Value
        $expandedPath = [Environment]::ExpandEnvironmentVariables($rawPath)
        $targetPath = Join-Path $stagingRoot "saves\$gameName"

        Write-Host "🎮 Sauvegarde de '$gameName' depuis '$expandedPath'..."
        Save -sourcePath $expandedPath -targetPath $targetPath
    }
}

function Init-BackupFolder {
    <#
    .SYNOPSIS
    Initialise un dossier de sauvegarde, avec nom personnalisé et emplacement optionnel.

    .DESCRIPTION
    Crée un dossier nommé `$folderName` dans `$env:USERPROFILE` ou dans un chemin personnalisé (`$customPath`).
    Si le paramètre `-CleanOnly` est activé, le dossier est supprimé s’il existe, puis recréé.

    .EXAMPLE
    $backupFolder = Init-BackupFolder -folderName "MyBackup" -customPath "D:\Backups"
    Write-Host "Dossier de sauvegarde : $backupFolder"

    .EXAMPLE
    Init-BackupFolder -CleanOnly

    .NOTES
    - Le nom par défaut est "MyBackupPerso"
    - Le dossier est créé s’il n’existe pas, ou recréé si `-CleanOnly` est utilisé
    - Retourne le chemin complet du dossier
    #>
    [CmdletBinding()]
    param (
        [string]$folderName = "MyBackupPerso",
        [string]$customPath,
        [switch]$CleanOnly
    )

    $basePath = if ($customPath) { $customPath } else { $env:USERPROFILE }
    $backupFolder = Join-Path -Path $basePath -ChildPath $folderName

    if ($CleanOnly -and (Test-Path -Path $backupFolder)) {
        Remove-Item -Path $backupFolder -Recurse -Force
    }

    if (-not (Test-Path -Path $backupFolder)) {
        New-Item -Path $backupFolder -ItemType Directory | Out-Null
    }

    return $backupFolder
}

# ============================================
# =============== INVOKE =====================
# ============================================
function Invoke-BackupEnv {
    <#
    .SYNOPSIS
        Lance le script de sauvegarde environnementale (backup-perso.ps1) avec des paramètres optionnels.

    .DESCRIPTION
        Cette fonction appelle le script de profil `backup-perso.ps1`, qui effectue la sauvegarde des fichiers liés à l’environnement utilisateur (dotfiles, configurations, etc.).
        Elle permet de spécifier un dossier de destination explicite via -BackupFolder, ou de déléguer la création du dossier au script lui-même via Init-BackupFolder, en passant les paramètres -Name et -Path.

    .PARAMETER BackupFolder
        Chemin complet vers le dossier de destination. Si non fourni, le script appellera Init-BackupFolder avec les paramètres -Name et -Path.

    .PARAMETER Name
        Nom logique du profil de sauvegarde (ex: 'env'). Utilisé par Init-BackupFolder si BackupFolder n’est pas fourni.

    .PARAMETER Path
        Dossier racine dans lequel Init-BackupFolder créera le dossier de sauvegarde. Par défaut : $env:USERPROFILE\Backups.

    .EXAMPLE
        Invoke-BackupEnv -Name 'env' -Path 'D:\Backups'

    .EXAMPLE
        Invoke-BackupEnv -BackupFolder 'D:\Backups\env_2025-11-18_16-11'
    #>
    [CmdletBinding()]
    param (
        [string]$BackupFolder,
        [string]$Name,
        [string]$Path = "$env:USERPROFILE\Backups"
    )

    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\backup-perso.ps1"
    if (-not (Test-Path $scriptPath)) {
        Write-Error "Script backup-perso.ps1 introuvable à l'emplacement : $scriptPath"
        return
    }

    $invokeParams = @{
        Name         = $Name
        Path         = $Path
    }
    if ($BackupFolder) { $invokeParams.BackupFolder = $BackupFolder }
    if ($DryRun)       { $invokeParams.DryRun       = $true }

    & $scriptPath @invokeParams
}

function Invoke-BackupGames {
    <#
    .SYNOPSIS
        Lance le script de sauvegarde des jeux (backup-games.ps1) avec des paramètres optionnels.

    .DESCRIPTION
        Cette fonction appelle le script de profil `backup-games.ps1`, qui sauvegarde les fichiers de jeux selon une configuration YAML.
        Elle permet de spécifier un dossier de destination explicite via -BackupFolder, ou de déléguer la création du dossier au script lui-même via Init-BackupFolder, en passant les paramètres -Name et -Path.

    .PARAMETER BackupFolder
        Chemin complet vers le dossier de destination. Si non fourni, le script appellera Init-BackupFolder avec les paramètres -Name et -Path.

    .PARAMETER Name
        Nom logique du profil de sauvegarde (ex: 'games', 'steam'). Utilisé par Init-BackupFolder si BackupFolder n’est pas fourni.

    .PARAMETER Path
        Dossier racine dans lequel Init-BackupFolder créera le dossier de sauvegarde. Par défaut : $env:USERPROFILE\Backups.

    .EXAMPLE
        Invoke-BackupGames -Name 'games' -Path 'D:\Backups'

    .EXAMPLE
        Invoke-BackupGames -BackupFolder 'D:\Backups\games_2025-11-18_16-25'
    #>
    [CmdletBinding()]
    param (
        [string]$BackupFolder,
        [string]$Name,
        [string]$Path = "$env:USERPROFILE\Backups"
    )

    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\backup-games.ps1"
    if (-not (Test-Path $scriptPath)) {
        Write-Error "Script backup-games.ps1 introuvable à l'emplacement : $scriptPath"
        return
    }

    $invokeParams = @{}
    if ($BackupFolder) { $invokeParams.BackupFolder = $BackupFolder }
    if ($Name)         { $invokeParams.Name         = $Name }
    if ($Path)         { $invokeParams.Path         = $Path }

    & $scriptPath @invokeParams
}

# ============================================
# =============== LEGACY =====================
# ============================================
# Fonctions conservées pour compatibilité ou référence.
# Ne sont plus utilisées dans le flux principal.

# .NOTES
# - Cette fonction est conservée à titre de référence.
# - Remplacée par Init-BackupFolder dans le flux principal.

function Init-StagingFolder {
    <#
    .SYNOPSIS
    Initialise le dossier temporaire de staging pour le backup.

    .DESCRIPTION
    Supprime le dossier de staging s’il existe déjà, puis le recrée.
    Par défaut, le dossier est créé dans $env:TEMP, mais un chemin personnalisé peut être fourni.

    .PARAMETER folderName
    Nom du sous-dossier à créer. Par défaut : "MyBackupStaging".

    .PARAMETER customPath
    Chemin racine personnalisé. Si non fourni, $env:TEMP est utilisé.

    .PARAMETER CleanOnly
    Si activé, supprime le dossier sans le recréer.

    .OUTPUTS
    Retourne le chemin complet du dossier de staging (sauf si -CleanOnly est utilisé).

    .EXAMPLE
    $staging = Init-StagingFolder
    Save -sourcePath "..." -targetPath "$staging\..."

    .EXAMPLE
    $staging = Init-StagingFolder -customPath "$env:USERPROFILE\TempBackupStaging"

    .EXAMPLE
    Init-StagingFolder -CleanOnly

    .NOTES
    Le dossier est recréé à chaque appel sauf si -CleanOnly est utilisé.
    #>

    param (
        [string]$folderName = "MyBackupStaging",
        [string]$customPath,
        [switch]$CleanOnly
    )

    $basePath = if ($customPath) { $customPath } else { $env:TEMP }
    $staging = Join-Path $basePath $folderName

    if (Test-Path $staging) {
        Write-Host "🧹 Suppression du dossier temporaire existant : $staging" -ForegroundColor DarkYellow
        Remove-Item $staging -Recurse -Force
    }

    if ($CleanOnly) {
        return
    }

    Write-Host "📁 Création du dossier temporaire : $staging" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $staging | Out-Null

    return $staging
}


function Copy-FolderWithExclusions {
  # Copie un dossier source vers une destination en excluant certains fichiers ou dossiers.
  # - Source : chemin complet du dossier source à copier.
  # - Destination : chemin complet du dossier de destination.
  # - ExcludeNames : tableau de noms à exclure (fichiers ou dossiers).
  # Les exclusions sont insensibles à la casse et peuvent viser des noms, chemins ou extensions.

  param (
    [string]$Source,
    [string]$Destination,
    [string[]]$ExcludeNames
  )

  # Crée le dossier de destination s’il n’existe pas
  if (!(Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
  }

  # Récupère tous les éléments du dossier source
  $items = Get-ChildItem -Path $Source -Recurse

  foreach ($item in $items) {
    $exclude = $false

    # Vérifie si l’élément doit être exclu
    foreach ($excl in $ExcludeNames) {
      if (
        $item.Name -ieq $excl -or
        $item.FullName -like "*\$excl" -or
        $item.FullName -like "*\$excl\*" -or
        $item.FullName -like "*\$excl.*"
      ) {
        $exclude = $true
        break
      }
    }

    # Si non exclu, copie l’élément
    if (-not $exclude) {
      $target = $item.FullName.Replace($Source, $Destination)
      if ($item.PSIsContainer) {
        if (!(Test-Path $target)) {
          New-Item -ItemType Directory -Path $target -Force | Out-Null
        }
      } else {
        Copy-Item $item.FullName -Destination $target -Force
      }
    }
  }
}
