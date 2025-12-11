# 🧰 SergeBackup

**SergeBackup** est un module PowerShell minimaliste et modulaire conçu pour automatiser les sauvegardes de configuration, d’environnement, et de fichiers critiques. Il centralise toute la logique dans une seule fonction `Save`, avec des fonctions internes spécialisées pour gérer les cas particuliers (exclusions, contenu texte, etc.).

---

## 📦 Fonctionnalités

- Sauvegarde de fichiers, dossiers, et contenu texte
- Exclusion de fichiers/dossiers par nom
- Initialisation d’un dossier temporaire de staging
- Structure modulaire et testable
- Facile à intégrer dans un script de backup personnel
- Sauvegarde rapide des répertoires AppData via `Save-AppData`

---

## 🚀 Installation

Clone le repo ou copie le module dans ton dossier de scripts PowerShell :

```powershell
git clone https://github.com/Sergeileduc/powershell-sergeileduc.git
Import-Module ./SergeBackup/SergeBackup.psm1
```

---

## Architecture du module

```bash
SergeBackup.psm1
│
├── Save(textContent?, sourcePath?, targetPath, exclusions?)
│   │
│   ├── Si textContent → écrit fichier texte
│   ├── Sinon si exclusions → Save-ItemWithExclusions
│   └── Sinon → Copy-Item brut
│
├── Save-ItemWithExclusions(sourcePath, targetPath, exclusions)
│   └── Copie récursive en filtrant les noms exclus
│
├── Save-AppData(appName?, targetPath, exclusions?)
│   ├── Si appName → copie %APPDATA%\appName
│   └── Si appName absent → copie tout %APPDATA%
│
├── Init-StagingFolder(folderName?, customPath?, CleanOnly?)
│   └── Initialise ou nettoie le dossier temporaire
│
└── (Autres fonctions utilitaires éventuelles)
    ├── Copy-EnvFiles
    ├── Save-RegistryKeys
    └── etc.
```

---

## Options de `Save-AppData`

- `-appName` : nom du sous-dossier dans `%APPDATA%` (ex. `"Code"`, `"Mozilla"`)  
- `-targetPath` : destination du backup  
- `-exclusions` *(optionnel)* : liste de fichiers/dossiers à ignorer  
- **Cas spécial** : si `-appName` est omis, la fonction sauvegarde **tout `%APPDATA%`** (hors exclusions)

---

## Exemples d'utilisation

### Initialisation du dossier de backup

```powershell
$backupFolder = Init-BackupFolder -customPath "$env:USERPROFILE"
```

### Sauvegarde de fichiers et contenu

```powershell
Save -sourcePath "$env:APPDATA\Code\User\settings.json" -targetPath "$backupFolder\vscode\vscode-settings.json"
Save -sourcePath "$env:USERPROFILE\.ssh" -targetPath "$backupFolder\ssh" -exclusions @("known_hosts", "config.old")
Save -textContent (pip freeze) -targetPath "$backupFolder\packages\pip.txt"
```

### Sauvegarde rapide d’un répertoire AppData

```powershell
# Sauvegarde ciblée
Save-AppData -appName "Code" -targetPath "$backupFolder\vscode"
Save-AppData -appName "Mozilla" -targetPath "$backupFolder\firefox" -exclusions @("Cache", "Crash Reports")

# Sauvegarde complète de tout %APPDATA%
Save-AppData -targetPath "$backupFolder\all-appdata"
Save-AppData -targetPath "$backupFolder\all-appdata" -exclusions @("Temp", "Microsoft\Teams\Cache")
```

### Duplication vers les destinations finales

```powershell
$root = "$env:USERPROFILE\OneDrive\Documents\AAA-important\geek\backup"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$target = Join-Path $root $timestamp
$latest = Join-Path $root "latest"

Copy-Item -Path $staging -Destination $latest -Recurse -Force
Copy-Item -Path $staging -Destination $target -Recurse -Force
```
