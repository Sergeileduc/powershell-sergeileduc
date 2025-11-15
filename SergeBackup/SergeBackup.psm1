Import-Module powershell-yaml


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

function Save-Text {
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
        Write-Error "💥 Échec de l’écriture dans '$targetPath' : $_"
    }
}

function Save-Item {
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

    param (
        [Parameter(Mandatory = $true)]
        [string]$sourcePath,

        [Parameter(Mandatory = $true)]
        [string]$targetPath
    )

    if (-not (Test-Path $sourcePath)) {
        Write-Warning "❌ Source introuvable : $sourcePath"
        return
    }

    try {
        Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
    } catch {
        Write-Error "💥 Échec de la copie de '$sourcePath' vers '$targetPath' : $_"
    }

  Write-Host "✅ Sauvegarde : $relativeTarget" -ForegroundColor Green
}


function Save-ItemWithExclusions {
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

    param (
        [Parameter(Mandatory = $true)]
        [string]$sourcePath,

        [Parameter(Mandatory = $true)]
        [string]$targetPath,

        [string[]]$exclusions
    )

    if (-not (Test-Path $sourcePath)) {
        Write-Warning "❌ Source introuvable : $sourcePath"
        return
    }

    $items = Get-ChildItem -Path $sourcePath -Recurse

    foreach ($item in $items) {
        if ($exclusions -contains $item.Name) {
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


function Save {
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

    param (
        [string]$textContent,
        [string]$sourcePath,
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

    if (-not $sourcePath) {
        Write-Warning "⚠️ Aucun contenu à sauvegarder : ni -textContent ni -sourcePath n’ont été fournis."
        return
    }

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


function Copy-EnvFiles {
    <#
    .SYNOPSIS
    Sauvegarde les fichiers .env renommés par projet dans un dossier cible.

    .DESCRIPTION
    Cette fonction parcourt les fichiers .env présents dans le dossier courant (ou un dossier spécifique),
    et les copie vers un dossier de sauvegarde en les renommant selon leur projet.

    .PARAMETER targetFolder
    Dossier de destination dans lequel les fichiers .env seront copiés.

    .EXAMPLE
    Copy-EnvFiles -targetFolder "backup\env"
    #>

    param (
        [Parameter(Mandatory = $true)]
        [string]$targetFolder
    )

    $envFiles = Get-ChildItem -Path . -Filter "*.env.*" -File

    foreach ($file in $envFiles) {
        $projectName = $file.Name -replace "^\.env\.", ""
        $targetPath = Join-Path $targetFolder "$projectName.env"

        Save -sourcePath $file.FullName -targetPath $targetPath
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
