// 26 键中英混打键盘（一等公民，与九宫格并存）
//
// 与 Components/Alphabetic.libsonnet 的区别：
//   Alphabetic  -> KeyboardType.English，纯英文，空格显示 'English'
//   本组件      -> KeyboardType.Chinese，走 Rime 中英混输，空格显示 $rimeSchemaName
//
// 原皮肤中 KeyboardType.Chinese 只在 keyboardLayout=='26' 时作为 pinyin 键盘生成，
// 导致九宫格布局下无法使用中英混打的 26 键。本组件将其提升为独立键盘 'pinyin26'。
local layout26 = import './Pinyin/Pinyin26.libsonnet';

{
  new(isDark, isPortrait):
    layout26.new(isDark, isPortrait, layout26.KeyboardType.Chinese),
}
