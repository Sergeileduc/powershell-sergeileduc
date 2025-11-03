Write-Host "🔧 Nettoyage NVIDIA DXCache..."
Remove-Item "$env:LOCALAPPDATA\NVIDIA\DXCache\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "🔧 Nettoyage des artefacts OTA NVIDIA App..."
$nvidiaOtaPath = "C:\ProgramData\NVIDIA Corporation\NVIDIA App\UpdateFramework\ota-artifacts\*"
Remove-Item $nvidiaOtaPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "🔧 Nettoyage du dossier NVIDIA Downloader..."
$nvidiaDownloaderPath = "C:\ProgramData\NVIDIA Corporation\Downloader\*"
Remove-Item $nvidiaDownloaderPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "🔧 Nettoyage NVIDIA GLCache..."
Remove-Item "$env:LOCALAPPDATA\NVIDIA\GLCache\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "🔧 Nettoyage Chrome Cache..."
$chromeCachePaths = @(
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache\*",
  "$env:LOCALAPPDATA\Google\Chrome\User Data\ShaderCache\*",
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Crashpad\*"
)

foreach ($path in $chromeCachePaths) {
  Write-Host "  → Suppression de $path"
  Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "🔧 Nettoyage Chrome Service Worker caches..."
$swCachePaths = @(
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Service Worker\CacheStorage\*",
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Service Worker\ScriptCache\*"
)

foreach ($path in $swCachePaths) {
  Write-Host "  → Suppression de $path"
  Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "🔧 Suppression du dossier OptGuideOnDeviceModel..."
$optGuidePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\OptGuideOnDeviceModel"
if (Test-Path $optGuidePath) {
  Remove-Item $optGuidePath -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "  → Supprimé : $optGuidePath"
} else {
  Write-Host "  → Dossier absent : $optGuidePath"
}

Write-Host "🔧 Nettoyage Edge caches..."
$edgePaths = @(
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\ShaderCache\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Crashpad\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Service Worker\CacheStorage\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Service Worker\ScriptCache\*"
)

foreach ($path in $edgePaths) {
  Write-Host "  → Suppression de $path"
  Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "🔧 Suppression du dossier ProvenanceData (Edge)..."
$provPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\ProvenanceData"
if (Test-Path $provPath) {
  Remove-Item $provPath -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "  → Supprimé : $provPath"
} else {
  Write-Host "  → Dossier absent : $provPath"
}

Write-Host "🔧 Nettoyage des caches CRX (Edge)..."
$crxPaths = @(
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\component_crx_cache\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\extensions_crx_cache\*"
)

foreach ($path in $crxPaths) {
  Write-Host "  → Suppression de $path"
  Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "🔧 Nettoyage des fichiers temporaires OneDrive..."
$oneDrivePaths = @(
  "$env:LOCALAPPDATA\Microsoft\OneDrive\logs\*",
  "$env:LOCALAPPDATA\Microsoft\OneDrive\setup\*",
  "$env:LOCALAPPDATA\Microsoft\OneDrive\temp\*",
  "$env:LOCALAPPDATA\Microsoft\OneDrive\Telemetry\*"
)

foreach ($path in $oneDrivePaths) {
  Write-Host "  → Suppression de $path"
  Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "🔧 Nettoyage du dossier Temp..."
$tempPath = "$env:LOCALAPPDATA\Temp\*"
Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "🔧 Nettoyage des caches VS Code..."
$vsCodePaths = @(
  "$env:APPDATA\Code\Cache\*",
  "$env:APPDATA\Code\CachedData\*",
  "$env:APPDATA\Code\CachedExtensionVSIXs\*",
  "$env:APPDATA\Code\crashpad\*",
  "$env:APPDATA\Code\GPUCache\*",
  "$env:APPDATA\Code\webstorage\*"
)

foreach ($path in $vsCodePaths) {
  Write-Host "  → Suppression de $path"
  Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "🔧 Nettoyage des caches Discord..."
$discordPaths = @(
  "$env:APPDATA\discord\Cache\*",
  "$env:APPDATA\discord\logs\*"
)

foreach ($path in $discordPaths) {
  Write-Host "  → Suppression de $path"
  Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "🔧 Nettoyage du cache pip..."
$pipCachePath = "$env:LOCALAPPDATA\pip\cache\*"
Remove-Item $pipCachePath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n✅ Nettoyage terminé."
Read-Host "Appuie sur Entrée pour fermer"
