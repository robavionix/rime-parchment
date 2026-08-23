#!/usr/bin/env bash
# 拉取上游雾凇拼音作为构建基底
#
# vendor/ 不计入版本控制——它是上游仓库的完整拷贝（50 MB），
# 不该塞进本仓库。构建前跑一次本脚本即可。
set -euo pipefail
cd "$(dirname "$0")"

UPSTREAM=https://codeload.github.com/iDvel/rime-ice/tar.gz/refs/heads/main

if [ -d vendor/rime-ice ]; then
  echo "vendor/rime-ice 已存在。如需重新拉取，先删除该目录。"
  exit 0
fi

echo "拉取上游 rime-ice ..."
mkdir -p vendor
curl -sL --max-time 300 -o /tmp/rime-ice.tar.gz "$UPSTREAM"
tar -xzf /tmp/rime-ice.tar.gz -C /tmp
rm -rf vendor/rime-ice
mv /tmp/rime-ice-main vendor/rime-ice
rm -f /tmp/rime-ice.tar.gz /tmp/rime-ice.tar.gz.*
rm -rf vendor/rime-ice/.git*

echo "完成：vendor/rime-ice ($(du -sh vendor/rime-ice | cut -f1))"
