@echo off
:: Vérifie si le script est lancé en admin
net session >nul 2>&1
if %errorLevel% == 0 (
    powershell -ExecutionPolicy Bypass -File "%~dp0choco-install.ps1"
) else (
    :: Relance en admin
    powershell -Command "Start-Process '%~dp0choco-install.bat' -Verb RunAs"
)w
pause