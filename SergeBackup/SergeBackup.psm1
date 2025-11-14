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
  param (
    [string]$Text,
    [string]$RelativeTarget
  )

  $target1 = Join-Path $global:backupTimestamped $RelativeTarget
  $target2 = Join-Path $global:backupLatest $RelativeTarget

  foreach ($target in @($target1, $target2)) {
    $parentDir = Split-Path $target -Parent
    if (!(Test-Path $parentDir)) {
      New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $Text | Out-File -FilePath $target -Encoding UTF8
  }

  Write-Host "✅ Contenu sauvegardé : $RelativeTarget" -ForegroundColor Green
}

function Save-Item {
<#
.SYNOPSIS
Sauvegarde un fichier ou dossier vers deux emplacements : horodaté et latest.

.DESCRIPTION
Copie un fichier ou un dossier existant dans :
- Un dossier horodaté (`$global:backupTimestamped`)
- Un dossier "latest" (`$global:backupLatest`)

.PARAMETER sourcePath
Chemin du fichier ou dossier à copier.

.PARAMETER relativeTarget
Nom du fichier ou dossier cible (relatif).

.EXAMPLE
Save-Item "C:\data\notes.txt" "notes.txt"

.NOTES
Nécessite que les variables globales $global:backupTimestamped et $global:backupLatest soient initialisées.
#>

  param (
    [string]$sourcePath,
    [string]$relativeTarget
  )

  if (!(Test-Path $sourcePath)) {
    Write-Host "⚠️ Source introuvable : $sourcePath" -ForegroundColor Yellow
    return
  }

  $target1 = Join-Path $global:backupTimestamped $relativeTarget
  $target2 = Join-Path $global:backupLatest $relativeTarget

  foreach ($target in @($target1, $target2)) {
    $parentDir = Split-Path $target -Parent
    if (!(Test-Path $parentDir)) {
      New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    if (Test-Path $sourcePath -PathType Container) {
      Copy-Item $sourcePath -Destination $target -Recurse -Force
    } else {
      Copy-Item $sourcePath -Destination $target -Force
    }
  }

  Write-Host "✅ Sauvegarde : $relativeTarget" -ForegroundColor Green
}


function Save-ItemWithExclusions {
<#
.SYNOPSIS
Sauvegarde un dossier vers deux emplacements en excluant certains fichiers ou sous-dossiers.

.DESCRIPTION
Copie un dossier existant dans :
- Un dossier horodaté (`$global:backupTimestamped`)
- Un dossier "latest" (`$global:backupLatest`)
En excluant les fichiers ou dossiers spécifiés.

.PARAMETER sourcePath
Chemin du dossier source.

.PARAMETER relativeTarget
Chemin relatif de destination.

.PARAMETER excludeNames
Liste des noms ou extensions à exclure.

.EXAMPLE
Save-ItemWithExclusions "$env:USERPROFILE\.ssh" "ssh" @("known_hosts.old", "config.bak")
#>

  param (
    [string]$sourcePath,
    [string]$relativeTarget,
    [string[]]$excludeNames = @()
  )

  if (!(Test-Path $sourcePath -PathType Container)) {
    Write-Host "⚠️ Dossier source introuvable : $sourcePath" -ForegroundColor Yellow
    return
  }

  $target1 = Join-Path $global:backupTimestamped $relativeTarget
  $target2 = Join-Path $global:backupLatest $relativeTarget

  foreach ($target in @($target1, $target2)) {
    $parentDir = Split-Path $target -Parent
    if (!(Test-Path $parentDir)) {
      New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    Copy-FolderWithExclusions -Source $sourcePath -Destination $target -ExcludeNames $excludeNames
  }

  Write-Host "✅ Sauvegarde avec exclusions : $relativeTarget" -ForegroundColor Green
}

function Save {
<#
.SYNOPSIS
Sauvegarde un fichier, un dossier ou un texte vers les emplacements de backup.

.DESCRIPTION
Fonction générique qui délègue à :
- Save-Item (fichier ou dossier)
- Save-ItemWithExclusions (dossier avec exclusions)
- Save-Text (contenu texte)

.PARAMETER sourcePath
Chemin du fichier ou dossier à sauvegarder.

.PARAMETER relativeTarget
Chemin relatif dans les dossiers de backup.

.PARAMETER excludeNames
Liste des noms ou extensions à exclure (pour les dossiers).

.PARAMETER textContent
Texte à sauvegarder (si fourni, sourcePath est ignoré).

.EXAMPLE
Save -sourcePath "$env:USERPROFILE\.ssh" -relativeTarget "ssh" -excludeNames @("known_hosts.old")

.EXAMPLE
Save -textContent "Hello world" -relativeTarget "notes\hello.txt"
#>

  param (
    [string]$sourcePath,
    [string]$relativeTarget,
    [string[]]$excludeNames = @(),
    [string]$textContent = $null
  )

  if ($textContent) {
    Save-Text -Text $textContent -RelativeTarget $relativeTarget
    return
  }

  if ($excludeNames.Count -gt 0) {
    Save-ItemWithExclusions -sourcePath $sourcePath -relativeTarget $relativeTarget -excludeNames $excludeNames
  } else {
    Save-Item -sourcePath $sourcePath -relativeTarget $relativeTarget
  }
}

function Copy-EnvFilesToBoth {
  <#
    .SYNOPSIS
    Sauvegarde tous les fichiers .env trouvés dans le profil utilisateur,
    en les renommant selon le dossier parent, vers les deux dossiers de backup.

    .EXAMPLE
    Copy-EnvFilesToBoth
  #>

  $envFiles = Get-ChildItem -Path "$env:USERPROFILE" -Filter ".env" -Recurse -ErrorAction SilentlyContinue

  foreach ($dest in @($global:backupTimestamped, $global:backupLatest)) {
    $envBackupDir = Join-Path $dest "env-files"
    if (!(Test-Path $envBackupDir)) {
      New-Item -ItemType Directory -Path $envBackupDir -Force | Out-Null
    }

    foreach ($file in $envFiles) {
      $projectName = Split-Path $file.DirectoryName -Leaf
      $targetName = "$projectName.env"
      $targetPath = Join-Path $envBackupDir $targetName
      Copy-Item $file.FullName -Destination $targetPath -Force
      Write-Host "✅ .env sauvegardé : $targetName" -ForegroundColor Green
    }
  }
}


function Backup-GameSaves {
    param (
        [string]$configPath
    )

    if (!(Test-Path $configPath)) {
        Write-Host "❌ Fichier de config introuvable : $configPath" -ForegroundColor Red
        return
    }

    try {
        $gameSaves = Get-Content $configPath -Raw | ConvertFrom-Yaml
    } catch {
        Write-Host "❌ Erreur de lecture du fichier JSON : $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    foreach ($game in $gameSaves.GetEnumerator()) {
        $gameName = $game.Key
        $rawPath = $game.Value
        $expandedPath = [Environment]::ExpandEnvironmentVariables($rawPath)

        Write-Host "🎮 Sauvegarde de '$gameName' depuis '$expandedPath'..."
        Save-Item $expandedPath "saves\$gameName"
    }
}
