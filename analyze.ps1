param (
    [string]$AppFolder = "$env:APPDATA",
    [int]$Depth = 2
)

Write-Host "`n📦 Analyse de $AppFolder`n" -ForegroundColor Cyan

# Patterns de dossiers suspects
$suspectPatterns = @(
    'cache','log','crash','temp','report','shader','widevine',
    'component','dump','backup','cookies','Crash Reports','GrShaderCache',
    'ShaderCache','MediaFoundationWidevineCdm','Opera Add-ons Downloads'
)

# Extensions de fichiers clés
$keyExtensions = '*.json','*.ini','*.conf','*.xml','*.settings','*.sqlite','*.db'

# Stats globales
$totalRaw = 0
$totalFiltered = 0

# Liste des apps (dossiers)
$folders = Get-ChildItem -Path $AppFolder -Directory

foreach ($folder in $folders) {
    $path = $folder.FullName
    $name = $folder.Name

    # Tous les fichiers
    $allFiles = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue

    # Taille brute
    $rawSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
    $rawMB = [math]::Round($rawSize / 1MB, 2)
    $totalRaw += $rawSize

    # Fichiers filtrés (exclusion des dossiers suspects)
    $filteredFiles = $allFiles | Where-Object {
        $dir = $_.DirectoryName.ToLower()
        -not ($suspectPatterns | Where-Object { $dir -like "*$_*" })
    }

    $filteredSize = ($filteredFiles | Measure-Object -Property Length -Sum).Sum
    $filteredMB = [math]::Round($filteredSize / 1MB, 2)
    $totalFiltered += $filteredSize

    # Fichiers clés
    $keyFiles = $filteredFiles | Where-Object {
        $keyExtensions | Where-Object { $_ -and $_ -ne '' -and $_ -like "*$($_)" }
    }

    # Dossiers suspects détectés
    $suspectDirs = Get-ChildItem -Path $path -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object {
        $folderName = $_.Name.ToLower()
        $suspectPatterns | Where-Object { $folderName -like "*$_*" }
    }

    # Affichage
    Write-Host "📁 $name"
    Write-Host "   🔸 Taille brute     : $rawMB MB"
    Write-Host "   🔹 Taille filtrée   : $filteredMB MB"
    Write-Host "   ⚠️  Dossiers suspects : $($suspectDirs.Count)"
    foreach ($file in $keyFiles) {
        $relative = $file.FullName.Substring($AppFolder.Length + 1)
        Write-Host "   🔹 Fichier clé : $relative"
    }
    foreach ($suspect in $suspectDirs) {
        $relative = $suspect.FullName.Substring($AppFolder.Length + 1)
        Write-Host "   ⚠️  Suspect : $relative" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# Résumé final
$rawTotalMB = [math]::Round($totalRaw / 1MB, 2)
$filteredTotalMB = [math]::Round($totalFiltered / 1MB, 2)
$gainMB = [math]::Round($rawTotalMB - $filteredTotalMB, 2)
$gainPercent = if ($rawTotalMB -ne 0) { [math]::Round(($gainMB / $rawTotalMB) * 100, 1) } else { 0 }

Write-Host "`n📊 Résumé global" -ForegroundColor Cyan
Write-Host "   💾 Taille totale AppData\Roaming : $rawTotalMB MB"
Write-Host "   🧹 Taille filtrée (sans suspects) : $filteredTotalMB MB"
Write-Host "   🎯 Gain potentiel : $gainMB MB ($gainPercent%)"
