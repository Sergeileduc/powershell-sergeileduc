# 🧰 backup-dev.ps1

Script PowerShell pour sauvegarder l’environnement de développement d’un utilisateur Windows.  
Il centralise les éléments critiques dans un dossier de backup versionné et prêt à être restauré.

---

## 📦 Fonctionnalités

Ce script sauvegarde :

- ✅ Paquets installés avec **Chocolatey**
- 🐍 Paquets Python installés via **pip**
- ⚙️ Variables d’environnement utilisateur
- 🧠 Extensions et réglages **VSCode**
- 🧑‍💻 Profil **Git** (`.gitconfig` + clés SSH)
- ☁️ Profil **Fly.io** (`.fly/config.yml`, `auth.json`)
- 🗂️ Dossier **.config** (avec exclusions : `__pycache__`, `cache`, `temp`)
- 🔐 Fichiers **.env** (renommés avec le nom du dossier projet)

---

## 🕒 Versionnement

Chaque exécution crée deux dossiers :

- `backup-YYYY-MM-DD` → version horodatée
- `backup-latest` → copie du dernier backup, utilisée par défaut pour la restauration

---

## 📁 Structure du dossier de backup

```bash
backup/
├── backup-YYYY-MM-DD/         # Version horodatée du backup
│   ├── packages-choco.config  # Paquets Chocolatey
│   ├── requirements.txt       # Paquets pip
│   ├── env-vars.csv           # Variables d’environnement
│   ├── vscode-extensions.txt  # Extensions VSCode
│   ├── vscode-settings.json   # Réglages VSCode
│   ├── gitconfig              # Fichier .gitconfig
│   ├── ssh/                   # Clés SSH
│   ├── fly/                   # Config Fly.io
│   ├── config/                # Dossier .config (exclusions appliquées)
│   └── env-files/             # Fichiers .env renommés par projet
│       ├── mon-api.env
│       └── site-web.env
├── backup-latest/             # Copie du dernier backup (pour restauration rapide)
│   └── (identique à backup-YYYY-MM-DD)

```

---

## 🚀 Utilisation

1. Ouvre PowerShell
2. Exécute le script :

   ```powershell
   .\backup-perso.ps1
   ```

Le dossier de backup est créé dans :
OneDrive\Documents\AAA-important\geek\backup\
