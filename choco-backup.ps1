$cheminFichier = Join-Path $env:USERPROFILE "Documents\chocopackages.txt"
choco list --id-only > $cheminFichier