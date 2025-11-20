param (
    [string]$AppFolder = "$env:APPDATA",
    [int]$Depth = 2
)

Write-Host "`n📦 Analyse de $AppFolder`n" -ForegroundColor Cyan

# Liste les sous-dossiers
$folders = Get-ChildItem -Path $AppFolder -Directory

foreach ($folder in $folders) {
    $path = $folder.FullName
    $size = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $sizeMB = [math]::Round($size / 1MB, 2)

    Write-Host "📁 $($folder.Name) — $sizeMB MB" -ForegroundColor Yellow

    # Fichiers clés
    $keyFiles = Get-ChildItem -Path $path -Recurse -Include *.json,*.ini,*.conf,*.xml,*.settings -ErrorAction SilentlyContinue
    foreach ($file in $keyFiles) {
        $relative = $file.FullName.Substring($AppFolder.Length + 1)
        Write-Host "   🔹 $relative"
    }

    # Dossiers suspects (cache, logs, crash, etc.)
    $suspects = Get-ChildItem -Path $path -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match 'cache|log|crash|temp|report|shader|widevine|component'
    }
    foreach ($suspect in $suspects) {
        $relative = $suspect.FullName.Substring($AppFolder.Length + 1)
        Write-Host "   ⚠️  Suspect : $relative" -ForegroundColor DarkGray
    }

    Write-Host ""
}
