param (
    [string]$AppFolder = "$env:APPDATA",
    [int]$Depth = 2,
    [switch]$DeepDive,
    [string[]]$ExcludeFolders = @()
)

Write-Host "`n📦 Analyse de $AppFolder`n" -ForegroundColor Cyan

$suspectPatterns = @(
    'cache','log','crash','temp','report','shader','widevine',
    'component','dump','backup','cookies','Crash Reports','GrShaderCache',
    'ShaderCache','MediaFoundationWidevineCdm','Opera Add-ons Downloads'
)

$keyExtensions = '*.json','*.ini','*.conf','*.xml','*.settings','*.sqlite','*.db'

$totalRaw = 0
$totalFiltered = 0

$folders = Get-ChildItem -Path $AppFolder -Directory

foreach ($folder in $folders) {
    $path = $folder.FullName
    $name = $folder.Name

    $allFiles = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue

    $rawSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
    $rawMB = [math]::Round($rawSize / 1MB, 2)
    $totalRaw += $rawSize

    $filteredFiles = $allFiles | Where-Object {
        $dir = $_.DirectoryName.ToLower()
        -not ($suspectPatterns + $ExcludeFolders | Where-Object { $dir -like "*$_*" })
    }

    $filteredSize = ($filteredFiles | Measure-Object -Property Length -Sum).Sum
    $filteredMB = [math]::Round($filteredSize / 1MB, 2)
    $totalFiltered += $filteredSize

    $keyFiles = $filteredFiles | Where-Object {
        $keyExtensions | Where-Object { $_ -and $_ -ne '' -and $_ -like "*$($_)" }
    }

    $suspectDirs = Get-ChildItem -Path $path -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object {
        $folderName = $_.Name.ToLower()
        $suspectPatterns | Where-Object { $folderName -like "*$_*" }
    }

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

    if ($DeepDive) {
        Write-Host "   🔍 Analyse détaillée..." -ForegroundColor Magenta

        # Top dossiers restants
        $filteredFiles | Group-Object { $_.DirectoryName } | ForEach-Object {
            [PSCustomObject]@{
                Path = $_.Name
                Count = $_.Count
                SizeMB = [math]::Round(($_.Group | Measure-Object Length -Sum).Sum / 1MB, 2)
            }
        } | Sort-Object SizeMB -Descending | Select-Object -First 5 | ForEach-Object {
            Write-Host "      📂 $($_.Path) — $($_.SizeMB) MB"
        }

        # Top fichiers
        $filteredFiles | Sort-Object Length -Descending | Select-Object -First 5 | ForEach-Object {
            $size = [math]::Round($_.Length / 1MB, 2)
            Write-Host "      📄 $($_.FullName) — $size MB"
        }

        # Extensions les plus lourdes
        $filteredFiles | Group-Object Extension | ForEach-Object {
            [PSCustomObject]@{
                Extension = $_.Name
                Count = $_.Count
                TotalMB = [math]::Round(($_.Group | Measure-Object Length -Sum).Sum / 1MB, 2)
            }
        } | Sort-Object TotalMB -Descending | Select-Object -First 5 | ForEach-Object {
            Write-Host "      📦 $($_.Extension) — $($_.TotalMB) MB"
        }
    }

    Write-Host ""
}

$rawTotalMB = [math]::Round($totalRaw / 1MB, 2)
$filteredTotalMB = [math]::Round($totalFiltered / 1MB, 2)
$gainMB = [math]::Round($rawTotalMB - $filteredTotalMB, 2)
$gainPercent = if ($rawTotalMB -ne 0) { [math]::Round(($gainMB / $rawTotalMB) * 100, 1) } else { 0 }

Write-Host "`n📊 Résumé global" -ForegroundColor Cyan
Write-Host "   💾 Taille totale AppData\Roaming : $rawTotalMB MB"
Write-Host "   🧹 Taille filtrée (sans suspects) : $filteredTotalMB MB"
Write-Host "   🎯 Gain potentiel : $gainMB MB ($gainPercent%)"
