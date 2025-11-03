$basePath = Join-Path "$env:USERPROFILE\OneDrive\Documents" "AAA-important\geek\backup"

if (!(Test-Path $basePath)) {
    New-Item -ItemType Directory -Path $basePath -Force | Out-Null
}

$cheminFichier = Join-Path $basePath "packages-choco.config"

choco export --include-version-numbers $cheminFichier

Write-Host "✅ Choco export terminé : $cheminFichier"
# Write-Output "`n$cheminFichier`n"
