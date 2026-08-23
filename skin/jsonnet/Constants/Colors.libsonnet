local settings = import '../Settings.libsonnet';

// 本文件中的颜色使用 #rrggbb 或 #rrggbbaa 格式的十六进制字符串表示
// 其中 rr、gg、bb 分别表示红、绿、蓝三种颜色的强度，范围是 00 到 FF（十六进制）
// aa 表示 alpha 通道的值，范围也是 00 到 FF，00 表示完全透明，FF 表示完全不透明（此时可以省略 alpha 通道）
// 注意：aa 为 00 时颜色完全透明，会使按键不可点击，建议至少使用 01

// 标签颜色常量定义
local labelColor = {
  // 浅色=墨褐（不用纯黑，与羊皮纸底同为暖色系，长时间看更省眼）
  // 深色=暖白（与柔和灰底对比度约 9:1，按键字清晰）
  primary: {
    light: '#3B3226',
    dark: '#F2EFE8',
  },
  // 次级：上下划提示文字
  secondary: {
    light: '#8F8067',
    dark: '#A9A49A',
  },
  tertiary: {
    light: '#BBAE95',
    dark: '#6E6A63',
  },
  quaternary: {
    light: '#D3C8B0',
    dark: '#4A4750',
  },
};

// 分割线颜色
local separatorColor = {
  light: '#C9BCA0',
  dark: '#45454B',
};

// 键盘背景色
local keyboardBackgroundColor = {
  light: '#E9DFC9',  // 羊皮纸底
  dark: '#2A2A2D',   // 柔和灰底（非纯黑，减少暗环境下的明暗反差）
};

// 标准按键背景色（如字母按键、空格键等）
local standardButtonBackgroundColor = {
  light: '#FBF6EA',
  dark: '#3F3F45',   // 改为不透明：原 #D1D1D165 带透明度，会被底色影响而发灰
};

// 标准按键按下时的背景色
local standardButtonHighlightedBackgroundColor = {
  light: '#EFE6D2',
  dark: '#52525A',
};

// 标准按键前景色（如字母按键、空格键等），用于按键的字体，图片等
local standardButtonForegroundColor = labelColor.primary;

local standardButtonHighlightedForegroundColor = standardButtonForegroundColor;

// 标准按键备用色，用于显示上下划提示等
local alternativeForegroundColor = labelColor.secondary;
local alternativeHighlightedForegroundColor = alternativeForegroundColor;

// 标准按键阴影颜色
local standardButtonShadowColor = {
  light: '#B9A985',
  dark: '#1A1A1C',
};

// 系统按键（如回车、删除等）背景颜色
local systemButtonBackgroundColor = {
  light: '#D9CDB2',
  dark: '#343439',
};

local systemButtonHighlightedBackgroundColor = {
  light: '#FBF6EA',
  dark: '#45454C',
};

// 系统按键（如回车、删除等）前景颜色
local systemButtonForegroundColor = labelColor.primary;

local systemButtonHighlightedForegroundColor = systemButtonForegroundColor;

// MARK: 一定要与 Settings.libsonnet 中的 accentColor 编号对应
local accentColors = [
  // 在这里检查一下对比度 https://webaim.org/resources/contrastchecker/
  // 确保前景色和背景色的对比度足够高（至少大于 3）以保证可读性
  { // red
    background: '#da4357',
    foreground: '#ffffff',
  },
  { // green
    background: '#50A545',
    foreground: '#ffffff',
  },
  { // orange
    background: '#E86E30',
    foreground: '#ffffff',
  },
  { // blue
    background: '#2e67f8',
    foreground: '#ffffff',
  },
  { // purple
    background: '#7A72B8',
    foreground: '#ffffff',
  },
  { // 6 = 墨印（朱砂偏赭）——本皮肤默认，与羊皮纸/柔和灰均协调
    background: { light: '#9C5A44', dark: '#B06A4F' },
    foreground: { light: '#FFF8EC', dark: '#FFF3E4' },
  },
];

local colorButtonBackgroundColor = if settings.accentColor == 0 then systemButtonBackgroundColor else
  local color = accentColors[settings.accentColor - 1].background;
  if std.type(color) == 'object' && std.objectHas(color, 'light') && std.objectHas(color, 'dark') then
    color
  else
    {
      light: color,
      dark: color,
    };
local colorButtonForegroundColor = if settings.accentColor == 0 then systemButtonForegroundColor else
  local color = accentColors[settings.accentColor - 1].foreground;
  if std.type(color) == 'object' && std.objectHas(color, 'light') && std.objectHas(color, 'dark') then
    color
  else
    {
      light: color,
      dark: color,
    };

local colorButtonHighlightedBackgroundColor = systemButtonHighlightedBackgroundColor;
local colorButtonHighlightedForegroundColor = labelColor.primary;

// 按键底部边缘颜色
local lowerEdgeOfButtonNormalColor = {
  light: '#B9A985',
  dark: '#1A1A1C',
};

// 按下状态下，按键底部边缘颜色
local lowerEdgeOfButtonHighlightColor = {
  light: '#B9A985',
  dark: '#1A1A1C',
};

// 标准按键 Hint 背景色(包含长按符号列表的背景色)
local standardCalloutBackgroundColor = {
  light: '#FBF6EA',
  dark: '#4A4A52',
};

// 标准按键 Hint 前景色，用于按键的字体，图片等
local standardCalloutForegroundColor = standardButtonForegroundColor;

local standardCalloutHighlightedForegroundColor = colorButtonForegroundColor;

// 标准按键 Hint 选中背景色，如长按符号列表中选中的符号背景色
local standardCalloutSelectedBackgroundColor = colorButtonBackgroundColor;

// 标准按键 Hint 边框颜色
local standardCalloutBorderColor = {
  light: '#C9BCA0',
  dark: '#5C5C64',
};

// 预编辑区文字颜色
local preeditForegroundColor = standardButtonForegroundColor;

// 工具栏按钮前景色
local toolbarButtonForegroundColor = standardButtonForegroundColor;

// 工具栏按钮高亮前景色
local toolbarButtonHighlightedForegroundColor = standardButtonForegroundColor;

// 候选字亮候选字背景颜色
local candidateHighlightColor = standardButtonBackgroundColor;
local candidateForegroundColor = standardButtonForegroundColor;

// 候选字分隔线颜色
local candidateSeparatorColor = separatorColor;


{
  labelColor: labelColor,
  separatorColor: separatorColor,
  keyboardBackgroundColor: keyboardBackgroundColor,
  standardButtonBackgroundColor: standardButtonBackgroundColor,
  standardButtonHighlightedBackgroundColor: standardButtonHighlightedBackgroundColor,
  standardButtonForegroundColor: standardButtonForegroundColor,
  standardButtonHighlightedForegroundColor: standardButtonHighlightedForegroundColor,
  alternativeForegroundColor: alternativeForegroundColor,
  alternativeHighlightedForegroundColor: alternativeHighlightedForegroundColor,
  standardButtonShadowColor: standardButtonShadowColor,
  systemButtonBackgroundColor: systemButtonBackgroundColor,
  systemButtonHighlightedBackgroundColor: systemButtonHighlightedBackgroundColor,
  systemButtonForegroundColor: systemButtonForegroundColor,
  systemButtonHighlightedForegroundColor: systemButtonHighlightedForegroundColor,
  colorButtonBackgroundColor: colorButtonBackgroundColor,
  colorButtonHighlightedBackgroundColor: colorButtonHighlightedBackgroundColor,
  colorButtonForegroundColor: colorButtonForegroundColor,
  colorButtonHighlightedForegroundColor: colorButtonHighlightedForegroundColor,
  lowerEdgeOfButtonNormalColor: lowerEdgeOfButtonNormalColor,
  lowerEdgeOfButtonHighlightColor: lowerEdgeOfButtonHighlightColor,
  standardCalloutBackgroundColor: standardCalloutBackgroundColor,
  standardCalloutForegroundColor: standardCalloutForegroundColor,
  standardCalloutHighlightedForegroundColor: standardCalloutHighlightedForegroundColor,
  standardCalloutSelectedBackgroundColor: standardCalloutSelectedBackgroundColor,
  standardCalloutBorderColor: standardCalloutBorderColor,
  preeditForegroundColor: preeditForegroundColor,
  toolbarButtonForegroundColor: toolbarButtonForegroundColor,
  toolbarButtonHighlightedForegroundColor: toolbarButtonHighlightedForegroundColor,
  candidateHighlightColor: candidateHighlightColor,
  candidateForegroundColor: candidateForegroundColor,
  candidateSeparatorColor: candidateSeparatorColor,
}
