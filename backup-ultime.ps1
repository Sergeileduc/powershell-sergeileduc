<#
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

# Chemin vers le dossier OneDrive Documents
$oneDriveDocs = Join-Path "$env:USERPROFILE\OneDrive\Documents" "Scripts\Powershell"
# Importe les fonctions
. (Join-Path $oneDriveDocs "backup-functions.ps1")

# Timestamp du jour
$timestamp = Get-Date -Format "yyyy-MM-dd"
# Autres variables
# Racine du dossier de backup
$root = Join-Path "$env:USERPROFILE\OneDrive\Documents" "AAA-important\geek\backup"
# Dossiers de destination
$global:backupTimestamped = Join-Path $root "backup-$timestamp"
$global:backupLatest = Join-Path $root "backup-latest"

# Crée les deux dossiers
foreach ($path in @($global:backupTimestamped, $global:backupLatest)) {
  if (!(Test-Path $path)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
  }
}

# 1. Chocolatey
$tempChocoExport = Join-Path $env:TEMP "packages-choco.config"
choco export --include-version-numbers $tempChocoExport

if (Test-Path $tempChocoExport) {
  Save-Item $tempChocoExport "packages-choco.config"
  Write-Host "✅ Chocolatey exporté et copié dans les deux backups" -ForegroundColor Green
  Remove-Item $tempChocoExport
} else {
  Write-Host "❌ Échec de l’export Chocolatey — fichier introuvable : $tempChocoExport" -ForegroundColor Red
}

# 2. pip
$pipList = pip freeze | Out-String
Save-Text $pipList "requirements.txt"
Write-Host "✅ pip freeze enregistré" -ForegroundColor Green

# 3. Variables d’environnement
$envVars = Get-ChildItem Env: | ForEach-Object { "$($_.Name),$($_.Value)" }
$envVarsText = $envVars -join "`n"
Save-Text $envVarsText "env-vars.csv"
Write-Host "✅ Variables d’environnement sauvegardées" -ForegroundColor Green

# 4. Extensions VSCode
$extensions = code --list-extensions | Out-String
Save-Text $extensions "vscode-extensions.txt"
Write-Host "✅ Extensions VSCode sauvegardées" -ForegroundColor Green

# 5. Réglages VSCode
Save-Item "$env:APPDATA\Code\User\settings.json" "vscode-settings.json"
Write-Host "✅ Réglages VSCode copiés" -ForegroundColor Green

# 6. Profil Git
Save-Item "$env:USERPROFILE\.gitconfig" ".gitconfig"
Write-Host "✅ Fichier .gitconfig sauvegardé" -ForegroundColor Green

# 7. Clés SSH
Save-ItemWithExclusions "$env:USERPROFILE\.ssh" "ssh" @("known_hosts.old", "config.bak")
Write-Host "✅ Clés SSH sauvegardées (fichiers inutiles exclus)" -ForegroundColor Green

# 8. Fly.io
Save-ItemWithExclusions "$env:USERPROFILE\.fly" "fly" @("bin", "flyctl.exe", "flyctl", "wintun.dll")
Write-Host "✅ Config Fly.io sauvegardée (sans le dossier bin ni les exécutables)" -ForegroundColor Green

# 9. Dossier .config (avec exclusions)
Save-ItemWithExclusions "$env:USERPROFILE\.config" "config" @("__pycache__", "cache", "temp")
Write-Host "✅ Dossier .config sauvegardé (exclusions appliquées)" -ForegroundColor Green

# 10. Fichiers .env (renommés par projet)
Copy-EnvFilesToBoth

# 🎉 Fin
Write-Host "`n🎉 Sauvegarde complète terminée dans : $backupTimestamped" -ForegroundColor Cyan
Write-Host "📌 Dernier backup accessible via : $backupLatest" -ForegroundColor Cyan
