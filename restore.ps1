# restore.ps1
Write-Host "=== Script de restauration (squelette) ===" -ForegroundColor Cyan

$steps = @(
    "1. Exécuter 'choco install packages-choco.config -y' pour réinstaller les logiciels.",
    "2. Exécuter 'pip install -r requirements-freeze.txt' pour restaurer les dépendances Python.",
    "3. Copier les réglages VSCode (settings.json, snippets, extensions).",
    "4. Restaurer .gitconfig et clés SSH.",
    "5. Vérifier Fly.io et autres configs (.config, .env).",
    "6. Replacer les réglages Wezterm et Windows Terminal.",
    "7. Reconfigurer raccourcis personnalisés (yt-dlp GUI, etc.)."
)

foreach ($step in $steps) {
    Write-Host $step -ForegroundColor Yellow
    Read-Host "Appuie sur Entrée quand c'est fait"
}

Write-Host "=== Fin du squelette ===" -ForegroundColor Green
