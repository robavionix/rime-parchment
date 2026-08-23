# =====================================
# 此文件用于自定义键盘按键功能。
# 可根据需要修改下方内容，调整各类按键的行为
# 修改完成后，保存本文件，然后回到皮肤界面，
# 长按皮肤，选择「运行 main.jsonnet」生效。
#
# 包含中文9键布局的按键
# =====================================

local colors = import '../Constants/Colors.libsonnet';
local fonts = import '../Constants/Fonts.libsonnet';
local settings = import '../Settings.libsonnet';
local commonButtons = import './Common.libsonnet';

{
  local root = self,

  // T9 按键
  // 1 键：点按走 Rime punctuator（1 @ . / : _ - #），打字时是分词键。
  //
  // 4.2 新增中文标点通路 —— 长按弹出网格，下划直出逗号。
  // 起因：九宫格最左侧那一列是元书内置组件 t9Symbols，点选标点后会跳回
  // 主键盘（皮肤无法干预，见 README「已知问题」）。这里用普通按键提供
  // 一条等价通路，普通按键不带切键盘动作，所以不会跳。
  //
  // 一律用 symbol（直发系统）而非 character（会走 Rime punctuator 转换）。
  t9OneButton: {
    name: 't9OneButton',
    params: {
      action: { character: '1' },
      swipeUp: { action: { symbol: '1' } },
      swipeDown: { action: { symbol: '，' }, text: '，' },
      text: '@/.',

      longPress: [
        { action: { symbol: '，' }, text: '，' },
        { action: { symbol: '。' }, text: '。', selected: true },
        { action: { symbol: '？' }, text: '？' },
        { action: { symbol: '！' }, text: '！' },
        { action: { symbol: '、' }, text: '、' },
        { action: { symbol: '：' }, text: '：' },
        { action: { symbol: '；' }, text: '；' },
        { action: { symbol: '…' }, text: '…' },
      ],

      whenPreeditChanged: {
        text: '分词',
      }
    },
  },
  t9TwoButton: {
    name: 't9TwoButton',
    params: {
      action: { character: '2' },
      swipeUp: { action: { symbol: '2' } },
      text: 'abc',
    },
  },
  t9ThreeButton: {
    name: 't9ThreeButton',
    params: {
      action: { character: '3' },
      swipeUp: { action: { symbol: '3' } },
      text: 'def',
    },
  },
  t9FourButton: {
    name: 't9FourButton',
    params: {
      action: { character: '4' },
      swipeUp: { action: { symbol: '4' } },
      text: 'ghi',
    },
  },
  t9FiveButton: {
    name: 't9FiveButton',
    params: {
      action: { character: '5' },
      swipeUp: { action: { symbol: '5' } },
      text: 'jkl',
    },
  },
  t9SixButton: {
    name: 't9SixButton',
    params: {
      action: { character: '6' },
      swipeUp: { action: { symbol: '6' } },
      text: 'mno',
    },
  },
  t9SevenButton: {
    name: 't9SevenButton',
    params: {
      action: { character: '7' },
      swipeUp: { action: { symbol: '7' } },
      text: 'pqrs',
    },
  },
  t9EightButton: {
    name: 't9EightButton',
    params: {
      action: { character: '8' },
      swipeUp: { action: { symbol: '8' } },
      text: 'tuv',
    },
  },
  t9NineButton: {
    name: 't9NineButton',
    params: {
      action: { character: '9' },
      swipeUp: { action: { symbol: '9' } },
      text: 'wxyz',
    },
  },
  // t9ZeroButton: {
  //   name: 't9ZeroButton',
  //   params: {
  //     action: { character: '0' },
  //     swipeUp: { action: { symbol: '0' } },
  //     fontSize: 20,
  //   },
  // },

  t9Buttons: [
    self.t9OneButton,
    self.t9TwoButton,
    self.t9ThreeButton,
    self.t9FourButton,
    self.t9FiveButton,
    self.t9SixButton,
    self.t9SevenButton,
    self.t9EightButton,
    self.t9NineButton,
    // self.t9ZeroButton,
  ],

  // t9拼音符号列表兼拼音候选
  t9SymbolsCollection: {
    name: 't9SymbolsCollection',
    params: {
      type: 't9Symbols',
    },
  },

  // 横屏时的 T9 候选列表
  t9CandidatesCollection: {
    name: 't9CandidatesCollection',
    params: {
      type: 'verticalCandidates',
    },
  },

  // 空格，增加上划输入数字 0 功能
  spaceButton: {
    name: 'spaceButton',
    params: std.mergePatch(commonButtons.spaceButton.params, {
      swipeUp: { action: { symbol: '0' } },
    }),
  },

  // 常用拉丁符号
  //
  // 替代原来的「选择」键——那个键的动作是 sendKeys: 'Down'（在候选列表里下移），
  // 触摸键盘上完全无用。
  //
  // 点按上屏 @（写邮箱最高频），上划 %，长按弹出符号网格。
  // 一律用 symbol 而非 character：symbol 直发系统，character 会走 Rime 的
  // punctuator 被转成全角中文标点。
  //
  // 选取原则：与最左侧 t9Symbols 列表（以中文标点为主）错开，
  // 收录写英文、填表单、发邮件时真正高频的拉丁符号。
  latinSymbolButton: {
    name: 'latinSymbolButton',
    params: {
      action: { symbol: '@' },
      text: '@',
      swipeUp: { action: { symbol: '%' }, text: '%' },
      swipeDown: { action: { symbol: '。' }, text: '。' },   // 4.2 新增，与 1 键下划的逗号配对
      longPress: [
        { action: { symbol: '@' }, text: '@', selected: true },
        { action: { symbol: '&' }, text: '&' },
        { action: { symbol: '#' }, text: '#' },
        { action: { symbol: '%' }, text: '%' },
        { action: { symbol: '*' }, text: '*' },
        { action: { symbol: '+' }, text: '+' },
        { action: { symbol: '=' }, text: '=' },
        { action: { symbol: '/' }, text: '/' },
        { action: { symbol: '_' }, text: '_' },
        { action: { symbol: '~' }, text: '~' },
        { action: { symbol: '°' }, text: '°' },
        { action: { symbol: '—' }, text: '—' },
      ],
    }
  },
}
