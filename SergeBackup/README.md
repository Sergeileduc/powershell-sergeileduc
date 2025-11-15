# 🧰 SergeBackup

**SergeBackup** est un module PowerShell minimaliste et modulaire conçu pour automatiser les sauvegardes de configuration, d’environnement, et de fichiers critiques. Il centralise toute la logique dans une seule fonction `Save`, avec des fonctions internes spécialisées pour gérer les cas particuliers (exclusions, contenu texte, etc.).

---

## 📦 Fonctionnalités

- Sauvegarde de fichiers, dossiers, et contenu texte
- Exclusion de fichiers/dossiers par nom
- Initialisation d’un dossier temporaire de staging
- Structure modulaire et testable
- Facile à intégrer dans un script de backup personnel

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
├── Init-StagingFolder(folderName?, customPath?, CleanOnly?)
│   └── Initialise ou nettoie le dossier temporaire
│
└── (Autres fonctions utilitaires éventuelles)
    ├── Copy-EnvFiles
    ├── Save-RegistryKeys
    └── etc.
```

---

## Exemples d'utilisation

# Initialisation du dossier temporaire

$staging = Init-StagingFolder -customPath "$env:USERPROFILE\TempBackupStaging"

# Sauvegarde de fichiers et contenu

Save -sourcePath "$env:APPDATA\Code\User\settings.json" -targetPath "$staging\vscode\vscode-settings.json"
Save -sourcePath "$env:USERPROFILE\.ssh" -targetPath "$staging\ssh" -exclusions @("known_hosts", "config.old")
Save -textContent (pip freeze) -targetPath "$staging\packages\pip.txt"

# Duplication vers les destinations finales

$root = "$env:USERPROFILE\OneDrive\Documents\AAA-important\geek\backup"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$target = Join-Path $root $timestamp
$latest = Join-Path $root "latest"

Copy-Item -Path $staging -Destination $latest -Recurse -Force
Copy-Item -Path $staging -Destination $target -Recurse -Force
