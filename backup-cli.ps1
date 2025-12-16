# backup-menu.ps1 — CLI launcher

Write-Host "=== Menu de sauvegarde ===" -ForegroundColor Cyan
Write-Host "1 - Backup env"
Write-Host "2 - Backup env + AppData"
Write-Host "3 - Backup games"
Write-Host "4 - Backup all"
Write-Host "Q - Quitter"
Write-Host ""

$choice = Read-Host "Votre choix"

switch ($choice) {
    "1" { & "$PSScriptRoot\backup.ps1" -Section env }
    "2" { & "$PSScriptRoot\backup.ps1" -Section envappdata }
    "3" { & "$PSScriptRoot\backup.ps1" -Section games }
    "4" { & "$PSScriptRoot\backup.ps1" -Section all }
    "Q" { Write-Host "Bye 👋"; return }
    default { Write-Host "Choix invalide" -ForegroundColor Red }
}
