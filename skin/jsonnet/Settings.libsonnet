#======================================
# 此文件用于微调皮肤设置。
# 可根据需要修改下方内容，调整皮肤的相关参数。
# 修改完成后，保存本文件，然后回到皮肤界面，
# 长按皮肤，选择「运行 main.jsonnet」生效。
#======================================
{
  # 主键盘布局选择，可选值如下：
  # 26 : 常规26键布局
  # 26b: 左移26键布局(zxcvbnm行左移半格)
  # 9  : 拼音9键布局
  # 14 : 14键布局（双键布局）
  # 17 : 17键布局
  # 18 : 18键布局
  # bopomofo : 注音佈局
  # sigma : 西戈拼音布局
  # ⚠️ 双键盘模式下本项决定**哪个键盘是主键盘**。
  # 元书对非主键盘有「输入后自动返回主键盘」的行为（与符号键盘打一个符号
  # 就跳回字母键盘同源）。因此主力键盘必须设为主键盘，否则上屏一个逗号
  # 就会被弹走。26 键中英混打是主力，故设 '26'，九宫格作为自定义键盘。
  keyboardLayout: '26',


  #======================================
  # 【双键盘并存】九宫格 + 26键中英混打
  #======================================
  # 启用后：
  #   - 九宫格（pinyin 键盘）右下角键 → 跳转 26 键中英混打，并切到 schemaFor26
  #   - 26 键的「中/En」键下滑 → 返回九宫格，并切到 schemaFor9
  # 注意：keyboardLayout 必须为非 26 键布局，否则本项无效（26 键已是主键盘）
  dualKeyboard: true,

  # 主键盘 —— 键盘调出时默认显示哪个，也是元书上屏符号后返回的那个
  #   '26'  26 键中英混打（默认）
  #   '9'   九宫格
  #
  # 原理：元书打开的键盘类型固定叫 pinyin，本设置决定 pinyin 映射到哪套布局。
  # 另一套则挂到 pinyin9 上。两颗切换键的目标名由下面两个派生值自动跟着换，
  # 不需要手动改按键。
  primaryKeyboard: '26',

  # 派生：两套键盘各自的元书键盘类型名（不要手动改）
  kbd26: if self.dualKeyboard && self.primaryKeyboard == '9' then 'pinyin9' else 'pinyin',
  kbd9: if self.dualKeyboard && self.primaryKeyboard == '9' then 'pinyin' else 'pinyin9',

  # 九宫格使用的 Rime 方案 ID
  # t9 方案继承自 rime_ice，共用同一词库与 userdb，自造词互通
  schemaFor9: 't9',

  # 26 键中英混打使用的 Rime 方案 ID
  schemaFor26: 'rime_ice',

  # 纯英文键盘使用的 Rime 方案 ID
  # melt_eng 是独立可用的英文方案，挂载同一份 en_merged 词库，
  # 因此纯英文键盘同样享有 43,005 条词库、前缀补全与错拼派生。
  schemaForEn: 'melt_eng',


  # 数字键盘布局选择，可选值如下：
  # 9 : 九宫格布局
  # row : 数字显示在一行
  # hex : 十六进制布局
  numericLayout: '9',


  # 符号键盘布局选择，可选值如下：
  # default : 元书自带的符号键盘
  # row : 行式符号布局
  # classified : 分类符号布局
  symbolicLayout: 'default',


  # 输入时空格键上的内容，支持固定内容和变量
  # 注意：bopomofo 佈局下此項不生效，因為空格鍵打字中用於選聲調（一聲）
  # 变量可选如下：
  # $rimePreedit：Rime 预编辑文本
  # $rimeCandidate：Rime 首个候选字
  # $rimeCandidateComment: Rime 首个候选字的 comment 信息
  spaceButtonComposingText: '选定',


  # 是否为 iPad 设备，目前仅用于调整高度
  # true 是 iPad，false 是 iPhone
  iPad: false,


  # 空格键方案名称显示位置
  # x, y 取值范围为 [0, 1]
  # x 值越小越靠左，y 值越小越靠上
  # 特殊值 null 表示不显示方案名称
  # 居中。原为左下角 { x: 0.2, y: 0.7 }，方案名一长就溢出空格键、
  # 压到相邻按键上（如 English Nano）。
  spaceButtonSchemaNameCenter:
    { x: 0.5, y: 0.5 }, # 居中
    # { x: 0.5, y: 0.5 }, # 中间
    # null,               # 不显示


  # 上下滑动提示文字显示位置
  # hide      🙈不显示
  # topLeft   ↖️左上角
  # top       ⬆️正上方
  # topRight  ↗️右上角
  # bottomLeft   ↙️左下角
  # bottom       ⬇️正下方
  # bottomRight  ↘️右下角
  swipeUpTextCenter: 'top',
  swipeDownTextCenter: 'hide',


  # toolbar 按钮配置
  # 注意第一个和最后一个按键是固定的，不可配置
  # 按钮代号列表如下：
  # 【元书相关】
  # 1-脚本  2-常用语  3-剪贴板
  # 4-皮肤  5-文件管理器  6-方案切换
  # 7-数字键盘  8-符号键盘  9-表情键盘
  # 10-查看性能  11-左手模式  12-右手模式
  # 【Rime 相关】
  # 13-Rime同步  14-Rime部署  15-方案管理
  # 16-快符  17-RimeSwitcher
  # 【皮肤相关】
  # 18-皮肤微调  19-按键功能定义
  # 【文本编辑相关】
  # 20-全选  21-复制  22-剪切
  # 23-粘贴  24-撤销  25-重做
  # 26-左移  27-右移
  # 【显示相关】
  # 28-内嵌编辑（正在打的字直接显示在输入框里，而不是只在候选条上；
  #    补全、词库、容错一律不受影响。英文键盘上尤其有用）
  #
  # 将上述代号填入下面的数组即可
  # 顺序即显示顺序。编辑类功能排在最前，因为最常用。
  # 21-复制 23-粘贴 20-全选 22-剪切 24-撤销 25-重做 26-左移 27-右移
  # 3-剪贴板 9-表情键盘 8-符号键盘 4-皮肤 14-Rime部署 17-RimeSwitcher
  toolbarSlideButtons: [ 21, 23, 20, 22, 24, 25, 26, 27, 28, 3, 9, 8, 4, 14, 17 ],

  # 滑动按钮区域占几个按键宽度
  toolbarSlideButtonsMaxCount: {
    portrait: 5,   # 竖屏
    landscape: 8,  # 横屏
  },


  # 同时配了图标和文字的，优先显示图标还是文字
  # true 显示图标，false 显示文字
  preferIcon: true,


  # 主题色
  # 0-无  1-红色  2-绿色  3-橙色  4-蓝色  5-紫色
  accentColor: 6,


  # 中文模式下，字母键是否大写显示
  # 注意：17键布局、注音佈局、西戈码布局下此设置无效
  # true 大写，false 小写
  uppercaseForChinese: true,


  # shiftButton 的功能定义
  shiftButtonParams: {
    systemImageName: 'shift',
    action: 'shift',

    uppercased: { systemImageName: 'shift.fill', },
    capsLocked: { systemImageName: 'capslock.fill', },

    whenPreeditChanged: {
      action: { character: "'" },
      systemImageName: 'square.and.line.vertical.and.square',
      text: '分词',

      # action: 'tab',
      # systemImageName: 'arrow.right.to.line',
      # text: 'Tab',
    },
  },


  # Rime 方案中的快符
  quickAction:
    { character: ';' },
    # { character: '/' },

}
