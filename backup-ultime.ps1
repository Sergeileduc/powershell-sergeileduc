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
Import-Module (Join-Path $oneDriveDocs "backup-functions.psm1")


# Dossier temporaire local
$staging = "$env:USERPROFILE\TempBackupStaging"
if (Test-Path $staging) {
    Write-Host "🧹 Suppression du dossier temporaire existant..."
    Remove-Item $staging -Recurse -Force
}
Write-Host "📁 Création du dossier temporaire : $staging"
New-Item -ItemType Directory -Path $staging | Out-Null

# Rediriger les fonctions Save vers le staging
<# En fait, nos fonctions utilisent des variables globales pour les chemins de backup.
Donc, on définit ces variables globales pour pointer vers le staging temporaire.
Normalement, dans backup-functions.ps1, ces variables seraient définies pour pointer vers le dossier OneDrive.
Mais comme ça merde, bah tant pis, on passe par staging.
Et on fera un move final du staging vers OneDrive à la fin du script.
#>
$global:backupTimestamped = $staging
$global:backupLatest = $staging

# 1. Chocolatey
$tempChocoExport = Join-Path $env:TEMP "packages-choco.config"
choco export --include-version-numbers $tempChocoExport

if (Test-Path $tempChocoExport) {
  Save $tempChocoExport "packages-choco.config"
  Write-Host "✅ Chocolatey exporté et copié dans les deux backups" -ForegroundColor Green
  Remove-Item $tempChocoExport
} else {
  Write-Host "❌ Échec de l’export Chocolatey — fichier introuvable : $tempChocoExport" -ForegroundColor Red
}

# 2. pip
$pipList = pip freeze | Out-String
Save -textContent $pipList -relativeTarget "requirements.txt"
Write-Host "✅ pip freeze enregistré" -ForegroundColor Green

# 3. Variables d’environnement
$envVars = Get-ChildItem Env: | ForEach-Object { "$($_.Name),$($_.Value)" }
$envVarsText = $envVars -join "`n"
Save -textContent $envVarsText -relativeTarget "env-vars.csv"
Write-Host "✅ Variables d’environnement sauvegardées" -ForegroundColor Green

# 4. Extensions VSCode
$extensions = code --list-extensions | Out-String
Save -textContent $extensions -relativeTarget "vscode-extensions.txt"
Write-Host "✅ Extensions VSCode sauvegardées" -ForegroundColor Green

# 5. Réglages VSCode
Save -sourcePath "$env:APPDATA\Code\User\settings.json" -relativeTarget "vscode-settings.json"
Write-Host "✅ Réglages VSCode copiés" -ForegroundColor Green

# 6. Profil Git
Save -sourcePath "$env:USERPROFILE\.gitconfig" -relativeTarget ".gitconfig"
Write-Host "✅ Fichier .gitconfig sauvegardé" -ForegroundColor Green

# 7. Clés SSH
Save -sourcePath "$env:USERPROFILE\.ssh" -relativeTarget "ssh" -excludeNames @("known_hosts.old", "config.bak")
Write-Host "✅ Clés SSH sauvegardées (fichiers inutiles exclus)" -ForegroundColor Green

# 8. Fly.io
Save -sourcePath "$env:USERPROFILE\.fly" -relativeTarget "fly" -excludeNames @(
    "bin", "flyctl.exe", "flyctl", "wintun.dll", "fly.exe", "fly.exe.old", "fly-agent.sock"
)

Write-Host "✅ Config Fly.io sauvegardée (sans le dossier bin ni les exécutables)" -ForegroundColor Green

# 9. Dossier .config (avec exclusions)
Save -sourcePath "$env:USERPROFILE\.config" -relativeTarget "config" -excludeNames @("__pycache__", "cache", "temp")
Write-Host "✅ Dossier .config sauvegardé (exclusions appliquées)" -ForegroundColor Green

# 10. Fichiers .env (renommés par projet)
Copy-EnvFilesToBoth


# Dossiers finaux dans OneDrive
$root = Join-Path "$env:USERPROFILE\OneDrive\Documents" "AAA-important\geek\backup"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$target = Join-Path $root $timestamp
$latest = Join-Path $root "latest"

Write-Host "📁 Création du dossier horodaté : $target"
New-Item -ItemType Directory -Path $target -Force | Out-Null

Write-Host "📁 Mise à jour du dossier latest : $latest"
if (Test-Path $latest) {
    Remove-Item $latest -Recurse -Force
}
New-Item -ItemType Directory -Path $latest | Out-Null

# 11. 🚚 Déplacement du staging vers le dossier horodaté (y compris fichiers cachés)
Write-Host "🚚 Déplacement du staging vers le dossier horodaté..."
Copy-Item -Path "$staging\*" -Destination $target -Recurse -Force
Remove-Item -Path "$staging\*" -Recurse -Force

# 12. 📋 Copie vers le dossier latest (y compris fichiers cachés)
Write-Host "📋 Copie vers le dossier latest..."
Copy-Item -Path "$target\*" -Destination $latest -Recurse -Force

# 13. 📊 Résumé de la sauvegarde
$filesCount = (Get-ChildItem $target -Recurse -File -Force).Count
Write-Host "📊 $filesCount fichiers sauvegardés dans $target" -ForegroundColor Cyan
Write-Host "✅ Sauvegarde complète terminée dans :"
Write-Host "   - $target"
Write-Host "   - $latest"

# 14. 🧹 Suppression du dossier de staging
Write-Host "🧹 Suppression du dossier de staging..."
Remove-Item -Path $staging -Recurse -Force

# 15. 🎉 Fin du script
if ($filesCount -eq 0) {
    Write-Host "⚠️ Aucun fichier sauvegardé — vérifie tes exclusions ou ton dossier source." -ForegroundColor Red
} else {
    Write-Host "🎉 Sauvegarde complète terminée avec succès !" -ForegroundColor Green
}
