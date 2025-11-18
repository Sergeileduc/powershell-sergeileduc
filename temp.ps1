$target = "$env:USERPROFILE\OneDrive\Documents\Scripts\Powershell\launch-backup.ps1"
$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop 'Backup.lnk'
$iconPath = "$env:SystemRoot\System32\shell32.dll,43"  # Icône disque

$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$target`""
$shortcut.IconLocation = $iconPath
$shortcut.WorkingDirectory = Split-Path $target
$shortcut.Save()
