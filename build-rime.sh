#!/usr/bin/env bash
# 组装 Rime 配置：干净上游雾凇 + 本项目补丁 - 无用文件
#
# 用法:
#   ./build-rime.sh            iOS 元书版  → dist/rime
#   ./build-rime.sh android    安卓版      → dist/rime-android
#
# 5.0 起不再有独立的 t9 方案：九宫格与 26 键共用 rime_ice
# （见 src/patches/rime_ice.custom.yaml 末尾）。
#
# 安卓版会剥离 rime_ice.custom.yaml 里 T9-ONLY 标记之间的内容：那几段依赖
# `t9_processor`，是仓/元书编译进 App 的原生组件，不属于 librime，安卓端
# 加载会失败。剥离后安卓拿到的是一份纯 26 键配置。
set -euo pipefail
cd "$(dirname "$0")"

TARGET="${1:-ios}"
if [ "$TARGET" = "android" ]; then
  OUT=dist/rime-android
else
  OUT=dist/rime
fi
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
cp src/rime_ice.dict.yaml          "$OUT/"           # 覆盖：挂载个人中文词库
cp src/en_dicts/en_merged.dict.yaml "$OUT/en_dicts/" # 新增：合并英文词库
cp src/cn_dicts/personal.dict.yaml "$OUT/cn_dicts/"  # 新增：个人中文词库
cp src/patches/melt_eng.custom.yaml "$OUT/"
cp src/patches/default.custom.yaml  "$OUT/"

# t9 方案已废弃（5.0），其文件不再随包分发
rm -f "$OUT/t9.schema.yaml" "$OUT/lua/t9_preedit.lua"

if [ "$TARGET" = "android" ]; then
  # 剥离 T9-ONLY 段：t9_processor 等元书原生能力，librime 没有
  sed '/T9-ONLY BEGIN/,/T9-ONLY END/d'       src/patches/rime_ice.custom.yaml > "$OUT/rime_ice.custom.yaml"
else
  cp src/patches/rime_ice.custom.yaml "$OUT/"
fi

echo "[4/4] 统计"
printf '  产物目录 %s\n' "$OUT"
printf '  总体积   %s\n' "$(du -sh "$OUT" | cut -f1)"
printf '  文件数   %s\n' "$(find "$OUT" -type f | wc -l)"
echo
echo "  精简对比："
printf '    上游 %s / %s 文件\n' "$(du -sh vendor/rime-ice | cut -f1)" "$(find vendor/rime-ice -type f | wc -l)"
printf '    产物 %s / %s 文件\n' "$(du -sh "$OUT" | cut -f1)" "$(find "$OUT" -type f | wc -l)"
