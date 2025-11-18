# 🧠 SergeBackup

Un framework PowerShell modulaire pour orchestrer des sauvegardes locales, versionnées et OneDrive-friendly — sans magie noire, sans dépendance externe, et avec une touche de philosophie.

## 📦 Structure

```
📁 Scripts\Powershell\
├───📄 backup.ps1               # Lanceur principal : exécute les profils et finalise la sauvegarde
├───📄 backup-games.ps1         # Script de sauvegarde pour les jeux (via YAML)
├───📄 backup-gui.ps1           # Interface graphique expérimentale
├───📄 backup-perso.ps1         # Script de sauvegarde pour l’environnement utilisateur
├───📄 backup-unit-test.ps1     # Tests unitaires pour les fonctions de backup
├───📄 backup-perso.md          # Notes et documentation perso
└───📁 SergeBackup\
    ├───📄 SergeBackup.psm1     # Module principal : fonctions Invoke-BackupX
    ├───📄 SergeBackup.psd1     # Manifest du module
    └───📄 README.md            # Ce fichier
```

## 🚀 Utilisation

### 🔹 Lancer une sauvegarde

```powershell
.\backup.ps1 -Section env
.\backup.ps1 -Section games
.\backup.ps1 -Section all
```

Sans paramètre, `backup.ps1` exécute toutes les sections définies.

### 🔹 Depuis le module

```powershell
Import-Module .\SergeBackup\SergeBackup.psm1

Invoke-BackupEnv   -Name 'env'
Invoke-BackupGames -Name 'games'
```

## 🧩 Fonctionnement

1. `Init-BackupFolder` crée un dossier de staging temporaire
2. Le script de profil (`backup-perso.ps1`, `backup-games.ps1`, etc.) y dépose les fichiers à sauvegarder
3. `Finalize-Backup` copie ce dossier vers :
   - un dossier horodaté (`YYYY-MM-DD_HH-mm`)
   - un dossier `latest` (copie réelle, pas de symlink — compatible OneDrive)

## 🛠️ Personnalisation

- Ajoutez vos propres profils : créez `backup-<nom>.ps1` et une fonction `Invoke-Backup<Nom>` dans `SergeBackup.psm1`
- Le staging est centralisé : tous les profils peuvent écrire dans le même dossier
- Le dossier final est configurable (par défaut dans OneDrive/Documents/AAA-important/geek/backup)

## 📋 TODO (extraits)

- [ ] Ajouter des raccourcis `.lnk` avec icônes personnalisées
- [ ] Ajouter des alias PowerShell (`backup-env`, `backup-games`)
- [ ] Ajouter un petit log `.txt` dans chaque backup horodaté

## 🧘 Philosophie

> “Ce backup n’est qu’un instant figé dans le chaos.”

Ce projet est né d’un besoin simple : automatiser ses sauvegardes sans complexité inutile, tout en gardant le contrôle. Chaque script est autonome, lisible, testable. Pas de dépendance obscure, pas de magie implicite.
