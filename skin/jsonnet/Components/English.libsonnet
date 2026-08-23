// 走 Rime 的纯英文键盘
//
// 与 Components/Alphabetic.libsonnet（上游的 'alphabetic'）的区别：
//   Alphabetic  -> KeyboardType.English，processButtonParams 把 character
//                  改写成 symbol，按键直发系统，**完全绕过 Rime，没有词库**
//   本组件      -> KeyboardType.EnglishRime，保留 character 动作走 Rime，
//                  配合 melt_eng 方案，享有完整词库、前缀补全与错拼派生
//
// 字母键小写显示（uppercaseForChinese 对本类型不生效）。
local layout26 = import './Pinyin/Pinyin26.libsonnet';

{
  new(isDark, isPortrait):
    layout26.new(isDark, isPortrait, layout26.KeyboardType.EnglishRime),
}
