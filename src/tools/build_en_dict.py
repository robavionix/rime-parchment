#!/usr/bin/env python3
"""
构建英文词库 en_merged.dict.yaml

策略：
  1. 保留上游 en / en_ext 的全部词条（含其人工筛选成果：注释掉的噪音、修正的大小写）
  2. 用 OpenSubtitles 5 万词频表为所有词条赋予统一权重（解决排序问题）
  3. 补入词频表中上游没有、且通过词典校验的新词
  4. 并入人工整理的场景词（教育/证件/居住/财务/医疗/职场）与高频词组

权重：round(log10(freq+1) * 100)，范围约 100~750；无词频数据的词给 fallback。
统一赋权是必须的——若只给新词权重而上游词条无权重，新词会盖过 the/and 这类核心词。
"""
import math, re, sys, pathlib

sys.stdout.reconfigure(encoding='utf-8')

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRATCH = pathlib.Path(sys.argv[1])          # 素材目录
UPSTREAM = pathlib.Path(sys.argv[2])         # 上游 rime-ice 目录
OUT = ROOT / 'src' / 'en_dicts' / 'en_merged.dict.yaml'

FALLBACK_WEIGHT = 30      # 上游有、词频表无 → 保守权重
CURATED_WEIGHT  = 420     # 场景词基准权重（约等于 log10(freq)≈4.2，即中高频）
MIN_LEN         = 3

# ---------- 读词频表 ----------
freq = {}
for line in (SCRATCH / 'en50k.txt').read_text(encoding='utf-8').splitlines():
    parts = line.split()
    if len(parts) == 2 and parts[1].isdigit():
        freq[parts[0].lower()] = int(parts[1])

# ---------- 读词典校验表 ----------
valid = set(w.strip().lower() for w in
            (SCRATCH / 'words_alpha.txt').read_text(encoding='utf-8').splitlines() if w.strip())

def weight(word):
    f = freq.get(word.lower())
    return round(math.log10(f + 1) * 100) if f else FALLBACK_WEIGHT

# ---------- 解析上游词库 ----------
def parse_dict(path):
    """返回 [(text, code)]，跳过注释、空行与 YAML 头"""
    out, in_body = [], False
    for line in path.read_text(encoding='utf-8').splitlines():
        if not in_body:
            if line.startswith('...'):
                in_body = True
            continue
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        cols = line.split('\t')
        text = cols[0].strip()
        code = cols[1].strip() if len(cols) > 1 and cols[1].strip() else text
        if text:
            out.append((text, code))
    return out

upstream = []
for name in ('en_ext', 'en'):
    p = UPSTREAM / 'en_dicts' / f'{name}.dict.yaml'
    got = parse_dict(p)
    upstream += got
    print(f'  上游 {name:8s}: {len(got):6d} 条')

seen_text = set(t for t, _ in upstream)
seen_lower = set(t.lower() for t in seen_text)

entries = [(t, c, weight(t)) for t, c in upstream]

# ---------- 补入词频表新词 ----------
added = 0
for word, f in sorted(freq.items(), key=lambda kv: -kv[1]):
    if len(word) < MIN_LEN:            continue
    if not word.isalpha():             continue
    if word in seen_lower:             continue
    if word not in valid:              continue   # 过滤字幕表拼写噪音
    entries.append((word, word, weight(word)))
    seen_lower.add(word)
    added += 1
print(f'  词频表补入      : {added:6d} 条')

# ---------- 并入场景词 ----------
curated = 0
for line in (ROOT / 'src' / 'tools' / 'curated_terms.txt').read_text(encoding='utf-8').splitlines():
    line = line.rstrip()
    if not line.strip() or line.lstrip().startswith('#'):
        continue
    cols = line.split('\t')
    text = cols[0].strip()
    code = cols[1].strip() if len(cols) > 1 else text
    if not text:
        continue
    # 场景词权重取 max(基准, 实际词频)，保证不被通用词淹没
    w = max(CURATED_WEIGHT, weight(text))
    key = text.lower()
    if key in seen_lower and ' ' not in text:
        # 已存在 → 提权而非重复收录
        for i, (t, c, _) in enumerate(entries):
            if t.lower() == key:
                entries[i] = (t, c, w)
                break
    else:
        entries.append((text, code, w))
        seen_lower.add(key)
    curated += 1
print(f'  场景词并入      : {curated:6d} 条')

# ---------- 生成错拼变体 ----------
# Rime 没有内置英文拼写检查，speller/algebra 的 derive 规则也只能处理
# 固定模式（双写辅音、ie/ei 等），无法覆盖「漏字母」「相邻字母顺序颠倒」
# 这类位置不定的错法——正则替换表达不了。
#
# 因此在词库层面处理：给正确单词额外挂上错拼编码，权重压低。
#   interesting  interesting  550   ← 正确拼写，高权重
#   interesting  intersting    8    ← 漏字母变体，低权重
#
# 两条硬性约束：
#   ① 变体若本身是真英文单词，必须丢弃。否则打 hat 会跳出 heat/that 一堆东西。
#   ② 只对高频词生成。全量生成会让 prism 体积失控，而低频词打错的概率本就低。

TYPO_TOP_N   = 12000   # 漏字母 / 换位：词频前 N 的词
TYPO_VOWEL_N = 6000    # 元音替换：范围更窄（这类是「不知道怎么拼」的错，
                       # 多发生在常用词上），且组合数更多，故收紧
TYPO_MIN_LEN = 5       # 太短的词，其变体极易与真词冲突，且省不了几个键
TYPO_WEIGHT  = 8       # 远低于正常词条（中位数 279），保证正确拼写始终在前

# 白名单：既不在词典校验表、也不在词频表，但确属正当词汇的
# 技术名词 / 品牌名 / 缩写。不加保护会被错拼清除逻辑误删。
TYPO_PROTECT = {
    'arial', 'cron', 'perl', 'nginx', 'redis', 'kubectl', 'systemd',
    'sudo', 'grep', 'regex', 'kanban', 'agile', 'devops',
    'logon', 'logoff', 'suse', 'ubuntu', 'fedora',
}

# 按权重取前 N 个词作为生成源
source = [(t, c, w) for t, c, w in entries
          if ' ' not in t and t.isalpha() and len(t) >= TYPO_MIN_LEN]
source.sort(key=lambda e: -e[2])
source = source[:TYPO_TOP_N]
# 元音替换的权重下限：取前 TYPO_VOWEL_N 个词的最低权重
vowel_threshold = source[min(TYPO_VOWEL_N, len(source)) - 1][2] if source else 0

# 一个变体可能对应多个正确词，只保留词频最高的那个，避免候选噪音
# 注意顺序：先收集**全部**候选变体（不做任何过滤），因为下一步要用它来
# 识别上游自带的错拼词条。若在此处就按 existing_codes 过滤，那些已被上游
# 收录的错拼会被跳过，反而检测不出来。
raw_variants = {}
for text, code, w in source:
    low = code.lower()
    cands = set()
    # 漏字母：逐位删除
    for i in range(len(low)):
        cands.add(low[:i] + low[i + 1:])
    # 相邻字母顺序颠倒：teh → the
    for i in range(len(low) - 1):
        cands.add(low[:i] + low[i + 1] + low[i] + low[i + 2:])
    # 元音互换：seperate → separate、definately → definitely、independant → independent
    # 非母语者最常犯的错型。只在更窄的高频范围内生成。
    if w >= vowel_threshold:
        for i, ch in enumerate(low):
            if ch in 'aeiou':
                for v in 'aeiou':
                    if v != ch:
                        cands.add(low[:i] + v + low[i + 1:])
    for v in cands:
        if len(v) < 3 or v == low:
            continue
        prev = raw_variants.get(v)
        if prev is None or w > prev[1]:
            raw_variants[v] = (text, w)

# ── 清除上游自带的错拼词条 ──
# 上游 rime-ice 的 en.dict.yaml 把一些常见错拼当成正规词条收录了
# （实例：en.dict.yaml:5393 的 definately）。这类条目会让纠错失效——
# 打 definately 出来的就是错的那个，而不是 definitely。
#
# 判定三条同时成立才算错拼：
#   ① 不在 37 万词典校验表中
#   ② 恰好是某高频词的错拼变体
#   ③ **词形全小写**
#
# 第 ③ 条是关键。上游对专有名词一律大写开头（Alexandre / Alta / Alton / Ames），
# 而错拼是全小写（amatuer / definately）。没有这条会把大批人名地名误删——
# 它们同样不在校验表中，且确实可能撞上某个常用词的变体。
before = len(entries)
#   ④ **在词频表中也查不到**
#
# 第 ④ 条保护那些不在词典校验表、但人们确实在说的词（如 carbs 词频 690）。
# 真正的错拼不会出现在清洗过的词频表里。
bad = [t for t, c, w in entries
       if ' ' not in t
       and t.islower()
       and t.lower() not in TYPO_PROTECT
       and t.lower() in raw_variants
       and t.lower() not in valid
       and t.lower() not in freq]
badset = set(b.lower() for b in bad)
entries = [(t, c, w) for t, c, w in entries if t.lower() not in badset]
print(f'  清除上游错拼    : {before - len(entries):6d} 条')
for b in sorted(badset):
    print(f'      - {b:16s} → {raw_variants[b][0]}')

# ── 落地变体（此时才按「是否真单词」「是否已被占用」过滤）──
existing_codes = set(c.lower() for _, c, _ in entries)
added_variants = 0
for v, (text, _) in raw_variants.items():
    if v in valid:            continue   # 变体本身是真单词 → 丢弃，否则打 hat 会跳出 heat/that
    if v in existing_codes:   continue   # 已被正常词条占用 → 丢弃
    entries.append((text, v, TYPO_WEIGHT))
    added_variants += 1
print(f'  错拼变体生成    : {added_variants:6d} 条 (源词 {len(source)}, 阈值 len>={TYPO_MIN_LEN})')

# ---------- 输出 ----------
entries.sort(key=lambda e: (-e[2], e[0].lower()))
OUT.parent.mkdir(parents=True, exist_ok=True)
with OUT.open('w', encoding='utf-8', newline='\n') as f:
    f.write('''# Rime dictionary
# encoding: utf-8
#
# 英文合并词库 —— 面向有中英文混打需求的用户
#
# 由 src/tools/build_en_dict.py 生成，请勿手工编辑。
# 要增删场景词，改 src/tools/curated_terms.txt 后重新运行构建。
#
# 构成：
#   1. 上游 rime-ice en.dict.yaml + en_ext.dict.yaml 的全部词条
#   2. OpenSubtitles 5 万词频表补充的新词（经 370k 词典校验，滤除拼写噪音）
#   3. 人工整理的场景词：教育 / 证件 / 居住 / 财务 / 医疗 / 交通 / 职场 / 缩写 / 高频词组
#
# 权重统一为 round(log10(词频+1) * 100)，使候选排序反映真实使用频率。
#
---
name: en_merged
version: "1.0.0"
...
''')
    for text, code, w in entries:
        f.write(f'{text}\t{code}\t{w}\n')

print(f'\n  输出 {OUT.relative_to(ROOT)}')
print(f'  总词条 {len(entries)} 条, {OUT.stat().st_size/1024:.0f} KB')
