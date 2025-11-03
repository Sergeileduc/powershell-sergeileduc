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
Sauvegarde un contenu texte dans deux fichiers simultanément.

.DESCRIPTION
Écrit une chaîne de texte dans deux emplacements de sauvegarde :
- Un dossier horodaté (`$global:backupTimestamped`)
- Un dossier "latest" (`$global:backupLatest`)

Ce mécanisme permet de conserver une version historique et une version toujours à jour.

.PARAMETER content
Le contenu texte à sauvegarder (chaîne de caractères).

.PARAMETER filename
Le nom du fichier à créer dans les deux dossiers de sauvegarde.

.EXAMPLE
$pipList = pip freeze | Out-String
Save-Text $pipList "requirements.txt"

.NOTES
Nécessite que les variables globales $global:backupTimestamped et $global:backupLatest soient initialisées.
#>

  param (
    [string]$content,
    [string]$filename
  )

  $file1 = Join-Path $global:backupTimestamped $filename
  $file2 = Join-Path $global:backupLatest $filename

  $content | Tee-Object -FilePath $file1 -Encoding UTF8 | Out-File -FilePath $file2 -Encoding UTF8

  Write-Host "✅ Contenu sauvegardé : $filename" -ForegroundColor Green
}

function Save-File {
<#
.SYNOPSIS
Copie un fichier ou dossier vers les deux emplacements de sauvegarde.

.DESCRIPTION
Copie un fichier ou un dossier existant dans :
- Un dossier horodaté (`$global:backupTimestamped`)
- Un dossier "latest" (`$global:backupLatest`)

.PARAMETER sourcePath
Chemin du fichier ou dossier à copier.

.PARAMETER relativeTarget
Nom du fichier ou dossier cible (relatif).

.EXAMPLE
Save-File "C:\data\notes.txt" "notes.txt"

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

  Write-Host "✅ Fichier sauvegardé : $relativeTarget" -ForegroundColor Green
}


function Copy-FolderToBothWithExclusions {
  <#
    .SYNOPSIS
    Copie un dossier vers les deux dossiers de backup, en excluant certains fichiers ou sous-dossiers.

    .PARAMETER source
    Chemin du dossier source à copier.

    .PARAMETER targetName
    Nom du dossier cible dans les backups.

    .PARAMETER excludeNames
    Liste des noms à exclure (fichiers ou dossiers).

    .EXAMPLE
    Copy-FolderToBothWithExclusions "$env:USERPROFILE\.ssh" "ssh" @("known_hosts.old", "config.bak")
  #>

  param (
    [string]$source,
    [string]$targetName,
    [string[]]$excludeNames
  )

  foreach ($dest in @($global:backupTimestamped, $global:backupLatest)) {
    $target = Join-Path $dest $targetName
    Copy-FolderWithExclusions -Source $source -Destination $target -ExcludeNames $excludeNames
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
