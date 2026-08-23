#!/usr/bin/env bash
# 编译皮肤：jsonnet -> YAML
# 用法: ./build.sh [release]    默认 debug（YAML 可读），release 生成紧凑格式
set -euo pipefail
cd "$(dirname "$0")"

DEBUG=true
[ "${1:-}" = "release" ] && DEBUG=false

# jsonnet -m 不会自动创建子目录，必须预先建好
mkdir -p skin/light skin/dark

./tools/jsonnet.exe -S -m skin \
  --tla-code debug=$DEBUG \
  skin/jsonnet/main.jsonnet

echo "✅ 编译完成 (debug=$DEBUG)"
ls skin/light/ | sed 's/^/   /'
