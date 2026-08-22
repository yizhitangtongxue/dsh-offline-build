param(
  [string]$Workspace = "",
  [int]$Port = 0
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $env:DSH_HOME) { $env:DSH_HOME = Join-Path $Root "dsh-home" }
$env:PATH = "$(Join-Path $Root 'bin');$env:PATH"

if (-not $Workspace) {
  if ($env:DSH_WORKSPACE) { $Workspace = $env:DSH_WORKSPACE }
  else { $Workspace = (Get-Location).Path }
}
if ($Port -eq 0) {
  if ($env:DSH_PORT) { $Port = [int]$env:DSH_PORT }
  else { $Port = 3080 }
}

$Node = Join-Path $Root "bin\node.exe"
$Cli = Join-Path $Root "runtime\node_modules\@deepseek-ai\dsh\lib\bin.js"

if (-not (Test-Path $Node)) { throw "找不到便携 Node.js：$Node" }
if (-not (Test-Path $Cli)) { throw "找不到 DSH CLI：$Cli" }
if (-not (Test-Path $Workspace)) { throw "工作目录不存在：$Workspace" }

Set-Location $Workspace
Write-Host "DSH_HOME: $env:DSH_HOME"
Write-Host "Workspace: $Workspace"
Write-Host "Web UI: http://127.0.0.1:$Port"
Write-Host "API Key 不在离线包中，请在 WebUI 设置 → 模型中配置。"

& $Node $Cli web --host 127.0.0.1 --port $Port --no-open
exit $LASTEXITCODE
