#!/usr/bin/env bash
# 组装 Rime 配置：干净上游雾凇 + 本项目补丁 - 无用文件
# 用法: ./build-rime.sh
set -euo pipefail
cd "$(dirname "$0")"

OUT=dist/rime
rm -rf "$OUT"
mkdir -p "$OUT"

echo "[1/4] 复制上游雾凇基底"
cp -r vendor/rime-ice/. "$OUT/"

echo "[2/4] 精简无用文件"
# ── 其它平台的界面配置（本项目只面向 iOS 元书）──
rm -f  "$OUT/squirrel.yaml"          # macOS 鼠须管
rm -f  "$OUT/weasel.yaml"            # Windows 小狼毫
# ── 双拼方案（本项目用全拼）──
rm -f  "$OUT"/double_pinyin*.schema.yaml
rm -f  "$OUT"/en_dicts/cn_en_abc.txt \
       "$OUT"/en_dicts/cn_en_double_pinyin.txt \
       "$OUT"/en_dicts/cn_en_flypy.txt \
       "$OUT"/en_dicts/cn_en_jiajia.txt \
       "$OUT"/en_dicts/cn_en_mspy.txt \
       "$OUT"/en_dicts/cn_en_sogou.txt \
       "$OUT"/en_dicts/cn_en_ziguang.txt
# ── 部件拆字（反查 + 辅码）：源 2.1M，编译产物约 5.8M，用户确认不需要 ──
rm -f  "$OUT/radical_pinyin.dict.yaml" "$OUT/radical_pinyin.schema.yaml"
rm -f  "$OUT/lua/search.lua"
# ── 已合并进 en_merged 的英文分表 ──
rm -f  "$OUT/en_dicts/en.dict.yaml" "$OUT/en_dicts/en_ext.dict.yaml"
# ── 文档与素材（1.3 MB 截图，输入法运行不需要）──
rm -rf "$OUT/others"
rm -f  "$OUT/README.md" "$OUT/AGENTS.md" "$OUT/recipe.yaml"
# LICENSE 保留：雾凇为 GPLv3，署名与许可须随分发保留

echo "[3/4] 覆盖 / 追加本项目文件"
cp src/melt_eng.dict.yaml          "$OUT/"           # 覆盖：改挂 en_merged
cp src/en_dicts/en_merged.dict.yaml "$OUT/en_dicts/" # 新增：合并英文词库
cp src/patches/*.custom.yaml       "$OUT/"           # 补丁：不动上游原文件

echo "[4/4] 统计"
printf '  产物目录 %s\n' "$OUT"
printf '  总体积   %s\n' "$(du -sh "$OUT" | cut -f1)"
printf '  文件数   %s\n' "$(find "$OUT" -type f | wc -l)"
echo
echo "  精简对比："
printf '    上游 %s / %s 文件\n' "$(du -sh vendor/rime-ice | cut -f1)" "$(find vendor/rime-ice -type f | wc -l)"
printf '    产物 %s / %s 文件\n' "$(du -sh "$OUT" | cut -f1)" "$(find "$OUT" -type f | wc -l)"
