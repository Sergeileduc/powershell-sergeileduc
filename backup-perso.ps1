param (
    [string]$LocalRoot   = "$env:USERPROFILE\MyBackups",
    [string]$Name        = 'env-perso',
    [string]$CloudRoot   = "$env:USERPROFILE\OneDrive\Documents\AAA-important\geek\backup",
    [switch]$IncludeAppData
)
# SaveAppdata takes a long time and is not always necessary.

<#
  .SYNOPSIS
  Script de sauvegarde de l'environnement de développement
  Destination par défaut : $env:USERPROFILE\Backups
  Copie vers OneDrive\Documents\AAA-important\geek\backup\

  Sauvegarde :
    - Chocolatey
    - pip
    - Variables d'environnement
    - VSCode (extensions + settings)
    - Git (.gitconfig + clés SSH)
    - Fly.io (config + auth)
    - Dossier .config (avec exclusions)
    - Fichiers .env (renommés par projet)
    - wezterm config
    - AppData (complet ou ciblé, selon flag)
    - Version horodatée + version "latest"

  .PARAMETER BackupFolder
  Nom du dossier de backup (sera créé sous le chemin défini par -Path).

  .PARAMETER Name
  Nom logique de la sauvegarde (par défaut : 'env').

  .PARAMETER Path
  Chemin racine où stocker les backups (par défaut : $env:USERPROFILE\Backups).

  .PARAMETER IncludeAppData
  Active la sauvegarde du répertoire %APPDATA%.
  - Si présent : copie tout %APPDATA% (hors exclusions éventuelles).
  - Si absent : ignore la sauvegarde AppData pour accélérer le backup.

  .EXAMPLE
  .\backup-perso.ps1
  Lance le backup standard sans inclure AppData.

  .EXAMPLE
  .\backup-perso.ps1 -IncludeAppData
  Lance le backup complet en incluant la sauvegarde de %APPDATA%.

  .EXAMPLE
  .\backup-perso.ps1 -BackupFolder mybackup -Name dev -Path "D:\Backups"
  Lance le backup nommé 'dev' dans D:\Backups\mybackup.

  .NOTES
  Attention : %APPDATA% peut contenir un grand nombre de petits fichiers (caches, logs, profils).
  La sauvegarde peut donc prendre plusieurs minutes et générer un volume conséquent.
  Il est recommandé d’utiliser des exclusions ciblées pour éviter de copier des données inutiles.
#>

# # Sécurité et cohérence
# Set-StrictMode -Version Latest


function Finalize-Env {
    param(
        [string]$LocalFolder,
        [string]$CloudRoot = "$env:USERPROFILE\OneDrive\Documents\AAA-important\geek\backup",
        [string]$Name = "env-perso",
        [int]$Rotation = 3
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmm"
    $destRoot  = Join-Path $CloudRoot "env"
    $latest    = Join-Path $destRoot "latest"
    $snapshot  = Join-Path $destRoot $timestamp

    Write-Host "📂 Finalisation ENV '$Name' → $latest et $snapshot"

    # Prune le dossier latest avant copie
    if (Test-Path $latest) {
        Remove-Item -LiteralPath $latest -Recurse -Force
        Write-Host "🧹 Dossier latest Env nettoyé."
    }

    foreach ($p in @($latest, $snapshot)) {
        if (-not (Test-Path $p)) {
            New-Item -ItemType Directory -Path $p -Force | Out-Null
        }
    }

    # Copie miroir vers latest
    Copy-Item -Path "$LocalFolder\*" -Destination $latest -Recurse -Force

    # Copie snapshot horodaté
    Copy-Item -Path "$LocalFolder\*" -Destination $snapshot -Recurse -Force

    # Rotation : supprime les snapshots les plus anciens
    $snapshots = Get-ChildItem $destRoot -Directory |
                 Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}_\d{4}$' } |
                 Sort-Object Name
    if ($snapshots.Count -gt $Rotation) {
        $toDelete = $snapshots | Select-Object -First ($snapshots.Count - $Rotation)
        foreach ($d in $toDelete) {
            Write-Host "🗑️ Suppression snapshot ancien : $($d.FullName)"
            Remove-Item $d.FullName -Recurse -Force
        }
    }
}


# Variables perso
$devPath = Join-Path -Path $env:USERPROFILE -ChildPath "Dev"

# Chemin vers le dossier OneDrive Documents
$oneDriveScripts = Join-Path "$env:USERPROFILE\OneDrive\Documents" "Scripts\Powershell"
# Importe les fonctions
Import-Module (Join-Path $oneDriveScripts "SergeBackup")


# Dossier local
if (-not $BackupFolder) {
    $BackupFolder = Init-BackupFolder -folderName $Name -customPath $LocalRoot
}
Write-Host "📂 Dossier de backup créé : $BackupFolder" -ForegroundColor Cyan


# 1. Chocolatey
$tempChocoExport = Join-Path $env:TEMP "packages-choco.config"
choco export --include-version-numbers $tempChocoExport

if (Test-Path $tempChocoExport) {
  Save -sourcePath $tempChocoExport -targetPath "$BackupFolder\packages-choco.config"
  Write-Host "✅ Chocolatey exporté" -ForegroundColor Green
  Remove-Item $tempChocoExport
} else {
  Write-Host "❌ Échec de l'export Chocolatey — fichier introuvable : $tempChocoExport" -ForegroundColor Red
}

# 2. pip
$pipList = pip freeze | Out-String
Save -textContent $pipList -targetPath "$BackupFolder\pip\requirements-freeze.txt"
Write-Host "✅ pip freeze enregistré (versions figées)" -ForegroundColor Green

# 2.5 pip (version loose, sans versions)
$pipLoose = pip list --not-required --format=freeze | ForEach-Object { ($_ -split '==')[0] } | Out-String
Save -textContent $pipLoose -targetPath "$BackupFolder\pip\requirements-loose.txt"
Write-Host "✅ pip loose enregistré (sans versions, paquets explicites)" -ForegroundColor Green


# 3. Variables d’environnement
$envVars = Get-ChildItem Env: | ForEach-Object { "$($_.Name),$($_.Value)" }
$envVarsText = $envVars -join "`n"
Save -textContent $envVarsText -targetPath "$BackupFolder\env-vars.csv"
Write-Host "✅ Variables d’environnement sauvegardées" -ForegroundColor Green

# 4. Extensions VSCode
$extensions = code --list-extensions | Out-String
Save -textContent $extensions -targetPath "$BackupFolder\Code\vscode-extensions.txt"
Write-Host "✅ Extensions VSCode sauvegardées" -ForegroundColor Green

# 5. Réglages VSCode + Snippets
Save -sourcePath "$env:APPDATA\Code\User\settings.json" -targetPath "$BackupFolder\Code\User\"
Save -sourcePath "$env:APPDATA\Code\User\keybindings.json" -targetPath "$BackupFolder\Code\User\"
if (Test-Path "$env:APPDATA\Code\User\snippets") {
    Save -sourcePath "$env:APPDATA\Code\User\snippets" -targetPath "$BackupFolder\Code\User\"
} else {
    Write-Host "⚠️ Dossier snippets absent, rien à sauvegarder."
}



Write-Host "✅ Réglages VSCode copiés" -ForegroundColor Green

# 6. Profil Git
Save -sourcePath "$env:USERPROFILE\.gitconfig" -targetPath "$BackupFolder\"
# Rendre le fichier visible dans le backup
(Get-Item "$BackupFolder\.gitconfig" -Force).Attributes = (Get-Item "$BackupFolder\.gitconfig" -Force).Attributes -bxor [System.IO.FileAttributes]::Hidden
Write-Host "✅ Fichier .gitconfig sauvegardé" -ForegroundColor Green

# 7. Clés SSH
Save -sourcePath "$env:USERPROFILE\.ssh" -targetPath "$BackupFolder\ssh" -exclusions @("known_hosts.old", "config.bak")
Write-Host "✅ Clés SSH sauvegardées (fichiers inutiles exclus)" -ForegroundColor Green

# 8. Fly.io
Save -sourcePath "$env:USERPROFILE\.fly" -targetPath "$BackupFolder\fly" -exclusions @(
    "bin", "flyctl.exe", "flyctl", "wintun.dll", "fly.exe", "fly.exe.old", "fly-agent.sock"
)
Write-Host "✅ Config Fly.io sauvegardée (sans le dossier bin ni les exécutables)" -ForegroundColor Green

# 9. Dossier .config (avec exclusions)
Save -sourcePath "$env:USERPROFILE\.config" -targetPath "$BackupFolder\.config" -exclusions @("__pycache__", "cache", "temp")
Write-Host "✅ Dossier .config sauvegardé (exclusions appliquées)" -ForegroundColor Green

# 10. Fichiers .env (renommés par projet)
Copy-EnvFiles -targetPath "$BackupFolder\env" -sourcePath $devPath
Write-Host "✅ Fichiers .env sauvegardés" -ForegroundColor Green

# 11. Réglages Wezterm
Save -sourcePath "$env:USERPROFILE\.wezterm.lua" -targetPath "$BackupFolder"
(Get-Item "$BackupFolder\.wezterm.lua" -Force).Attributes = (Get-Item "$BackupFolder\.wezterm.lua" -Force).Attributes -bxor [System.IO.FileAttributes]::Hidden
Write-Host "✅ Réglages Wezterm copiés" -ForegroundColor Green

# 12. Réglages Windows Terminal
Save -sourcePath "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" `
     -targetPath "$BackupFolder\WindowsTerminal\"
Write-Host "✅ Réglages Windows Terminal copiés" -ForegroundColor Green

# 13. AppData Roaming (sélection)
if ($IncludeAppData) {
        Save-AppData `
        -TargetPath "$BackupFolder\AppData" `
        -ExcludeFolders @(
            '.git',
            'models',
            'download\storage',
            'LibreOffice\4\updates',
            'security_state',
            'Stirling-PDF',
            'discord',
            'AutomaticDestinations',
            'Code\User\globalStorage',
            'Code\User\globalStorage\github.copilot-chat',
            'Opera Software\Opera Stable\adblocker_data',
            'Opera Software\Opera Stable\Safe Browsing',
            'Opera Software\Opera Stable\Default\IndexedDB',
            'Opera Software\Opera Stable\Default\Extensions'
        ) `
        -ExcludeExtensions @(
            '.log',
            '.bak',
            '.pak',
            '.pma',
            '.exe',
            '.dll',
            '.sqlite',
            '.lock',
            '.sst',
            '.ldb'
        )
}


# 📊 Résumé de la sauvegarde
$filesCount = (Get-ChildItem $BackupFolder -Recurse -File -Force).Count
Write-Host "📊 $filesCount fichiers sauvegardés dans $BackupFolder" -ForegroundColor Cyan

# # 🧹 Suppression du dossier de staging
# Write-Host "🧹 Suppression du dossier de staging..."
# Remove-Item -Path $BackupFolder -Recurse -Force

# 🎉 Fin du script
if ($filesCount -eq 0) {
    Write-Host "⚠️ Aucun fichier sauvegardé — vérifie tes exclusions ou ton dossier source." -ForegroundColor Red
} else {
    Write-Host "🎉 Sauvegarde complète terminée avec succès !" -ForegroundColor Green
}

Finalize-Env -LocalFolder $BackupFolder -CloudRoot $CloudRoot -Rotation $Rotation
Write-Host "✅ Backup ENV terminé."
