# 项目笔记（持续更新）

## 目标
为 **元书输入法**（Hamster 3, iOS/App Store, 作者 ihsiao）做一套 Rime 方案 + 键盘皮肤。
目标人群：在英语国家学习/生活的中国人。

## 需求（用户逐条给出，随时补充）
1. 两套键盘并存：
   - **九宫格**：只要中文输入
   - **全键盘**：中英混合双打，调用大量词库
2. 皮肤要「极其舒适」，与上述两套键盘配套

## 已确认的事实

### 平台
- 应用为「元书输入法」，非「元词」。distribution_code_name = `hamster3`，Rime 1.17.0
- 文档站：https://ihsiao.com/apps/hamster/v3/docs/guides/intro/

### Rime 方案与皮肤是两套独立体系
| | Rime 方案 | 元书皮肤 |
|---|---|---|
| 管 | 打什么字出来 | 键盘长什么样、按键行为 |
| 格式 | .schema.yaml / .dict.yaml / Lua | config.yaml + light/ + dark/（纯 YAML） |

### 皮肤包结构（硬性要求）
- `demo.png`（必须）、`config.yaml`（必须）、`light/`（必须）、`dark/`（必须）
- 可选：`README.md`、`fonts/`、`resources/`
- 键盘类型：pinyin（必须提供）、alphabetic、numeric、symbolic、panel、自定义
- 布局：HStack/VStack 嵌套 + Cell；尺寸用分数 `{ width: 1/3 }`
- 同级不可混用 HStack/VStack/Cell

### 按键可挂的动作
`action`、`swipeUpAction`、`swipeDownAction`、`repeatAction`（长按重复）、
`preeditStateAction`（预编辑状态独立动作）、`uppercasedStateAction`、
`hintSymbolsStyle`（长按符号网格）、`animation`、`notification`

### Jsonnet
- 元书内置 Jsonnet 编译器；手机端「长按皮肤 → 运行 main.jsonnet」
- PC 端：`jsonnet -S -m . --tla-code debug=true ./jsonnet/main.jsonnet`
- **本机尚未安装 jsonnet CLI**
- 编译产物单文件 80KB+，手写 YAML 不可行 → 必须用 Jsonnet 写

## 参考实现

### reference/rime-ice/
用户原配置，近乎零定制的雾凇原版（2026-08-20）。
- 唯一改动：`default.custom.yaml`，方案选择器生成，schema_list = [t9, rime_ice]
- 无 `rime_ice.custom.yaml`
- 全量词库，`rime_ice.table.bin` = 60MB
- **坏文件**：`t9_schema.yaml`（应为 `t9.schema.yaml`），内含前后鼻音模糊音但永不加载

雾凇中英混输三层机制：
- `melt_eng`：次翻译器挂 en.dict.yaml，`enable_sentence: false`
- `cn_en`：stabledb 挂 en_dicts/cn_en.txt，中英混合词
- filters：`autocap_filter`、`reduce_english_filter`（压低英文）、`cn_en_spacer`

针对本项目人群的四个硬伤：
1. `reduce_english_filter` 方向反了，专门压低英文候选
2. `corrector.lua` 把英文纠成中文（Amazon → 阿妈粽）
3. 英文词库缺留学/生活/职场场景词
4. `enable_sentence: false`，英文不能连打成句

### reference/空山素影/
成熟的 Jsonnet 皮肤，GitHub: luozikuan/kongshan-suying（**待确认 license**）
配套方案：luozikuan/rime-tailor

已具备：
- Layout 9/14/17/18/26/26b/bopomofo/sigma
- 上下滑动输入全部 PC 符号；a,z,x,c,v 下滑 = 全选/撤销/剪切/复制/粘贴
- 空格键显示当前方案名
- **中文模式字母键大写显示、英文模式小写显示**（中英状态一目了然）
- shift 打字中充当分词键
- 主题色 6 选 1；浮动面板「微调」直接编辑 Settings.libsonnet

**关键机制 `temp26Key`**：当 `keyboardLayout != '26'` 时，main.jsonnet 会额外
生成一个 temp26Key 自定义键盘，供 9 键布局临时跳到 26 键（如用雾凇 V 模式）。
按键可用 `keyboardType: 'temp26Key'` 动作跳转。
→ 这正是「九宫格 + 全键盘并存」的现成机制，需从「临时」提升为「一等公民」。

**局限**：`Settings.keyboardLayout` 是单选，原设计是 9 或 26 二选一，
不是双键盘并存。这是需要改造的核心点。

## 项目结构
```
Rime_conf/
├─ reference/          只读参考（rime-ice、空山素影）
├─ src/                Rime 方案源码
│   ├─ dicts/
│   └─ lua/
├─ skin/
│   ├─ src/            皮肤 Jsonnet 源码
│   └─ dist/           编译产物
├─ dist/               Rime 方案产物
└─ docs/               本文档
```

## 待定
- 英文路线：A 沿用 table_translator + 扩充词库 / B 独立英文 schema + lua（倾向先 A）
- 九宫格边界：数字/标点/误触发英文如何处理
- 皮肤视觉风格方向
- 目标机型（决定尺寸与是否做 iPad 布局）

---

## 已诊断问题：9键中文 + 全键盘中英混打无法并存

**现象**（用户报告）：设成 9 键后，全键盘只能打英文。
**结论：根因在皮肤，不在用户的 Rime 配置。**

`Pinyin26.libsonnet` 用同一布局生成三种 KeyboardType（第 15-19 行）：

| 类型 | 空格键显示 | 切换键 | 打中文 |
|---|---|---|---|
| Chinese (0) | `$rimeSchemaName` | alphabeticButton | ✅ 真正的中英混打 26 键 |
| English (1) | `English` | pinyinButton | ❌ |
| Temp26Key (2) | 写死「临时中文」 | goBackButton | ✅ 但为临时逃生舱 |

组件选择逻辑：
- `Components/Pinyin.libsonnet`：keyboardLayout=='9' → layout9，pinyin 键盘 = 9键
- `Components/Alphabetic.libsonnet`：**硬编码 KeyboardType.English**，只有一行

→ keyboardLayout='9' 时，KeyboardType.Chinese 的 26 键**根本不会被生成**。
用户按到的"全键盘"是 alphabetic（English 类型）。
temp26Key 虽生成且能走 Rime，但切换键是「返回」、空格写死「临时中文」，
作者原意是"17键布局下临时用雾凇 V 模式"，非主力键盘。

**根因**：`Settings.keyboardLayout` 是单选设计，9 键与 26 键二选一，未考虑并存。

### 修复方案
1. `main.jsonnet` 的 `nameToComponent` 新增自定义键盘（如 `pinyin26`），
   无条件生成 KeyboardType.Chinese 版本
2. 9 键与 26 键各加互跳按键：`keyboardType: 'pinyin26'` / `keyboardType: 'pinyin'`
3. **切键盘时同时切 Rime 方案**：九宫格 → `t9`，26 键 → `rime_ice`
   （皮肤侧与 Rime 侧的接缝，两边都要动）

第 3 步是需求的关键：两套键盘挂两套方案，词库/模糊音/英文策略完全独立。
九宫格彻底关英文，26 键把英文火力开满。

---

## 工具链（已就绪）

- `tools/` 内置便携版 **go-jsonnet v0.22.0**（jsonnet / jsonnetfmt / jsonnet-lint），
  免管理员、不污染系统 PATH。本机仅有 winget，无 scoop/choco/go。
- `build.sh` —— 编译脚本。`./build.sh` 为 debug（YAML 可读），
  `./build.sh release` 为紧凑格式。
- **坑**：`jsonnet -m` 不会自动创建子目录，必须预先 `mkdir -p skin/light skin/dark`，
  否则报 `openat dark\xxx.yaml: The system cannot find the path specified.`
- 全量重编耗时 **约 1.6 秒**。

## 授权

`luozikuan/kongshan-suying` **无 LICENSE 文件**（技术上属保留所有权利）。
个人使用无问题——该皮肤本身即设计给用户改（README 专章讲改 Settings.libsonnet，
App 内置编辑器）。**若将来要公开发布本皮肤，需先联系原作者。**

## 诊断实测确认

`keyboardLayout: '9'` 编译产物：

| 键盘 | 空格键显示 | 说明 |
|---|---|---|
| pinyin | `$rimeSchemaName` | 九宫格中文 |
| alphabetic | `English` | 26键纯英文 ← 用户按到的"全键盘" |
| temp26Key | `临时中文` | 26键中文，被写死的逃生舱 |

KeyboardType.Chinese 的 26 键确实完全未生成。诊断成立。

## 已决策

1. **PC 端本地编译**（已装 go-jsonnet）
2. **九宫格 ↔ 全键盘用专用切换键**（方案 A），并联动切 Rime 方案

## 九宫格键位现状（Pinyin9.libsonnet）

```
┌────┬─────────────────────┬──────────┐
│符号 │  1     2     3      │ backspace│
│    │  4     5     6      │  清空    │
│数字 │  7     8     9      │  回车    │
│    │ ←→   空格  [中/En]  │          │
└────┴─────────────────────┴──────────┘
```
右下角为 `commonButtons.alphabeticButton`（Pinyin9.libsonnet:84），
即当前把用户送进纯英文键盘的按键。

**→ 无需新增键位**：把它改指向新建的中英混打 26 键即可。

目标流转：
```
九宫格中文 ──[右下键]──► 26键中英混打 ──[中/En]──► 26键纯英文
    ▲                        │                      │
    └─────[切换键]───────────┘◄──────[中/En]────────┘
```

## 工作区

- `skin/` —— 皮肤工作副本（fork 自空山素影，40 个 jsonnet 模块）
- `skin/jsonnet/` 源码，`skin/light/`、`skin/dark/` 为编译产物
- `build.sh` 编译已跑通

---

## 已实现：双键盘并存（第一版）

### 元书按键动作词汇（官方文档确认）
| 动作 | 语法 |
|---|---|
| 切指定 Rime 方案 | `{ switchRimeSchema: '方案ID' }` |
| 切键盘（含自定义） | `{ keyboardType: 'pinyin26' }` |
| 组合动作 | `{ combine: [...] }` ⚠️ 实验功能，需 TF ≥ 349 |
| 字符（走 Rime） | `{ character: 'a' }` |
| 符号（直发系统） | `{ symbol: '!' }` |
| 组合键 | `{ sendKeys: 'Shift+a' }` |
| 快捷指令 | `{ shortcut: '#方案切换' }` |

皮肤内已用到的 shortcut：`#方案切换` `#RimeSwitcher` `#中英切换` `#换行` `#行首` `#行尾`
`#次选上屏` `#重输` `#左手模式` `#右手模式` `#copy` `#cut` `#paste` `#undo` `#redo`
`#selectText` `#showPasteboardView` `#showPhraseView` `#keyboardPerformance`
`#candidatesBarStateToggle` `#toggleEmbeddedInputMode` `#toggleScriptView`
`#subCollectionPageUp/Down` `#verticalCandidatesPageUp/Down`

### 重要修正：九宫格无法与 26 键共用方案
- t9 有 `t9_processor`（元书原生处理器）+ speller 数字映射
  （`derive/[abc]/2/` 等），九宫格按键发数字字符，只有 t9 能解析。
- **但** `t9.schema.yaml` 第 9 行 `__include: rime_ice.schema.yaml:/`，
  其 translator 块只覆盖 `prism`/`spelling_hints`/`comment_format`，
  **未覆盖 `dictionary:`** → 两方案共用 `dictionary: rime_ice`，
  **共用 `rime_ice.userdb`，自造词与调频互通**。
- 结论：联动切方案零代价，严格优于共用单方案。
- 附带发现：t9 中 `# - table_translator@melt_eng` **本就注释掉**，
  九宫格开箱即纯中文，无需额外关闭。t9 用 `custom_phrase_t9.txt`（数字编码）。

### 改动清单（5 处）
1. `Settings.libsonnet` — `keyboardLayout: '26'` → `'9'`；
   新增 `dualKeyboard: true`、`schemaFor9: 't9'`、`schemaFor26: 'rime_ice'`
2. `Buttons/Common.libsonnet` — 新增 `gotoPinyin26Button`（文字「全键」）；
   `alphabeticButton.swipeDown` 在 dualKeyboard 下改为返回九宫格 + 切 t9
3. `Components/Pinyin26.libsonnet` — **新建**，无条件生成 `KeyboardType.Chinese`
4. `main.jsonnet` — 注册 `pinyin26` 键盘
5. `Components/Pinyin/Pinyin9.libsonnet` — 右下角 Cell 与样式块
   由 `alphabeticButton` 换为 `gotoPinyin26Button`

### 编译验证结果
- `config.yaml` 声明：alphabetic / numeric / panel / pinyin / **pinyin26** / temp26Key
- 空格键文本：pinyin → `$rimeSchemaName`，pinyin26 → `$rimeSchemaName`，
  alphabetic → `English`
- 九宫格右下角：`combine[switchRimeSchema: rime_ice, keyboardType: pinyin26]`，文字「全键」
- 26键 中/En 下滑：`combine[switchRimeSchema: t9, keyboardType: pinyin]`

### 产物
`dist/空山素影-双键盘.zip`

### 遗留
- ⚠️ `combine` 为实验功能，**需在真机验证**。若不支持，退路是拆成两步
  （先切键盘，再用 中/En 上滑的 `#方案切换`）。
- `temp26Key` 现已成为无入口的死代码（原入口 alphabeticButton.swipeDown 已被占用），
  可在确认双键盘可用后移除。

---

## 平台结论（已确认）

- 用户手机为 **元书输入法**（「元词」为口误）。**不做仓输入法兼容。**
- 安卓端：`src/` 方案层可直接搬到 **同文输入法 (Trime)**（`/rime`）或
  **fcitx5-android + Rime 插件**（`/Android/data/org.fcitx.fcitx5.android/files/data/rime/`）。
  **皮肤完全不通用**——元书皮肤格式为其专有，且我们依赖的
  `combine` / `switchRimeSchema` / 自定义键盘均为元书特性。
- ⚠️ `others/Hamster/melt_eng.custom.yaml`（官方九宫格英文补丁）**不可用**：
  官方明确警告「会导致全键盘方案无法输入英文」，与本项目需求直接冲突。

## Rime 侧已完成

### 工程结构
```
vendor/rime-ice/     固化的干净上游（50M/162 文件），构建可复现、不依赖网络
src/
  melt_eng.dict.yaml           覆盖上游：改挂 en_merged
  en_dicts/en_merged.dict.yaml 生成物，43,005 条
  patches/
    default.custom.yaml        schema_list = [rime_ice, t9]
    rime_ice.custom.yaml       硬伤 1/2/4
    melt_eng.custom.yaml       精简派生规则
  tools/
    curated_terms.txt          人工场景词，424 条
    build_en_dict.py           词库构建脚本
build-rime.sh                  组装：上游 + 补丁 - 精简 → dist/rime
```

### 四个硬伤的处理
1. **reduce_english_filter 方向反了** → `reduce_english_filter/mode: none`
   （上游有 `all|custom|none` 开关，无需动 filter 链）
2. **corrector 把英文纠成中文** → corrector 无开关，整体重定义 `engine/filters`
   摘除 `lua_filter@*corrector`。代价：失去中文错音提示。补丁里留了注释行可一键恢复。
   同时关闭仅为 corrector 服务的 `always_show_comments` 与 `comment_format`。
3. **英文词库覆盖不足** → 见下「英文词库」
4. **英文无法连打** → **不采用 `enable_sentence: true`**。
   英文词库无词间语法模型，开启后 important→import+ant、together→to+get+her，
   垃圾候选抢位（这正是上游设 false 的原因）。改用：
   - `melt_eng/enable_completion: true`（打 inter 出 international，提速大头）
   - 高频词组作为**单条词**收入词库（thank you / looking forward to 等，一次成型）
   - 附加 `melt_eng/enable_user_dict: true`，让 Rime 学习个人英文词频

### 英文词库 en_merged（43,005 条，原 23,866，+80%）
构成：
- 上游 en (21,268) + en_ext (2,598)，保留其人工筛选成果
- OpenSubtitles en_50k 词频表补入 18,979 条，经 370k 词典（dwyl/english-words）
  校验滤除字幕噪音，长度 ≥3
- 人工场景词 424 条：留学/签证/租房/税务/医疗/交通/职场/缩写/高频词组

**关键设计：统一赋权**。权重 = `round(log10(词频+1)*100)`，范围 30~746。
必须给上游词条也赋权——否则新词（有权重）会盖过 the/and 这类无权重的核心词。
场景词权重取 `max(420, 实际词频权重)`，高于中位数 279，保证出头但不压核心词。

### prism 瘦身
上游 `algebra_common` 为每词派生 **12 种**大小写拼写，其中「前 2~10 字母大写」
九条规则收益极低却贡献主要膨胀（23,866 词 → prism 8.2 MB）。
补丁整体重定义 `speller/algebra`，压到 **3 种**，并把「全小写」从
「仅 4 字符以上」放宽到所有长度（修复 NHS/GDP 等三字母缩写无法小写输入）。

### 文件精简（162 → 57 个文件）
删除：`squirrel.yaml`(macOS) `weasel.yaml`(Windows) `double_pinyin*.schema.yaml`×7
`en_dicts/cn_en_{abc,double_pinyin,flypy,jiajia,mspy,sogou,ziguang}.txt`
`en_dicts/en.dict.yaml` `en_dicts/en_ext.dict.yaml`（已并入 en_merged）
`others/`(1.3M 文档截图) `README.md` `AGENTS.md` `recipe.yaml`
保留 `LICENSE`（雾凇 GPLv3，分发须保留署名）。

无悬空引用（`default.yaml` 的双拼 schema_list 已被 default.custom.yaml 整体覆盖）。
所有补丁 YAML 语法校验通过。

### 待决 / 遗留
- `radical_pinyin`（部件拆字反查 + 辅码）：源 2.1M，**编译产物约 5.8M**
  （prism 2.5M + table 2.3M + reverse 963K）。移除需同时改 schema 的
  dependencies / segmentor / translator / filter 四处。**待用户确认是否用得上。**
- `melt_eng.schema.yaml` 内残留 `algebra_double_pinyin*` 约 200 行死配置，无害。
- `cn_dicts/` 45M（`tencent.dict.yaml` 独占 17M）——用户要求词库later再谈。
- 产物体积 49M，仍由中文词库主导。

---

## 部件拆字已移除（用户确认）

两个功能共用 `radical_pinyin` 词库（源 2.1M，编译产物约 5.8M）：

| 功能 | 触发 | 用途 | 判定 |
|---|---|---|---|
| **部件拆字反查** | 前缀 `uU` | 用部件拼音倒查生僻字：`uUniuniuniu`→犇、`uUshuishuishui`→淼、`uUbinbei`→赟 | 用户明确不要生僻字 |
| **辅码** | 键 `` ` `` | 打字中途补部件拼音筛候选：``shi`ri`` → 只剩含「日」的 时/是/昰 | 需记部件拼音，使用率极低 |

**附带发现**：上游未提供 `radical_pinyin:` 配置命名空间块，
`lua_filter@*search@radical_pinyin` 本就处于半失效状态。

### 移除涉及的 5 处（全在 rime_ice.custom.yaml 中打补丁，未动上游）
1. `schema/dependencies` → 仅保留 `melt_eng`
2. `engine/segmentors` → 去 `affix_segmentor@radical_lookup`
3. `engine/translators` → 去 `table_translator@radical_lookup`
4. `engine/filters` → 去 `reverse_lookup_filter@radical_reverse_lookup`
   与 `lua_filter@*search@radical_pinyin`
5. `recognizer/patterns` → 去 `radical_lookup: "^uU[a-z]+$"`

外加 build-rime.sh 删除 `radical_pinyin.{dict,schema}.yaml` 与 `lua/search.lua`。
补丁内留有完整恢复说明。

**t9 方案不受影响**：它虽 `__include: rime_ice.schema.yaml:/`，但自行定义了完整
`engine:` 块（无 corrector / reduce_english_filter / radical 相关项），故上述改动
对九宫格无副作用。

### 精简累计
| | 上游 | 产物 |
|---|---|---|
| 文件数 | 162 | **54** |
| 体积 | 50 M | **47 M** |

余下体积仍由 `cn_dicts/` 45M 主导（`tencent.dict.yaml` 独占 17M），待后续词库讨论。
上游 `rime_ice.schema.yaml` 中残留的 `radical_lookup:` / `radical_reverse_lookup:`
配置块已成孤儿配置，引擎不再引用，无害。

---

## 真机测试第 1 轮反馈与修复

### 重大结论：`combine` 动作**真机可用** ✅
九宫格 →26 键的联动切换（切键盘 + 切方案）实测正常。
双键盘方案的核心假设成立，无需退路方案。

### 用户报告的问题
1. ✅ 九宫格 → 全键盘正常，自动切到雾凇拼音
2. ❌ 26 键下按空格左侧逗号会跳到九宫格
3. ❌ 切到九宫格后方案未跟随切 t9，打出来是英文

### 根因（2 和 3 是同一个）
`alphabetic` 纯英文键盘是麻烦源头：
```
alphabetic 底行: pinyinButton → { keyboardType: 'pinyin' }   ← 无 switchRimeSchema
```
用户点 26 键的「中/En」进入纯英文键盘，再点该键被扔回九宫格，
但方案完全没切 → 第 3 条现象。逗号误报应为相邻键位混淆。

### 用户追加需求
- 不需要独立的纯英文键盘
- 切换按钮直接就是「中En / T9」两向切换

### 修复（3 处）
1. `Common.libsonnet`
   - `alphabeticButton` 还原上游原状（双键盘下不再使用）
   - `gotoPinyin26Button`：文字改「中En」，去掉通往纯英文键盘的 swipeDown，
     上滑改为 `#中英切换`
   - **新增 `gotoPinyin9Button`**：文字「T9」，点按 → combine[t9, pinyin]，
     上滑 `#中英切换`
2. `Pinyin26.libsonnet` — `getSwitchButton` 在 `settings.dualKeyboard` 下
   返回 `gotoPinyin9Button`（不再经纯英文键盘中转）
3. `main.jsonnet` — 双键盘模式下不生成 `alphabetic` 与 `temp26Key`

**纯英文输入改由切换键上滑的 `#中英切换`（ascii_mode）承担**，
在同一键盘内切中/英，无需独立键盘。

### 结果
生成的键盘由 6 个减为 **4 个**：`pinyin` / `pinyin26` / `numeric` / `panel`
- 九宫格切换键：文字「中En」→ `combine[switchRimeSchema: rime_ice, keyboardType: pinyin26]`
- 26 键切换键：文字「T9」→ `combine[switchRimeSchema: t9, keyboardType: pinyin]`

已确认 14/17/18/注音/西戈布局才引用 `alphabeticButton`（本项目不用），
数字/符号键盘用 `returnPrimaryKeyboard` 而非硬编码 alphabetic，移除安全。

## 待查：shift 三段式大写

用户希望：点1下=首字母大写，点2下=锁定全大写，点3下=恢复。

**元书字段现状**（官方 keys-reference 确认）：
| 字段 | 有无 |
|---|---|
| `uppercasedStateForegroundStyle` | ✅ 外观 |
| `capsLockedStateForegroundStyle` | ✅ 外观（优先级更高） |
| `uppercasedStateAction` | ✅ 大写**和**大写锁定共用 |
| `capsLockedStateAction` | ❌ **不存在** |

动作优先级：`preeditStateAction` → `uppercasedStateAction` → `action`

**硬限制**：大写锁定状态没有独立动作字段，与大写状态共用 `uppercasedStateAction`，
故「第二下」与「第三下」在配置层无法区分。严格三段循环只能依赖
`action: 'shift'` 原生实现。标准动作列表中无独立 `capsLock` 动作。
官方文档未写 shift 的状态转换规则。

**待用户真机验证 shift 原生行为**：点一下 / 慢点第二下 / 快速双击 分别是什么状态。

---

## 第 2 轮改动：保留纯英文键盘并给它词库

### 关键发现：上游纯英文键盘为何没有词库
`Utils.libsonnet:253` 的 `processButtonParams(isAlphabetic, params)`：
```jsonnet
if isAlphabetic then
  local paramsWithSymbol = replaceCharacterToSymbolRecursive(params);
```
`isAlphabetic == true` 时**把所有 `character` 动作改写成 `symbol`**。
- `character` → 走 Rime 引擎，有候选
- `symbol`    → 直发系统，绕过 Rime

这是空山素影的刻意设计（做一个"傻"英文键盘）。**根因不在词库，在按键动作类型。**

### 解法：新增 KeyboardType.EnglishRime (=3)
| 类型 | 按键动作 | 方案 | 词库 |
|---|---|---|---|
| `English` (1) 上游 | symbol 直发系统 | 无 | ❌ |
| **`EnglishRime` (3) 新增** | character 走 Rime | `melt_eng` | ✅ |

新组件 `Components/English.libsonnet`，键盘名 `english`，字母小写显示
（`uppercaseForChinese` 对本类型不生效）。

### melt_eng 的双重身份（重要结构优势）
| 身份 | 配置位置 | 连句 |
|---|---|---|
| 独立方案（纯英文键盘） | `melt_eng.custom.yaml` 的 `translator/` | **开** |
| rime_ice 次翻译器（混打键盘） | `rime_ice.custom.yaml` 的 `melt_eng/` | **关** |

两者互相独立 → 可做到「纯英文键盘开连句，混打键盘不开」。
混打键盘开连句会产生 important→import+ant 并与中文抢位；
纯英文键盘无此顾虑，且词库带真实词频权重，Rime 断句倾向选高权重整词。

### 英文自动纠错的能力边界（已如实告知用户）
Rime **无内置英文拼写检查**。已实现的是 `derive` 派生的**模式覆盖**：
- 双写辅音写成单个 ×13 条（`derive/bb/b/` 等，显式枚举而非反向引用）
- `ie`↔`ei`、`ance`↔`ence`、`able`↔`ible`

**不能**处理任意漏字母、多字母、字母顺序颠倒。通用编辑距离纠错需自写 Lua filter，
在 4.3 万词库上做模糊搜索，键盘扩展内存/CPU 限制下有性能风险，暂不采用。

⚠️ **踩坑**：Python 写 `\1` 反向引用会被解释成控制字符 0x01，导致 YAML
报 `unacceptable character #x0001`。改为显式枚举 13 条规则。

### 底行键位（26 键左下角 123 拆分）
```
26 键:  [123][En]  ，  空格  [T9]  enter
        112.5 112.5              ← 原 225/1125 对半分，不挤压其它键
纯英文: [123]      ，  空格  [中En] enter
九宫格:      ←→   空格  [中En]
```

### 同时修复
`pinyinButton` 上游为 `{keyboardType: 'pinyin'}`（跳九宫格且不切方案，
即首轮真机踩的坑），改为 `combine[switchRimeSchema: rime_ice, keyboardType: pinyin26]`。

### 产物
- 键盘 5 个：`pinyin` / `pinyin26` / `english` / `numeric` / `panel`
- `schema_list` 三方案：`rime_ice` / `t9` / `melt_eng`
- 皮肤更名 **中英混打V1.1**，已重写 README

## 词库个性化现状（用户提问）

**目前全部为通用词库，无任何个性化内容。**

| 层 | 现状 |
|---|---|
| 中文词库 | 上游雾凇原版（base/ext/tencent/8105/41448），未改 |
| 英文词库 | en_merged 43,005 条 = 通用词频 + 424 条人工场景词（仍属通用） |
| `rime_ice.userdb` | **空** —— 用户私人自造词按其要求未带入 |
| `custom_phrase.txt` | 上游示例内容，未个性化 |

### 三个个性化入口
1. **`custom_phrase.txt`** —— 最直接。邮箱、手机号、地址、学号、常用短语，
   固定编码且权重 99 置顶。⚠️ 其中 13 条为绕开 corrector 硬钉的英文词
   （Amazon/NASA/SOHO 等）**现已多余**，corrector 已禁用。
2. **`enable_user_dict`** —— 已对 rime_ice 与 melt_eng 开启，边用边学，需时间积累。
3. **`src/tools/curated_terms.txt`** —— 场景词表，可加个人专业词汇，
   改完重跑 `build_en_dict.py` + `build-rime.sh`。

---

## V3：英文键盘三项修复

### ① 空格键文案
`EnglishRime` 类型原用 `$rimeSchemaName`，显示 melt_eng 的方案名
「Easy English Nano」——又长又难看。改为固定 `'English'`。

### ② 关闭英文连句
实测 `enable_sentence: true` 噪音过大：打单个字母就冒出大量拼接组合
（is / IC 之类），淹没真正想要的单词。用户明确只要单词不要连句。
→ `translator/enable_sentence: false`

（前面担心的 important→import+ant 属同类问题，实测比预想更严重。）

### ③ 错拼纠正：改用词库层实现
**关键认知**：`derive` 规则只能处理**固定模式**（如 `ie`→`ei`），
无法覆盖「漏字母」「相邻换位」这种**位置不定**的错法——正则替换表达不了。

→ 改为在 `build_en_dict.py` 中生成错拼变体，作为正确词的额外编码：
```
interesting  interesting  481   ← 正确拼写
interesting  intersting     8   ← 变体，权重压低
```

三种错型：
| 错型 | 例 | 源词范围 |
|---|---|---|
| 漏字母（逐位删除） | intersting→interesting | 词频前 12000 |
| 相邻换位 | recieve→receive | 词频前 12000 |
| 元音互换 | seperate→separate | 词频前 6000（组合数多，收紧） |

**两条硬约束**：
1. 变体若本身是真英文单词 → 丢弃。否则打 `hat` 会跳出 heat/that 一堆。
2. 一个变体对应多词时，只保留词频最高的那个。

同时删除了 melt_eng.custom.yaml 中已被变体覆盖的冗余 derive 规则
（13 条双写辅音、ie/ei），保留词尾模式替换（ance/ence、able/ible）。

### 附带发现：上游雾凇词库自带错拼
`en.dict.yaml:5393` 收录了 `definately` 作为正规词条。这类脏数据让纠错失效——
打 definately 出来的就是错的那个。

**自动识别规则（四条同时成立）**：
1. 不在 37 万词典校验表中
2. 恰好是某高频词的错拼变体
3. **词形全小写**
4. **在词频表中也查不到**

第 3 条是关键：上游对专有名词一律大写开头（Alexandre/Alta/Alton/Ames），
错拼是全小写（amatuer/definately）。没有这条会误删大批人名地名——
调试过程实测误删 119 → 加第 3 条降到 25 → 加第 4 条降到 11。
第 4 条保护那些不在词典表但人们确实在说的词（carbs 词频 690）。

另设 `TYPO_PROTECT` 白名单收容技术名词/品牌（arial、cron、logon、suse 等），
最终精确清除 **9 条**，全部为真错拼：
amatuer / definately / filme / fread / insest / institut / limon / mishief / trembl

⚠️ **踩坑**：检测顺序很重要。最初把变体生成的 `existing_codes` 过滤放在
收集阶段，导致已被上游收录的错拼在生成时就被跳过，反而检测不出来。
必须先收集**全部**候选变体用于检测，再做过滤决定落地哪些。

### 体积变化（本轮最大风险）
| | V2 | V3 |
|---|---|---|
| 英文词条 | 43,005 | **239,139** |
| 源文件 | 870 KB | **4,574 KB** |
| dist 总计 | 47 M | 50 M |

`melt_eng.prism.bin` 会明显变大，**需真机验证部署耗时、唤起速度、是否闪退**。
减量旋钮在 `build_en_dict.py` 顶部：`TYPO_TOP_N` / `TYPO_VOWEL_N` / `TYPO_MIN_LEN`。

### 皮肤更名
去除空山素影与原作者署名，改名为 **中英混打**（用户要求）。
⚠️ 该皮肤派生自 `luozikuan/kongshan-suying`（无 LICENSE 文件）。
个人使用无碍；**若将来公开发布，署名问题需先与原作者沟通**。

---

## V4：外观重做 + 逗号 bug 定位

### 逗号跳键盘：根因推断
排查过程（两处都排除了）：
- 皮肤层：`commaButton` 完整配置只有 `action: {character: ','}` 与
  `swipeUpAction: {character: '.'}`，无任何 keyboardType 动作
- Rime 层：`default.yaml:127` 仅 `',' : { commit: ， }`；
  `- { when: has_menu, accept: comma, send: Page_Up }` 是**注释掉**的

→ 结论：**元书对「非主键盘」有「输入后自动返回主键盘」的行为**，
与符号键盘打一个符号即跳回字母键盘同源（皮肤里的
`symbolicKeyboardLockStateToggle` 就是该行为的锁定开关）。
26 键当时是自定义键盘、九宫格是主键盘，故逗号上屏即被弹回。

⚠️ 官方 parameters 文档**未记载**任何 `lock`/`autoReturn`/`primaryKeyboard`
参数，此为推断，需真机复验。

**修法：主次颠倒**
- `Settings.keyboardLayout: '9'` → `'26'`，主键盘 `pinyin` = 26 键中英混打
- 新建 `Components/Pinyin9.libsonnet`，九宫格降为自定义键盘 `pinyin9`
- 删除 `Components/Pinyin26.libsonnet`（主键盘已是 26 键，不再需要）
- 切换目标全部对调：`gotoPinyin26Button` → `keyboardType: 'pinyin'`；
  `gotoPinyin9Button` → `keyboardType: 'pinyin9'`

键盘现为 5 个：`pinyin`(26键主) / `pinyin9` / `english` / `numeric` / `panel`

**待验证的新风险**：九宫格现在是非主键盘，可能反过来中招。

### 配色重做（羊皮纸 / 柔和灰）
| | light | dark |
|---|---|---|
| keyboardBackground | `#E9DFC9` | `#2A2A2D` |
| standardButton | `#FBF6EA` | `#3F3F45` |
| systemButton | `#D9CDB2` | `#343439` |
| label.primary | `#3B3226` | `#F2EFE8` |
| accent(6=墨印) | `#9C5A44`/`#FFF8EC` | `#B06A4F`/`#FFF3E4` |

⚠️ **关键**：上游 `keyboardBackgroundColor` 为 `#ffffff03` / `#00000003`
（近乎全透明），系统底色会透上来——不改成不透明就做不出羊皮纸底。
上游 dark 的 `standardButtonBackgroundColor: '#D1D1D165'` 同理带透明度，
已改为不透明 `#3F3F45`，否则会被底色影响发灰。

深色文字/按键背景对比约 9:1。`accentColors` 数组新增第 6 项「墨印」，
`Settings.accentColor: 6`。

### 九宫格「选择」键 → 拉丁符号键
原 `cursorRightButton`：`action: {sendKeys: 'Down'}`，文字「选择」——
在候选列表下移，触摸键盘上无用。

替换为 `latinSymbolButton`：点按 `@`，上划 `%`，长按网格
`@ & # % * + = / _ ~ ° —`。
一律用 `symbol`（直发系统）而非 `character`（会走 Rime punctuator 转全角）。
与最左侧 `t9Symbols`（中文标点为主）错开。

`longPress` 数组格式（皮肤自有约定，见 BasicStyle.libsonnet 的 `AddLongPress()`）：
`longPress: [ { action: {...}, text: '...', selected: true }, ... ]`

### 工具栏扩充
`toolbarSlideButtons: [8,17,1,2,3,10,12]` →
`[21,23,20,22,24,25,26,27,3,9,8,4,14,17]`
= 复制/粘贴/全选/剪切/撤销/重做/左移/右移/剪贴板/表情/符号/皮肤/部署/方案。
代号表在 Settings.libsonnet 该项上方注释中。

### 改名与封面
- 皮肤名 → **中英双打羊皮纸**，不显示作者
- **`demo.png` 是皮肤列表封面** —— 之前一直沿用参考皮肤原图，
  所以列表里始终显示旧名字和原作者。已用 `skin/make_demo.py`（Pillow）重绘。
- ⚠️ 字体坑：msyh 缺 `⇧ ⌫ ✂ ⧉` 等符号会渲染成豆腐块，
  这些字符须用 `seguisym.ttf`（Segoe UI Symbol）绘制。

### 环境
本机新装：Pillow 12.3.0、PyYAML。

---

## ✅ 已证实：元书「非主键盘输入后自动返回主键盘」

V4 真机验证通过——把 26 键改为主键盘、九宫格降为自定义键盘后，
逗号不再跳走。**推断成立。**

**这是官方文档完全未记载的行为**（parameters / keys-reference 里都没有
`lock` / `autoReturn` / `primaryKeyboard` 之类参数）。

→ 经验：以后遇到「键盘莫名跳走」，先查主次关系——
   `Settings.keyboardLayout` 决定哪个键盘是主键盘（`pinyin`），
   **主力键盘必须设为主键盘**，否则任何上屏动作都会把它弹走。

## 方案名显示：改皮肤不够，必须改方案本身

现象：空格键改成 'English' 后，「Easy English Nano」仍从别处冒出。

原因：皮肤只能控制空格键那一处文本。**元书凡是显示「当前方案名」的地方
——工具栏、方案切换菜单、切换时的提示浮层——读的都是方案自身的
`schema/name` 字段**（`melt_eng.schema.yaml:11`）。

修法：`melt_eng.custom.yaml` 加 `schema/name: English Nano`，
并与皮肤侧 `KeyboardType.EnglishRime` 的空格键文本保持一致。两边都要改。

## GitHub 推送（待办，未执行）
环境已就绪：`gh` CLI 已装，账号 `robavionix` 已登录。`Rime_conf` **尚非 git 仓库**。

推送前必须先与用户确认的三件事：
1. ⚠️ **署名问题**：皮肤派生自 `luozikuan/kongshan-suying`（**无 LICENSE 文件**，
   技术上属保留所有权利），且用户要求去除了原作者署名。**公开发布风险实在**，
   需先确认仓库公开/私有，或先联系原作者。
2. **仓库体积**：`vendor/`50M + `tools/`19M + `dist/`66M + `test/`16M —— 必须写
   `.gitignore` 排除，否则仓库会臃肿到难以维护。
3. ⚠️ **「4 个迭代版本」无法真实重现**：每轮都是原地覆盖 `skin/jsonnet` 与
   `src/`，**没有保留历史快照**。只能推送当前状态（V4），迭代过程仅存于
   本文档的记录。若要 V1/V2/V3 的实际代码，已不可恢复。
