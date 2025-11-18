# Variables perso
$devPath = Join-Path -Path $env:USERPROFILE -ChildPath "Dev"

# Chemin vers le dossier OneDrive Documents
$oneDriveDocs = Join-Path "$env:USERPROFILE\OneDrive\Documents" "Scripts\Powershell"
# Importe les fonctions
Import-Module (Join-Path $oneDriveDocs "SergeBackup")


# Dossier local
$backupFolder = Init-BackupFolder
Write-Host "📂 Dossier de backup créé : $backupFolder" -ForegroundColor Cyan


# 1. Chocolatey
$tempChocoExport = Join-Path $env:TEMP "packages-choco.config"
choco export --include-version-numbers $tempChocoExport

if (Test-Path $tempChocoExport) {
  Save $tempChocoExport -targetPath "$backupFolder\packages-choco.config"
  Write-Host "✅ Chocolatey exporté" -ForegroundColor Green
  Remove-Item $tempChocoExport
} else {
  Write-Host "❌ Échec de l'export Chocolatey — fichier introuvable : $tempChocoExport" -ForegroundColor Red
}
