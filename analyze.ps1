# \analyze.ps1 -ExcludeFolders @('.git', 'models','download\storage', 'Opera Software\Opera Stable\adblocker_data', 'Opera Software\Opera Stable\Safe Browsing', 'LibreOffice\4\updates', 'Code\User\globalStorage\github.copilot-chat', 'Opera Software\Opera Stable\Default\IndexedDB', 'Opera Software\Opera Stable\Default\Extensions', 'security_state', 'Stirling-PDF', 'discord', 'AutomaticDestinations', 'Code\User\globalStorage') -ExcludeExtensions @('.log','.bak', '.pak', '.pma', '.exe', '.dll', '.sqlite', '.lock', '.sst', '.ldb') -DeepDive
# 🔎=============================
# Script: Analyze-Backup
# ===============================
param(
    [string]$BasePath = "$env:APPDATA",
    [string[]]$ExcludeFolders = @(),
    [string[]]$ExcludeExtensions = @(),
    [switch]$DeepDive
)

# --- Patterns suspects
$suspectPatterns = @(
  'cache','root_cache','log','crash','temp','report','shader','widevine',
  'component','dump','backup','cookies','Crash Reports','GrShaderCache',
  'ShaderCache','MediaFoundationWidevineCdm','Opera Add-ons Downloads',
  'IndexedDB','Service Worker','workspaceStorage'
)



# --- Fonction utilitaire pour afficher taille en MB ou KB
function Format-Size {
    param([long]$bytes)
    if ($bytes -ge 1MB) {
        return ("{0:N2} MB" -f ($bytes / 1MB))
    } else {
        return ("{0:N0} KB" -f ($bytes / 1KB))
    }
}

Write-Host "📂 Analyse de $BasePath" -ForegroundColor Cyan

# --- Récupération des fichiers
$allFiles = Get-ChildItem $BasePath -Recurse -File -ErrorAction SilentlyContinue

# --- Application des exclusions
$filteredFiles = @()
foreach ($file in $allFiles) {
    $dir = $file.DirectoryName.ToLower()
    $ext = $file.Extension.ToLower()
    $name = $file.FullName.ToLower()

    # Exclusion par dossier
    $excludeDirMatch = $false
    foreach ($folder in $ExcludeFolders) {
        if ($dir -like "*$folder*") { $excludeDirMatch = $true; break }
    }

    # Exclusion par extension
    $excludeExtMatch = $ExcludeExtensions -contains $ext

    # Exclusion par pattern suspect
    $excludePatternMatch = $false
    foreach ($pattern in $suspectPatterns) {
        if ($name -like "*$pattern*") { $excludePatternMatch = $true; break }
    }

    if (-not $excludeDirMatch -and -not $excludeExtMatch -and -not $excludePatternMatch) {
        $filteredFiles += $file
    }
}

# --- Calcul des tailles
$totalSize = ($allFiles | Measure-Object Length -Sum).Sum
$filteredSize = ($filteredFiles | Measure-Object Length -Sum).Sum
$gain = $totalSize - $filteredSize
$percent = if ($totalSize -gt 0) { [math]::Round(($gain / $totalSize) * 100, 1) } else { 0 }

# --- Résumé global
Write-Host "`n📊 Résumé global" -ForegroundColor Cyan
Write-Host ("   💾 Taille totale {0} : {1}" -f $BasePath, (Format-Size $totalSize))
Write-Host ("   🧹 Taille filtrée (sans suspects) : {0}" -f (Format-Size $filteredSize))
Write-Host ("   🎯 Gain potentiel : {0} ({1}%)" -f (Format-Size $gain), $percent)

# --- Top 10 dossiers les plus lourds (après filtrage)
Write-Host "`n📂 Top 10 dossiers (après filtrage)" -ForegroundColor Cyan
$topDirs = $filteredFiles | Group-Object DirectoryName | ForEach-Object {
    $totalBytes = ($_.Group | Measure-Object Length -Sum).Sum
    $maxFile = $_.Group | Sort-Object Length -Descending | Select-Object -First 1
    [PSCustomObject]@{
        Directory        = $_.Name
        TotalSizeBytes   = $totalBytes
        BiggestFile      = $maxFile.FullName
        BiggestFileSize  = $maxFile.Length
    }
} | Sort-Object TotalSizeBytes -Descending | Select-Object -First 10

$topDirs | ForEach-Object {
    Write-Host ("   📁 {0} — {1} (plus gros: {2}, {3})" -f `
        $_.Directory, (Format-Size $_.TotalSizeBytes), $_.BiggestFile, (Format-Size $_.BiggestFileSize))
}

# --- Top 10 fichiers les plus lourds (après filtrage)
Write-Host "`n📄 Top 10 fichiers (après filtrage)" -ForegroundColor Cyan
$topFiles = $filteredFiles | Sort-Object Length -Descending | Select-Object -First 10

$topFiles | ForEach-Object {
    Write-Host ("   📄 {0} — {1}" -f $_.FullName, (Format-Size $_.Length))
}

# --- DeepDive : liste des suspects
if ($DeepDive) {
    Write-Host "`n🔎 Fichiers suspects détectés" -ForegroundColor Yellow
    $suspects = $allFiles | Where-Object {
        $name = $_.FullName.ToLower()
        $suspectPatterns | ForEach-Object { $name -like "*$_*" } | Where-Object { $_ }
    }
    $suspects | Sort-Object Length -Descending | Select-Object FullName,@{Name="Size";Expression={Format-Size $_.Length}} -First 20 |
        ForEach-Object { Write-Host ("   ⚠️ {0} — {1}" -f $_.FullName, $_.Size) }
}
