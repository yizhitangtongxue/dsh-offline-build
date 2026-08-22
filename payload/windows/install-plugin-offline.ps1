param(
  [Parameter(Mandatory=$true, Position=0)]
  [string]$Plugin
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $env:DSH_HOME) { $env:DSH_HOME = Join-Path $Root "dsh-home" }
$env:PATH = "$(Join-Path $Root 'bin');$env:PATH"

$Node = Join-Path $Root "bin\node.exe"
$Cli = Join-Path $Root "runtime\node_modules\@deepseek-ai\dsh\lib\bin.js"

if (Test-Path $Plugin) { $Plugin = (Resolve-Path $Plugin).Path }

& $Node $Cli plugin --profile web add --offline $Plugin
if ($LASTEXITCODE -ne 0) {
  & $Node $Cli plugin --profile web approve-builds --all
  if ($LASTEXITCODE -ne 0) { throw "Native dependency approval failed" }
  & $Node $Cli plugin --profile web add --offline $Plugin
  if ($LASTEXITCODE -ne 0) { throw "Offline plugin install failed: $Plugin" }
}

Write-Host "Plugin installed: $Plugin"
Write-Host "Restart DSH to load the plugin."
