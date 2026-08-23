local buttons = import '../../Buttons/Layout26.libsonnet';
local commonButtons = import '../../Buttons/Common.libsonnet';
local toolbarParams = import '../../Buttons/Toolbar.libsonnet';
local settings = import '../../Settings.libsonnet';
local basicStyle = import '../../Styles/BasicStyle.libsonnet';
local preedit = import '../Preedit.libsonnet';
local toolbar = import '../Toolbar.libsonnet';
local utils = import '../../Utils/Utils.libsonnet';

local portraitNormalButtonSize = {
  size: { width: '112.5/1125' },
};

// 枚举键盘类型
local KeyboardType = {
  Chinese: 0,
  English: 1,      // 上游的"傻"英文键盘：character 被改写为 symbol，直发系统，无词库
  Temp26Key: 2,
  EnglishRime: 3,  // 走 Rime 的纯英文键盘：保留 character 动作，配合 melt_eng 方案，有词库
};

local getSwitchButton(keyboardType) =
  if keyboardType == KeyboardType.English then
    commonButtons.pinyinButton
  else if keyboardType == KeyboardType.Temp26Key then
    commonButtons.goBackButton
  else if keyboardType == KeyboardType.EnglishRime then
    // 走 Rime 的纯英文键盘：本键回 26 键中英混打
    commonButtons.gotoPinyin26Button
  else if settings.dualKeyboard then
    // 双键盘模式：本键直接回九宫格并切 t9 方案
    commonButtons.gotoPinyin9Button
  else
    commonButtons.alphabeticButton;

// 26 键中英混打的左下角「123」拆成两半：左 = 数字键盘，右 = 纯英文键盘
local splitNumeric(keyboardType) =
  settings.dualKeyboard && keyboardType == KeyboardType.Chinese;

// 说明：dualKeyboard 下 keyboardLayout 固定为 '26'，此时 KeyboardType.Chinese
// 即主键盘 'pinyin'。九宫格由 Components/Pinyin9.libsonnet 单独生成。

local keyboardLayout(keyboardType) = {
  keyboardLayout: [
    {
      HStack: {
        subviews: [
          { Cell: buttons.qButton.name },
          { Cell: buttons.wButton.name },
          { Cell: buttons.eButton.name },
          { Cell: buttons.rButton.name },
          { Cell: buttons.tButton.name },
          { Cell: buttons.yButton.name },
          { Cell: buttons.uButton.name },
          { Cell: buttons.iButton.name },
          { Cell: buttons.oButton.name },
          { Cell: buttons.pButton.name },
        ],
      },
    },
    {
      HStack: {
        subviews: [
          { Cell: buttons.aButton.name },
          { Cell: buttons.sButton.name },
          { Cell: buttons.dButton.name },
          { Cell: buttons.fButton.name },
          { Cell: buttons.gButton.name },
          { Cell: buttons.hButton.name },
          { Cell: buttons.jButton.name },
          { Cell: buttons.kButton.name },
          { Cell: buttons.lButton.name },
        ],
      },
    },
    {
      HStack: {
        subviews: [
          { Cell: commonButtons.shiftButton.name },
          { Cell: buttons.zButton.name },
          { Cell: buttons.xButton.name },
          { Cell: buttons.cButton.name },
          { Cell: buttons.vButton.name },
          { Cell: buttons.bButton.name },
          { Cell: buttons.nButton.name },
          { Cell: buttons.mButton.name },
          { Cell: commonButtons.backspaceButton.name },
        ],
      },
    },
    {
      HStack: {
        subviews: [
          { Cell: commonButtons.numericButton.name },
        ] + (
          if splitNumeric(keyboardType) then
            [{ Cell: commonButtons.gotoEnglishButton.name }]
          else []
        ) + [
          { Cell: commonButtons.commaButton.name },
          { Cell: commonButtons.spaceButton.name },
          { Cell: getSwitchButton(keyboardType).name },
          { Cell: commonButtons.enterButton.name },
        ],
      },
    },
  ],
};

local getAlphabeticButtonSize(name) =
  local extra = {
    [buttons.aButton.name]: {
      size:
        { width: '168.75/1125' },
      bounds:
        { width: '112.5/168.75', alignment: 'right' },
    },
    [buttons.lButton.name]: {
      size:
        { width: '168.75/1125' },
      bounds:
        { width: '112.5/168.75', alignment: 'left' },
    },
  };
  (
  if std.objectHas(extra, name) then
    extra[name]
  else
    portraitNormalButtonSize
  );

local newKeyLayout(isDark=false, isPortrait=true, keyboardType=KeyboardType.Chinese) =
  local isAlphabetic = keyboardType == KeyboardType.English;

  // 按键参数处理。三种键盘类型走三条路：
  //
  //   English      —— utils.processButtonParams(true, ...)，它做两件事：
  //                   (a) character → symbol（直发系统，绕过 Rime）
  //                   (b) 合并 OnAlphabetic 显示覆盖（英文字形标点等）
  //   EnglishRime  —— **只要 (b) 不要 (a)**。需要英文标点字形，
  //                   但必须保留 character 动作走 Rime，否则丢掉词库。
  //                   不这样处理的话，逗号会显示「，」却输出「,」——显示与实际不符。
  //   其余         —— 原样
  local procParams(params) =
    if isAlphabetic then
      utils.processButtonParams(true, params)
    else if keyboardType == KeyboardType.EnglishRime then
      std.mergePatch(params, std.get(params, 'OnAlphabetic', default={}))
    else
      params;
  {
    keyboardHeight: if isPortrait then commonButtons.keyboardHeight.portrait else commonButtons.keyboardHeight.landscape,
    keyboardStyle: utils.newBackgroundStyle(style=basicStyle.keyboardBackgroundStyleName),
  }
  + keyboardLayout(keyboardType)

  // letter Buttons
  + std.foldl(function(acc, button)
      acc +
      basicStyle.newAlphabeticButton(
        button.name,
        isDark,
        getAlphabeticButtonSize(button.name) +
        procParams(button.params) + basicStyle.hintStyleSize + basicStyle.textCenterWhenShowSwipeText +
        (
          if keyboardType != KeyboardType.English
             && keyboardType != KeyboardType.EnglishRime
             && settings.uppercaseForChinese then
            basicStyle.newAlphabeticButtonUppercaseForegroundStyle(isDark, button.params) + basicStyle.getKeyboardActionText(button.params.uppercased)
          else {}
        )),
      buttons.letterButtons,
      {})

  // Third Row
  + basicStyle.newSystemButton(
    commonButtons.shiftButton.name,
    isDark,
    (
      if settings.keyboardLayout=='26b' then portraitNormalButtonSize else
      {
        size:
          { width: '168.75/1125' },
        bounds:
          { width: '151/168.75', alignment: 'left' },
      }
    )
    + procParams(commonButtons.shiftButton.params)
  )

  + basicStyle.newSystemButton(
    commonButtons.backspaceButton.name,
    isDark,
    (
      if settings.keyboardLayout=='26b' then
      {
        size: { width: '225/1125' },
      }
      else
      {
        size:
          { width: '168.75/1125' },
        bounds:
          { width: '151/168.75', alignment: 'right' },
      }
    )
    + procParams(commonButtons.backspaceButton.params),
  )

  // Fourth Row
  + basicStyle.newSystemButton(
    commonButtons.numericButton.name,
    isDark,
    // 拆分时对半：225/1125 → 112.5/1125，与普通键同宽，不挤压其它键
    { size: { width: if splitNumeric(keyboardType) then '112.5/1125' else '225/1125' } }
    + procParams(commonButtons.numericButton.params)
  )

  + (
    if splitNumeric(keyboardType) then
      basicStyle.newSystemButton(
        commonButtons.gotoEnglishButton.name,
        isDark,
        { size: { width: '112.5/1125' } }
        + procParams(commonButtons.gotoEnglishButton.params)
      )
    else {}
  )

  + basicStyle.newAlphabeticButton(
    commonButtons.commaButton.name,
    isDark,
    portraitNormalButtonSize + procParams(commonButtons.commaButton.params) + basicStyle.hintStyleSize,
    swipeTextFollowSetting=false,
  )
  + basicStyle.newAlphabeticButton(
    commonButtons.spaceButton.name,
    isDark,
    basicStyle.newSpaceButtonForegroundStyle(
      procParams(commonButtons.spaceButton.params),
      if keyboardType == KeyboardType.English then
        'English'
      else if keyboardType == KeyboardType.EnglishRime then
        // 与 melt_eng.custom.yaml 中的 schema/name 保持一致。
        // 上游方案名为「Easy English Nano」，又长又难看，已在 Rime 侧改名。
        // 注意：只改这里不够——工具栏、方案切换菜单、切换提示浮层读的都是
        // 方案自身的 name 字段，必须两边一起改。
        'English Nano'
      else if keyboardType == KeyboardType.Temp26Key then
        '临时中文'
      else
        '$rimeSchemaName',
      isDark
    ),
    needHint=false,
  )
  + local switchButton = getSwitchButton(keyboardType);
    basicStyle.newSystemButton(
    switchButton.name,
    isDark,
    portraitNormalButtonSize
    + procParams(switchButton.params)
  )
  + basicStyle.newColorButton(
    commonButtons.enterButton.name,
    isDark,
    {
      size: { width: '250/1125' },
    } + procParams(commonButtons.enterButton.params)
  )
;

{
  // 枚举键盘类型
  KeyboardType:: KeyboardType,

  // keyboardType=Temp26Key 表示这个26键布局是临时使用的，比如当前是拼音17键布局，但是想使用雾凇方案中的 V 模式
  // 只在非26键布局下额外生成一个26键布局，action 使用 character，把动作发给 Rime 处理
  // 和主键盘的区别在于"中英切换键"改为"返回"键
  new(isDark, isPortrait, keyboardType=KeyboardType.Chinese):
	local insets = if isPortrait then commonButtons.backgroundInsets.portrait else commonButtons.backgroundInsets.landscape;

    local extraParams = {
      insets: insets,
    };

    preedit.new(isDark)
    + toolbar.new(isDark, isPortrait, if keyboardType == KeyboardType.Chinese then 'pinyin' else 'alphabetic')
    + basicStyle.newKeyboardBackgroundStyle(isDark)
    + basicStyle.newAlphabeticButtonBackgroundStyle(isDark, extraParams)
    + basicStyle.newSystemButtonBackgroundStyle(isDark, extraParams)
    + basicStyle.newColorButtonBackgroundStyle(isDark, extraParams)
    + basicStyle.newAlphabeticHintBackgroundStyle(isDark, { cornerRadius: 10 })
    + basicStyle.newLongPressSymbolsBackgroundStyle(isDark, extraParams)
    + basicStyle.newLongPressSymbolsSelectedBackgroundStyle(isDark, extraParams)
    + basicStyle.newButtonAnimation()
    + newKeyLayout(isDark, isPortrait, keyboardType)
    // Notifications
    + basicStyle.rimeSchemaChangedNotification
}
