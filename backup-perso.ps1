<#
  .SYNOPSIS
  Script de sauvegarde de l'environnement de développement
  Destination : OneDrive\Documents\AAA-important\geek\backup\
  Sauvegarde :
    - Chocolatey
    - pip
    - Variables d'environnement
    - VSCode (extensions + settings)
    - Git (.gitconfig + clés SSH)
    - Fly.io (config + auth)
    - Dossier .config (avec exclusions)
    - Fichiers .env (renommés par projet)
    - Version horodatée + version "latest"
#>

param (
    [string]$BackupFolder,
    [string]$Name = 'env',
    [string]$Path = "$env:USERPROFILE\Backups"
)

# Variables perso
$devPath = Join-Path -Path $env:USERPROFILE -ChildPath "Dev"

# Chemin vers le dossier OneDrive Documents
$oneDriveDocs = Join-Path "$env:USERPROFILE\OneDrive\Documents" "Scripts\Powershell"
# Importe les fonctions
Import-Module (Join-Path $oneDriveDocs "SergeBackup")


# Dossier local
if (-not $BackupFolder) {
    $BackupFolder = Init-BackupFolder -Name $Name -Path $Path
}
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

# 2. pip
$pipList = pip freeze | Out-String
Save -textContent $pipList -targetPath "$backupFolder\pip\requirements.txt"
Write-Host "✅ pip freeze enregistré" -ForegroundColor Green

# 3. Variables d’environnement
$envVars = Get-ChildItem Env: | ForEach-Object { "$($_.Name),$($_.Value)" }
$envVarsText = $envVars -join "`n"
Save -textContent $envVarsText -targetPath "$backupFolder\env-vars.csv"
Write-Host "✅ Variables d’environnement sauvegardées" -ForegroundColor Green

# 4. Extensions VSCode
$extensions = code --list-extensions | Out-String
Save -textContent $extensions -targetPath "$backupFolder\vscode-extensions.txt"
Write-Host "✅ Extensions VSCode sauvegardées" -ForegroundColor Green

# 5. Réglages VSCode
Save -sourcePath "$env:APPDATA\Code\User\settings.json" -targetPath "$backupFolder\Code\User\settings.json"
Write-Host "✅ Réglages VSCode copiés" -ForegroundColor Green

# 6. Profil Git
Save -sourcePath "$env:USERPROFILE\.gitconfig" -targetPath "$backupFolder\.gitconfig"
Write-Host "✅ Fichier .gitconfig sauvegardé" -ForegroundColor Green

# 7. Clés SSH
Save -sourcePath "$env:USERPROFILE\.ssh" -targetPath "$backupFolder\ssh" -exclusions @("known_hosts.old", "config.bak")
Write-Host "✅ Clés SSH sauvegardées (fichiers inutiles exclus)" -ForegroundColor Green

# 8. Fly.io
Save -sourcePath "$env:USERPROFILE\.fly" -targetPath "$backupFolder\fly" -exclusions @(
    "bin", "flyctl.exe", "flyctl", "wintun.dll", "fly.exe", "fly.exe.old", "fly-agent.sock"
)
Write-Host "✅ Config Fly.io sauvegardée (sans le dossier bin ni les exécutables)" -ForegroundColor Green

# 9. Dossier .config (avec exclusions)
Save -sourcePath "$env:USERPROFILE\.config" -targetPath "$backupFolder\config" -exclusions @("__pycache__", "cache", "temp")
Write-Host "✅ Dossier .config sauvegardé (exclusions appliquées)" -ForegroundColor Green

# 10. Fichiers .env (renommés par projet)
Copy-EnvFiles -targetPath "$backupFolder\env" -sourcePath $devPath
Write-Host "✅ Fichiers .env sauvegardés" -ForegroundColor Green


# 11. 📊 Résumé de la sauvegarde
$filesCount = (Get-ChildItem $backupFolder -Recurse -File -Force).Count
Write-Host "📊 $filesCount fichiers sauvegardés dans $backupFolder" -ForegroundColor Cyan

# # 12. 🧹 Suppression du dossier de staging
# Write-Host "🧹 Suppression du dossier de staging..."
# Remove-Item -Path $backupFolder -Recurse -Force

# 13. 🎉 Fin du script
if ($filesCount -eq 0) {
    Write-Host "⚠️ Aucun fichier sauvegardé — vérifie tes exclusions ou ton dossier source." -ForegroundColor Red
} else {
    Write-Host "🎉 Sauvegarde complète terminée avec succès !" -ForegroundColor Green
}
