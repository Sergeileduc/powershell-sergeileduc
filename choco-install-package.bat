@echo off
:: Vérifie si le script est lancé en admin
net session >nul 2>&1
if %errorLevel% == 0 (
    powershell -ExecutionPolicy Bypass -File "%~dp0choco-install-package.ps1"
) else (
    :: Relance en admin
    powershell -Command "Start-Process '%~dp0choco-install-package.bat' -Verb RunAs"
)
pause