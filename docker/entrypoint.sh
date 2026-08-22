#!/usr/bin/env bash
set -euo pipefail

SEED_MARKER="/data/.dsh-seeded-${DSH_IMAGE_VERSION:-current}"
mkdir -p /data /workspace

if [[ ! -f "$SEED_MARKER" ]]; then
  echo "初始化 DSH profile 到 /data（保留已有配置）……"
  cp -a -n /opt/dsh-seed/. /data/
  touch "$SEED_MARKER"
fi

export DSH_HOME=/data
cd "${DSH_WORKSPACE:-/workspace}"

CLI=/opt/dsh/runtime/node_modules/@deepseek-ai/dsh/lib/bin.js

echo "Workspace: $(pwd)"
echo "DSH_HOME: $DSH_HOME"
echo "Web UI: http://${DSH_HOST:-0.0.0.0}:${DSH_PORT:-3080}"
echo "API Key 不在镜像中，请在 WebUI 设置 → 模型中配置。"

exec node "$CLI" web \
  --host "${DSH_HOST:-0.0.0.0}" \
  --port "${DSH_PORT:-3080}" \
  --no-open "$@"
