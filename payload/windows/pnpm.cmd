@echo off
setlocal
set "ROOT=%~dp0.."
"%ROOT%\bin\node.exe" "%ROOT%\runtime\node_modules\pnpm\bin\pnpm.cjs" %*
exit /b %ERRORLEVEL%
