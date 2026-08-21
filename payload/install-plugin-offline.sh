#!/usr/bin/env bash
# 从本地 .tgz 或本地插件目录离线安装 DSH bundle。
# 注意：插件的所有依赖必须已经打进 tgz、当前 pnpm 离线存储中，或在 GitHub 构建阶段预装。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DSH_HOME="${DSH_HOME:-$ROOT/dsh-home}"
export PATH="$ROOT/bin:$PATH"
CLI="$ROOT/runtime/node_modules/@deepseek-ai/dsh/lib/bin.js"

if [[ $# -lt 1 ]]; then
  echo "用法: $0 /绝对路径/plugin.tgz [更多本地插件.tgz...]" >&2
  echo "建议：依赖复杂的插件在 GitHub Actions 的 extra_plugins 输入中预装。" >&2
  exit 2
fi

for plugin in "$@"; do
  if [[ ! -e "$plugin" ]]; then
    echo "错误：只接受本地文件或目录，找不到：$plugin" >&2
    exit 2
  fi
  plugin="$(realpath "$plugin")"
  echo "离线安装：$plugin"
  set +e
  "$ROOT/bin/node" "$CLI" plugin --profile web add --offline "$plugin"
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    echo "首次安装未完成，批准本地插件所需的原生构建后重试……"
    "$ROOT/bin/node" "$CLI" plugin --profile web approve-builds --all
    "$ROOT/bin/node" "$CLI" plugin --profile web add --offline "$plugin"
  fi
done

echo "安装完成。请重启 start.sh 使新增 bundle 生效。"
