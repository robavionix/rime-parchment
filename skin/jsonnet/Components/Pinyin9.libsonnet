// 九宫格，作为自定义键盘 'pinyin9'
//
// 主键盘（'pinyin'）已让位给 26 键中英混打——因为元书对非主键盘有
// 「输入后自动返回主键盘」的行为，主力键盘放在非主位会被逗号等上屏动作弹走。
local layout9 = import './Pinyin/Pinyin9.libsonnet';

{
  new(isDark, isPortrait):
    layout9.new(isDark, isPortrait),
}
