# Crée un faux dossier de jeu
$fakeGameSource = "$env:USERPROFILE\Documents\FakeGame"
New-Item -ItemType Directory -Path $fakeGameSource -Force | Out-Null
Set-Content -Path (Join-Path $fakeGameSource "save1.dat") -Value "Fake save content"

# # Copie vers staging
# Copy-Item $fakeGameSource -Destination $BackupFolder -Recurse -Force
# Write-Host "✅ Faux jeu sauvegardé dans le dossier de staging : $BackupFolder" -ForegroundColor Green
