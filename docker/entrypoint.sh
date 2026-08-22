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
echo "DSH internal: http://127.0.0.1:3081"
echo "Web UI via Nginx: http://0.0.0.0:3080"
echo "API Key 不在镜像中，请在 WebUI 设置 → 模型中配置。"

node "$CLI" web --host 127.0.0.1 --port 3081 --no-open "$@" &
DSH_PID=$!

cleanup() {
  kill "$DSH_PID" 2>/dev/null || true
  wait "$DSH_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Nginx 对外监听 3080，并把请求与 WebSocket 转发给仅监听本地的 DSH。
nginx -c /etc/nginx/nginx.conf -g 'daemon off;' &
NGINX_PID=$!

set +e
wait -n "$DSH_PID" "$NGINX_PID"
rc=$?
set -e
kill "$DSH_PID" "$NGINX_PID" 2>/dev/null || true
wait "$DSH_PID" "$NGINX_PID" 2>/dev/null || true
exit "$rc"
