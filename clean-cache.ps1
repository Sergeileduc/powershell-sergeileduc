# 🔧 NVIDIA
Write-Host "`n🔧 Nettoyage NVIDIA"
Clear-Folder @(
  @{ Path = "$env:LOCALAPPDATA\NVIDIA\DXCache\*"; Label = "DXCache" },
  @{ Path = "$env:LOCALAPPDATA\NVIDIA\GLCache\*"; Label = "GLCache" },
  @{ Path = "C:\ProgramData\NVIDIA Corporation\Downloader\*"; Label = "Downloader" },
  @{ Path = "C:\ProgramData\NVIDIA Corporation\NVIDIA App\UpdateFramework\ota-artifacts\*"; Label = "OTA Artifacts" }
)

# 🔧 Chrome
Write-Host "`n🔧 Nettoyage Chrome"
Clear-Folder @(
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache\*",
  "$env:LOCALAPPDATA\Google\Chrome\User Data\ShaderCache\*",
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Crashpad\*",
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Service Worker\CacheStorage\*",
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Service Worker\ScriptCache\*"
)

# Suppression spécifique
$optGuidePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\OptGuideOnDeviceModel"
Write-Host "🧹 OptGuideOnDeviceModel → $optGuidePath"
if (Test-Path $optGuidePath) {
  Remove-Item $optGuidePath -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "✅ Supprimé"
} else {
  Write-Host "⚠️ Dossier absent"
}

# 🔧 Edge
Write-Host "`n🔧 Nettoyage Edge"
Clear-Folder @(
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\ShaderCache\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Crashpad\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Service Worker\CacheStorage\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Service Worker\ScriptCache\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\component_crx_cache\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\extensions_crx_cache\*"
)

# Suppression spécifique
$provPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\ProvenanceData"
Write-Host "🧹 ProvenanceData → $provPath"
if (Test-Path $provPath) {
  Remove-Item $provPath -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "✅ Supprimé"
} else {
  Write-Host "⚠️ Dossier absent"
}

# 🔧 OneDrive
Write-Host "`n🔧 Nettoyage OneDrive"
Clear-Folder @(
  "$env:LOCALAPPDATA\Microsoft\OneDrive\logs\*",
  "$env:LOCALAPPDATA\Microsoft\OneDrive\setup\*",
  "$env:LOCALAPPDATA\Microsoft\OneDrive\temp\*",
  "$env:LOCALAPPDATA\Microsoft\OneDrive\Telemetry\*"
)

# 🔧 VS Code
Write-Host "`n🔧 Nettoyage VS Code"
Clear-Folder @(
  "$env:APPDATA\Code\Cache\*",
  "$env:APPDATA\Code\CachedData\*",
  "$env:APPDATA\Code\CachedExtensionVSIXs\*",
  "$env:APPDATA\Code\crashpad\*",
  "$env:APPDATA\Code\GPUCache\*",
  "$env:APPDATA\Code\webstorage\*"
)

# 🔧 Discord
Write-Host "`n🔧 Nettoyage Discord"
Clear-Folder @(
  "$env:APPDATA\discord\Cache\*",
  "$env:APPDATA\discord\logs\*"
)

# 🔧 pip
Write-Host "`n🔧 Nettoyage pip"
Clear-Folder "$env:LOCALAPPDATA\pip\cache\*"

# 🔧 Temp utilisateur
Write-Host "`n🔧 Nettoyage Temp utilisateur"
Clear-Folder "$env:LOCALAPPDATA\Temp\*"

Write-Host "`n✅ Nettoyage terminé."
Read-Host "Appuie sur Entrée pour fermer"
