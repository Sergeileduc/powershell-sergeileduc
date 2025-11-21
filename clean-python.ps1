# Vérifie que pipdeptree est installé
if (-not (pip show pipdeptree)) {
    Write-Host "Installation de pipdeptree..." -ForegroundColor Yellow
    pip install pipdeptree
}

# Récupère les paquets non requis par d'autres
$orphans = pipdeptree --warn silence --freeze | Select-String '^\S+$' | ForEach-Object { $_.Line }

if ($orphans.Count -eq 0) {
    Write-Host "✅ Aucun paquet orphelin détecté." -ForegroundColor Green
} else {
    Write-Host "📦 Paquets orphelins détectés :" -ForegroundColor Cyan
    $orphans | ForEach-Object { " - $_" }

    # Optionnel : proposer la désinstallation
    $confirm = Read-Host "Souhaitez-vous désinstaller ces paquets ? (o/n)"
    if ($confirm -eq 'o') {
        $orphans | ForEach-Object {
            pip uninstall -y $_
        }
        Write-Host "🧹 Paquets désinstallés." -ForegroundColor Green
    } else {
        Write-Host "🚫 Désinstallation annulée." -ForegroundColor DarkYellow
    }
}
