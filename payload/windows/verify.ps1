param()

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $env:DSH_HOME) { $env:DSH_HOME = Join-Path $Root "dsh-home" }
$env:PATH = "$(Join-Path $Root 'bin');$env:PATH"

$Node = Join-Path $Root "bin\node.exe"
$Cli = Join-Path $Root "runtime\node_modules\@deepseek-ai\dsh\lib\bin.js"
$Profile = Join-Path $env:DSH_HOME "profiles\web\package.json"

if (-not (Test-Path $Node)) { throw "Missing bin\node.exe" }
if (-not (Test-Path $Cli)) { throw "Missing DSH CLI" }
if (-not (Test-Path $Profile)) { throw "Missing web profile: $Profile" }

& $Node --version
if ($LASTEXITCODE -ne 0) { throw "Node.js failed" }
& $Node $Cli --version
if ($LASTEXITCODE -ne 0) { throw "DSH failed" }

$config = (& $Node $Cli --profile web --dump-config 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0) { throw "DSH config dump failed`n$config" }

$required = @(
  "web-ui-task-board",
  "web-ui-git-graph",
  "web-ui-plugin-manager",
  "web-ui-better-sidebar"
)
foreach ($name in $required) {
  if (-not $config.Contains($name)) { throw "Missing plugin config: $name" }
}

$profileJson = Get-Content -Raw $Profile | ConvertFrom-Json
if ($profileJson.dsh.profile.bundles -notcontains '@linxin666/dsh-web-ui-all') {
  throw "Profile did not load @linxin666/dsh-web-ui-all"
}

Write-Host "Verification passed: Windows x64 DSH WebUI and dsh-web-ui-all loaded."
