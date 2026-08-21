#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DSH_HOME="${DSH_HOME:-$ROOT/dsh-home}"
export PATH="$ROOT/bin:$PATH"
CLI="$ROOT/runtime/node_modules/@deepseek-ai/dsh/lib/bin.js"

"$ROOT/bin/node" --version
"$ROOT/bin/node" "$CLI" --version

PROFILE="$DSH_HOME/profiles/web/package.json"
[[ -f "$PROFILE" ]] || { echo "缺少 profile: $PROFILE" >&2; exit 1; }
grep -q '"@linxin666/dsh-web-ui-all"' "$PROFILE"

DUMP="$(mktemp)"
trap 'rm -f "$DUMP"' EXIT
"$ROOT/bin/node" "$CLI" --profile web --dump-config > "$DUMP"
for id in web-ui-task-board web-ui-git-graph web-ui-plugin-manager web-ui-better-sidebar; do
  grep -q "$id" "$DUMP" || { echo "缺少插件配置: $id" >&2; exit 1; }
done

echo "验证通过：DSH WebUI 与 dsh-web-ui-all 已完整加载。"
