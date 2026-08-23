# =====================================
# 此文件用于自定义键盘按键功能。
# 可根据需要修改下方内容，调整各类按键的行为
# 修改完成后，保存本文件，然后回到皮肤界面，
# 长按皮肤，选择「运行 main.jsonnet」生效。
#
# 包含中文17键布局的按键
# =====================================

local colors = import '../Constants/Colors.libsonnet';
local fonts = import '../Constants/Fonts.libsonnet';
local settings = import '../Settings.libsonnet';

{
  local root = self,

  // 按键定义
  hButton: {
    name: 'hButton',
    params: {
      text: 'HP',
      action: { character: 'h' },
      swipeUp: { action: { character: '1' } },
    },
  },
  sButton: {
    name: 'sButton',
    params: {
      text: 'Sh',
      action: { character: 's' },
      swipeUp: { action: { character: '2' } },
    },
  },
  zButton: {
    name: 'zButton',
    params: {
      text: 'Zh',
      action: { character: 'z' },
      swipeUp: { action: { character: '3' } },
    },
  },
  bButton: {
    name: 'bButton',
    params: {
      text: 'B',
      action: { character: 'b' },
      swipeUp: { action: { character: '@' } },
    },
  },
  xButton: {
    name: 'xButton',
    params: {
      text: 'oXv',
      action: { character: 'x' },
      swipeUp: { action: { character: '^' } },
    },
  },
  mButton: {
    name: 'mButton',
    params: {
      text: 'MS',
      action: { character: 'm' },
      swipeUp: { action: { character: '\\' } },
    },
  },

  // 第二行
  lButton: {
    name: 'lButton',
    params: {
      text: 'L',
      action: { character: 'l' },
      swipeUp: { action: { character: '4' } },
    },
  },
  dButton: {
    name: 'dButton',
    params: {
      text: 'D',
      action: { character: 'd' },
      swipeUp: { action: { character: '5' } },
    },
  },
  yButton: {
    name: 'yButton',
    params: {
      text: 'Y',
      action: { character: 'y' },
      swipeUp: { action: { character: '6' } },
    },
  },
  wButton: {
    name: 'wButton',
    params: {
      text: 'WZ',
      action: { character: 'w' },
      swipeUp: { action: { character: '0' } },
    },
  },
  jButton: {
    name: 'jButton',
    params: {
      text: 'JK',
      action: { character: 'j' },
      swipeUp: { action: { character: ':' } },
    },
  },
  nButton: {
    name: 'nButton',
    params: {
      text: 'NR',
      action: { character: 'n' },
      swipeUp: { action: { character: '"' } },
    },
  },

  // 第三行
  cButton: {
    name: 'cButton',
    params: {
      text: 'Ch',
      action: { character: 'c' },
      swipeUp: { action: { character: '7' } },
    },
  },
  qButton: {
    name: 'qButton',
    params: {
      text: 'Q~',
      action: { character: 'q' },
      swipeUp: { action: { character: '8' } },
    },
  },
  gButton: {
    name: 'gButton',
    params: {
      text: 'G',
      action: { character: 'g' },
      swipeUp: { action: { character: '9' } },
    },
  },
  fButton: {
    name: 'fButton',
    params: {
      text: 'CF',
      action: { character: 'f' },
      swipeUp: { action: { character: '!' } },
    },
  },
  tButton: {
    name: 'tButton',
    params: {
      text: 'T',
      action: { character: 't' },
      swipeUp: { action: { character: '?' } },
    },
  },


  letterButtons: [
    self.hButton, self.sButton, self.zButton, self.bButton, self.xButton, self.mButton,
    self.lButton, self.dButton, self.yButton, self.wButton, self.jButton, self.nButton,
    self.cButton, self.qButton, self.gButton, self.fButton, self.tButton,
  ],
}
