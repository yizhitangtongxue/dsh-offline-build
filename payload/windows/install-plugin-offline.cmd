@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-plugin-offline.ps1" %*
exit /b %ERRORLEVEL%
