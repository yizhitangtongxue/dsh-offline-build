#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DSH_HOME="${DSH_HOME:-$ROOT/dsh-home}"
export PATH="$ROOT/bin:$PATH"

HOST="${DSH_HOST:-127.0.0.1}"
PORT="${DSH_PORT:-3080}"
WORKSPACE="${DSH_WORKSPACE:-$PWD}"

if [[ ! -x "$ROOT/bin/node" ]]; then
  echo "错误：离线包缺少 bin/node" >&2
  exit 1
fi
if [[ ! -f "$ROOT/runtime/node_modules/@deepseek-ai/dsh/lib/bin.js" ]]; then
  echo "错误：离线包缺少 DeepSeek Harness CLI" >&2
  exit 1
fi

cd "$WORKSPACE"
echo "DSH_HOME: $DSH_HOME"
echo "Workspace: $WORKSPACE"
echo "Web UI: http://$HOST:$PORT"
echo "提示：API Key 请在 Web UI 的 设置 → 模型 中输入；本包不包含任何 Key。"

exec "$ROOT/bin/node" \
  "$ROOT/runtime/node_modules/@deepseek-ai/dsh/lib/bin.js" \
  web --host "$HOST" --port "$PORT" --no-open "$@"
