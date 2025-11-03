<#
ytdl-tools.ps1 — Fonctions PowerShell pour gérer les téléchargements YouTube avec yt-dlp
Auteur : Serge
#>

function ytdl-update {
<#
.SYNOPSIS
Télécharge les vidéos récentes d’une chaîne YouTube ou playlist.

.DESCRIPTION
Utilise yt-dlp pour récupérer les vidéos les plus récentes, en évitant les doublons grâce à une archive.
Par défaut : chaîne 1minShorts, 2 vidéos, dossier $HOME\Videos\ytdl.

.PARAMETER url
URL de la chaîne ou playlist YouTube (par défaut : https://www.youtube.com/@1minshorts/shorts)

.PARAMETER count
Nombre de vidéos à télécharger (par défaut : 2)

.PARAMETER reset
Si présent, supprime l’archive et ne télécharge rien

.PARAMETER dryRun
Affiche les vidéos détectées sans les télécharger

.PARAMETER quiet
Réduit la verbosité de yt-dlp (pas de progression, pas de warnings)

.EXAMPLE
ytdl-update
ytdl-update -url "https://www.youtube.com/@arteconcert" -count 5
ytdl-update -reset
ytdl-update -dryRun
ytdl-update -quiet
#>

    param(
        [string]$url = "https://www.youtube.com/@1minshorts/shorts",
        [int]$count = 2,
        [switch]$reset,
        [switch]$dryRun,
        [switch]$quiet
    )

    $configDir = "$HOME\.config\ytdl"
    $archivePath = Join-Path $configDir "archive.txt"
    $videoDir = "$HOME\Videos\ytdl"

    foreach ($dir in @($configDir, $videoDir)) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    if ($reset) {
        if (Test-Path $archivePath) {
            Remove-Item $archivePath -Force
            Write-Host "🧹 Archive supprimée : $archivePath"
        } else {
            Write-Host "ℹ️ Aucun fichier archive à supprimer."
        }
        if (-not $dryRun) {
            return
        }
    }

    $verbosity = if ($quiet) {
        "--quiet --no-warnings --no-progress"
    } else {
        ""
    }

    if ($dryRun) {
        Write-Host "`n🔍 Dry-run activé : détection des vidéos sans téléchargement…`n"

        $cmd = @(
            "yt-dlp",
            $verbosity,
            "--download-archive `"$archivePath`"",
            "--max-downloads $count",
            "--skip-download",
            "--print `"%(title)s | Duration: %(duration_string)s | Date: %(upload_date)s | URL: https://youtu.be/%(id)s`"",
            "-i",
            "`"$url`""
        ) -join " "

        Invoke-Expression $cmd
        return
    }

    $beforeCount = (Get-ChildItem -Path $videoDir -File).Count

    $cmd = @(
        "yt-dlp",
        $verbosity,
        "--download-archive `"$archivePath`"",
        "--max-downloads $count",
        "-f bestvideo+bestaudio",
        "--merge-output-format mp4",
        "-P `"$videoDir`"",
        "-i",
        "`"$url`""
    ) -join " "

    Write-Host "`n📥 Téléchargement des vidéos détectées…`n"
    Invoke-Expression $cmd

    $afterCount = (Get-ChildItem -Path $videoDir -File).Count
    $downloaded = $afterCount - $beforeCount
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"

    Write-Host "`n✅ $downloaded vidéo(s) téléchargée(s) le $timestamp"
    Write-Host "📂 Dossier : $videoDir"
}

function ytdl-info {
<#
.SYNOPSIS
Affiche un résumé du dossier de vidéos téléchargées.

.DESCRIPTION
Montre le nombre total de vidéos, la taille cumulée, et la date du dernier fichier.

.EXAMPLE
ytdl-info
#>

    $videoDir = "$HOME\Videos\ytdl"
    $files = Get-ChildItem -Path $videoDir -File

    if ($files.Count -eq 0) {
        Write-Host "📂 Aucun fichier trouvé dans $videoDir"
        return
    }

    $totalSizeMB = [math]::Round(($files | Measure-Object Length -Sum).Sum / 1MB, 1)
    $lastDate = ($files | Sort-Object LastWriteTime -Descending)[0].LastWriteTime.ToString("yyyy-MM-dd HH:mm")

    Write-Host "📦 Total : $($files.Count) vidéo(s)"
    Write-Host "💾 Taille : $totalSizeMB MB"
    Write-Host "🕒 Dernier fichier : $lastDate"
}

function ytdl-list {
<#
.SYNOPSIS
Liste les vidéos téléchargées avec leur taille et date.

.DESCRIPTION
Affiche chaque fichier du dossier avec son nom, sa taille en MB, et sa date de modification.

.EXAMPLE
ytdl-list
#>

    $videoDir = "$HOME\Videos\ytdl"
    $files = Get-ChildItem -Path $videoDir -File | Sort-Object LastWriteTime -Descending

    if ($files.Count -eq 0) {
        Write-Host "📂 Aucun fichier trouvé dans $videoDir"
        return
    }

    foreach ($file in $files) {
        $sizeMB = [math]::Round($file.Length / 1MB, 1)
        $date = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
        Write-Host "📄 $($file.Name) — $sizeMB MB — $date"
    }

    Write-Host "`n📦 Total : $($files.Count) fichier(s)"
}

function ytdl-clean {
<#
.SYNOPSIS
Supprime les vidéos trop vieilles ou trop lourdes.

.DESCRIPTION
Efface les fichiers du dossier qui dépassent une certaine taille ou une certaine ancienneté.

.PARAMETER maxAgeDays
Âge maximum des fichiers en jours (par défaut : 30)

.PARAMETER maxSizeMB
Taille maximale des fichiers en MB (par défaut : 100)

.EXAMPLE
ytdl-clean
ytdl-clean -maxAgeDays 15 -maxSizeMB 50
#>

    param(
        [int]$maxAgeDays = 30,
        [int]$maxSizeMB = 100
    )

    $videoDir = "$HOME\Videos\ytdl"
    $limitDate = (Get-Date).AddDays(-$maxAgeDays)

    $files = Get-ChildItem -Path $videoDir -File | Where-Object {
        $_.LastWriteTime -lt $limitDate -or ($_.Length / 1MB) -gt $maxSizeMB
    }

    if ($files.Count -eq 0) {
        Write-Host "🧹 Aucun fichier à supprimer (rien de trop vieux ou trop lourd)."
        return
    }

    foreach ($file in $files) {
        Remove-Item $file.FullName -Force
        Write-Host "❌ Supprimé : $($file.Name)"
    }

    Write-Host "`n✅ Nettoyage terminé : $($files.Count) fichier(s) supprimé(s)."
}

function ytdl-purge {
<#
.SYNOPSIS
Supprime tous les fichiers du dossier de vidéos téléchargées.

.DESCRIPTION
Efface brutalement tous les fichiers du dossier $HOME\Videos\ytdl, sans confirmation.
Affiche le chemin ciblé et les fichiers supprimés. Utiliser avec précaution.

.EXAMPLE
ytdl-purge
#>

    $videoDir = "$HOME\Videos\ytdl"

    Write-Host "📁 Dossier ciblé : $videoDir"

    if (-not (Test-Path $videoDir)) {
        Write-Host "📂 Dossier inexistant."
        return
    }

    $files = Get-ChildItem -Path $videoDir -File

    if ($files.Count -eq 0) {
        Write-Host "🧼 Dossier déjà vide."
        return
    }

    Write-Host "`n📋 Fichiers à supprimer :"
    $files | ForEach-Object { Write-Host " - $($_.FullName)" }

    $deleted = 0

    foreach ($file in $files) {
        try {
            Remove-Item $file.FullName -Force -ErrorAction Stop
            Write-Host "🔥 Supprimé : $($file.Name)"
            $deleted++
        } catch {
            Write-Host "⚠️ Échec suppression : $($file.Name) — $($_.Exception.Message)"
        }
    }

    Write-Host "`n💣 Purge complète : $deleted fichier(s) supprimé(s)."
}
