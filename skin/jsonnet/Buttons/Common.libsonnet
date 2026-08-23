# =====================================
# 此文件用于自定义键盘按键功能。
# 可根据需要修改下方内容，调整各类按键的行为
# 修改完成后，保存本文件，然后回到皮肤界面，
# 长按皮肤，选择「运行 main.jsonnet」生效。
#
# 包含一些通用按键，如空格、backspace、enter
# shift、返回键、各种切换键盘键等等
# =====================================

local colors = import '../Constants/Colors.libsonnet';
local fonts = import '../Constants/Fonts.libsonnet';
local settings = import '../Settings.libsonnet';

{
  local root = self,

  // 键盘高度（不含工具栏）
  keyboardHeight: if !settings.iPad then
    {
      portrait: 216,  // 54 * 4
      landscape: 160,  // 40 * 4
    }
    else
    {
      portrait: 256,  // 64 * 4
      landscape: 344,  // 86 * 4
    },

  // 按键背景内边距
  backgroundInsets: if !settings.iPad then
    {
      portrait: { top: 5, left: 3, bottom: 5, right: 3 },
      landscape: { top: 3, left: 3, bottom: 3, right: 3 },
    }
    else
    {
      portrait: { top: 3, left: 3, bottom: 3, right: 3 },
      landscape: { top: 4, left: 6, bottom: 4, right: 6 },
    },

  // 特殊功能键
  spaceButton: {
    name: 'spaceButton',
    params: {
      action: 'space',
      systemImageName: 'space',
      center: {x: 0.5, y: 0.5},
      notification:
        (if settings.spaceButtonSchemaNameCenter != null then
          ['rimeSchemaChangedNotification']
        else []),

      whenPreeditChanged: {
        text: settings.spaceButtonComposingText,
        fontSize: fonts.systemButtonTextFontSize,

        swipeUp: {
          action: { shortcut: '#次选上屏' },
          text: '次选',
        },
      },
    },
  },

  tabButton: {
    name: 'tabButton',
    params: {
      action: 'tab',
      systemImageName: 'arrow.right.to.line',
    },
  },

  backspaceButton: {
    name: 'backspaceButton',
    params: {
      action: 'backspace',
      repeatAction: self.action,
      systemImageName: 'delete.left',
      highlightSystemImageName: 'delete.left.fill',
	  whenPreeditChanged: {
		swipeUp: {
          action: { sendKeys: 'Control+Backspace' } // 删除一个音节
		},
	  },
    },
  },

  shiftButton: {
    name: 'shiftButton',
    params: settings.shiftButtonParams,
  },

  enterButton: {
    name: 'enterButton',
    params: {
      action: 'enter',
      text: '$returnKeyType',

      swipeUp: { action: { shortcut: '#行首' } },
      swipeDown: { action: { shortcut: '#行尾' } },

      longPress: [
        {
          action: { shortcut: '#换行' },
          systemImageName: 'return',
          text: '换行',
        },
      ],

      whenPreeditChanged: {
        text: '确认',
        backgroundStyle: 'systemButtonBackgroundStyle',
        normalColor: colors.systemButtonForegroundColor,
      },

      whenReturnKeyChanged: [
        {
          // NOTE: 此通知仅用来更新 enterButton 的前景文字 $returnKeyType
          //       匹配不上 returnKeyType:[] 中指定的值，就会使用默认的文字 $returnKeyType
          returnKeyType: [],
        },
      ],
    },
  },

  functionButton: {
    name: 'functionButton',
    params: {
      action: { shortcut: '#selectText' },
      systemImageName: 'selection.pin.in.out',

      whenKeyboardAction: [
        {
          notificationKeyboardAction: {
            shortcut: '#selectText'
          },
          action: { shortcut: '#cut' },
          systemImageName: 'scissors',
        },
      ],
    },
  },

  goBackButton: {
    name: 'goBackButton',
    params: {
      action: 'returnLastKeyboard',
      systemImageName: 'arrow.uturn.backward',
    },
  },

  gotoPrimaryKeyboardButton: {
    name: 'gotoPrimaryKeyboardButton',
    params: {
      action: 'returnPrimaryKeyboard',
      systemImageName: 'arrow.backward',
      text: '返回',
    },
  },

  iOSNextKeyboardButton: {
    name: 'iOSNextKeyboardButton',
    params: {
      action: 'nextKeyboard',
      systemImageName: 'globe',
    },
  },

  numericButton: {
    name: 'numericButton',
    params: {
      action: { keyboardType: 'numeric' },
      text: if settings.preferIcon then '123' else '数字',
      swipeUp: { action: { keyboardType: 'symbolic' } },
      swipeDown: { action: { keyboardType: 'emojis' } },

	  OnAlphabetic: {
		// 对于英文键盘，如果数字键盘是 row 形式，那么切到 numericRowEn 键盘
		// numericRowEn 键盘经过特殊处理，上面的符号都是用 symbol 直接上屏的
		[if settings.numericLayout == 'row' then 'action']: { keyboardType: 'numericRowEn' },

		// 同样地，对于英文键盘，如果字符键盘是 row 形式，那么切到 symbolicRowEn 键盘
		swipeUp: {
		  [if settings.symbolicLayout == 'row' then 'action']: { keyboardType: 'symbolicRowEn' },
		}
	  }
    }
    + ( // 对于 iPad 设备，长按数字键可以切换到 iOS 系统键盘列表中的下一个键盘
      if settings.iPad then {
        longPress: [
          {
            systemImageName: 'globe',
            action: 'nextKeyboard',
            selected: true,
          },
        ],
      }
      else {}
    )
    ,
  },

  symbolicButton: {
    name: 'symbolicButton',
    params: {
      action: { keyboardType: 'symbolic' },
      text: if settings.preferIcon then '#+=' else '符号',

	  OnAlphabetic: {
		[if settings.symbolicLayout == 'row' then 'action']: { keyboardType: 'symbolicRowEn' },
	  },
    },
  },

  alphabeticButton: {
    name: 'alphabeticButton',
    params: {
      action: { keyboardType: 'alphabetic' },
      assetImageName: 'chineseState2',
      swipeUp: { action: { shortcut: '#方案切换' } },

      // 非双键盘模式下保持原行为；双键盘模式下本按钮已不再被使用
      [if !settings.dualKeyboard && !std.startsWith(settings.keyboardLayout, '26') then 'swipeDown']: {
        action: { keyboardType: 'temp26Key' },
      },
    },
  },

  // ══ 双键盘切换：九宫格 ⇄ 26 键中英混打 ══
  // 两颗按钮占同一位置，互为对方的目标，点按即切键盘 + 切 Rime 方案。
  // 上滑为 #中英切换（ascii_mode）——纯英文输入由它承担，
  // 因此不再需要独立的 alphabetic 纯英文键盘。

  // 九宫格上的按钮 → 去 26 键中英混打
  gotoPinyin26Button: {
    name: 'gotoPinyin26Button',
    params: {
      action: { combine: [
        { switchRimeSchema: settings.schemaFor26 },
        { keyboardType: 'pinyin' },   // 主键盘即 26 键中英混打
      ] },
      text: '中En',
      swipeUp: { action: { shortcut: '#中英切换' } },
    },
  },

  // 26 键左下角拆分出的「En」→ 走 Rime 的纯英文键盘
  // 关键：目标键盘 'english' 保留 character 动作（经 Rime），
  // 并切到 melt_eng 方案，因此有完整词库与补全。
  // 上游的 'alphabetic' 键盘会把 character 改写成 symbol 直发系统，故无词库。
  gotoEnglishButton: {
    name: 'gotoEnglishButton',
    params: {
      action: { combine: [
        { switchRimeSchema: settings.schemaForEn },
        { keyboardType: 'english' },
      ] },
      text: 'En',
    },
  },

  // 26 键上的按钮 → 回九宫格
  gotoPinyin9Button: {
    name: 'gotoPinyin9Button',
    params: {
      action: { combine: [
        { switchRimeSchema: settings.schemaFor9 },
        { keyboardType: 'pinyin9' },  // 九宫格现为自定义键盘
      ] },
      text: 'T9',
      swipeUp: { action: { shortcut: '#中英切换' } },
    },
  },

  pinyinButton: {
    name: 'pinyinButton',
    params: {
      // 双键盘模式：返回 26 键中英混打（并切回 rime_ice）。
      // 上游原为 { keyboardType: 'pinyin' }，会跳到九宫格且不切方案——
      // 这正是首轮真机测试中「切到九宫格却打出英文」的根因。
      action: if settings.dualKeyboard then
                { combine: [
                    { switchRimeSchema: settings.schemaFor26 },
                    { keyboardType: 'pinyin' },
                ] }
              else
                { keyboardType: 'pinyin' },
      assetImageName: 'englishState2',
    },
  },

  asciiModeButton: {
    name: 'asciiModeButton',
    params: {
      action: { shortcut: '#中英切换' },
      assetImageName: 'chineseState2',
      swipeUp: { action: { shortcut: '#方案切换' } },

      whenRimeOptionChanged: {
        optionName: 'ascii_mode',
        optionValue: true,
        assetImageName: 'englishState2'
      },
    },
  },

  commaButton: {
    name: 'commaButton',
    params: {
      action: { character: ',', },
      text: '，',
      center: { y: 0.52 },

      swipeUp: {
        action: { character: '.' },
        text: '。',
        center: { y: 0.3 }
      },

      OnAlphabetic: {
        text: ',', center: { y: 0.48 },
        swipeUp: { text: '.', center: { y: 0.28 } },
      },
    },
  },

  clearPreeditButton: {
    name: 'clearPreeditButton',
    params: {
      action: { shortcut: '#换行' },
      text: '换行',

      whenPreeditChanged: {
        action: { shortcut: '#重输' },
        text: '重输',
      },
    },
  },

}
