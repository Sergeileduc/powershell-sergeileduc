# Chemin vers le dossier OneDrive Documents
$oneDriveDocs = Join-Path "$env:USERPROFILE\OneDrive\Documents" "Scripts\Powershell"
# Importe les fonctions
Import-Module (Join-Path $oneDriveDocs "SergeBackup")

# Dossier temporaire local
$staging = Init-StagingFolder -customPath "$env:USERPROFILE"


# 1. Chocolatey
$tempChocoExport = Join-Path $env:TEMP "packages-choco.config"
choco export --include-version-numbers $tempChocoExport

if (Test-Path $tempChocoExport) {
  Save $tempChocoExport -targetPath "$staging\packages-choco.config"
  Write-Host "✅ Chocolatey exporté et copié dans les deux backups" -ForegroundColor Green
  Remove-Item $tempChocoExport
} else {
  Write-Host "❌ Échec de l’export Chocolatey — fichier introuvable : $tempChocoExport" -ForegroundColor Red
}
