$packageFile = "$env:USERPROFILE\Documents\choco.txt"

if (Test-Path $packageFile) {
    Get-Content $packageFile | Where-Object { $_ -and $_.Trim() -ne "" } | ForEach-Object {
        Write-Host "Installation de $($_)..."
        choco install $_ -y
    }
} else {
    Write-Host "Fichier introuvable : $packageFile"
}