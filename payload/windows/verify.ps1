param()

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $env:DSH_HOME) { $env:DSH_HOME = Join-Path $Root "dsh-home" }
$env:PATH = "$(Join-Path $Root 'bin');$env:PATH"

$Node = Join-Path $Root "bin\node.exe"
$Cli = Join-Path $Root "runtime\node_modules\@deepseek-ai\dsh\lib\bin.js"
$Profile = Join-Path $env:DSH_HOME "profiles\web\package.json"

if (-not (Test-Path $Node)) { throw "缺少 bin\node.exe" }
if (-not (Test-Path $Cli)) { throw "缺少 DSH CLI" }
if (-not (Test-Path $Profile)) { throw "缺少 Web profile：$Profile" }

& $Node --version
if ($LASTEXITCODE -ne 0) { throw "Node.js 无法运行" }
& $Node $Cli --version
if ($LASTEXITCODE -ne 0) { throw "DSH 无法运行" }

$config = (& $Node $Cli --profile web --dump-config 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0) { throw "DSH 配置读取失败`n$config" }

$required = @(
  "web-ui-task-board",
  "web-ui-git-graph",
  "web-ui-plugin-manager",
  "web-ui-better-sidebar"
)
foreach ($name in $required) {
  if (-not $config.Contains($name)) { throw "缺少插件配置：$name" }
}

$profileJson = Get-Content -Raw $Profile | ConvertFrom-Json
if ($profileJson.dsh.profile.bundles -notcontains '@linxin666/dsh-web-ui-all') {
  throw "Profile 未加载 @linxin666/dsh-web-ui-all"
}

Write-Host "验证通过：Windows x64 DSH WebUI 与 dsh-web-ui-all 已完整加载。"
