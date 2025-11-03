. "$env:USERPROFILE\OneDrive\Documents\Scripts\Powershell\backup-functions.ps1"

function Backup-GameSaves {
  param (
    [string]$configPath = "$PSScriptRoot\game-saves.json"
  )

  if (!(Test-Path $configPath)) {
    Write-Host "❌ Fichier de config introuvable : $configPath" -ForegroundColor Red
    return
  }

  $gameSaves = Get-Content $configPath -Raw | ConvertFrom-Json

  $gameSaves.PSObject.Properties | ForEach-Object {
    $gameName = $_.Name
    $rawPath = $_.Value
    $expandedPath = [Environment]::ExpandEnvironmentVariables($rawPath)
    Save-File $expandedPath "saves\$gameName"
  }
}
