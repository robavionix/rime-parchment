#!/usr/bin/env python3
"""生成皮肤封面 demo.png —— 左半浅色羊皮纸，右半深色柔和灰"""
from PIL import Image, ImageDraw, ImageFont

W, H = 700, 512
CARD_M = 0                      # 画布即卡片，元书列表自带圆角容器

# ── 与 jsonnet/Constants/Colors.libsonnet 保持一致 ──
L = dict(bg='#E9DFC9', key='#FBF6EA', sys='#D9CDB2', text='#3B3226',
         hint='#8F8067', edge='#B9A985', accent='#9C5A44', accentFg='#FFF8EC')
D = dict(bg='#2A2A2D', key='#3F3F45', sys='#343439', text='#F2EFE8',
         hint='#A9A49A', edge='#1A1A1C', accent='#B06A4F', accentFg='#FFF3E4')

F = lambda p, s: ImageFont.truetype(p, s)
YAHEI, YAHEI_B = '/c/Windows/Fonts/msyh.ttc', '/c/Windows/Fonts/msyhbd.ttc'
SYM = '/c/Windows/Fonts/seguisym.ttf'   # msyh 缺 ⇧ ⌫ ✂ 等符号，会渲染成豆腐块
try:
    F(YAHEI_B, 10)
except OSError:                        # Git Bash 路径失败时退回 Windows 路径
    YAHEI, YAHEI_B = 'C:/Windows/Fonts/msyh.ttc', 'C:/Windows/Fonts/msyhbd.ttc'
    SYM = 'C:/Windows/Fonts/seguisym.ttf'
f_title = F(YAHEI_B, 42); f_sub = F(YAHEI, 18)
f_key = F(YAHEI, 21);     f_small = F(YAHEI, 13); f_tiny = F(YAHEI, 11)
f_sym = F(SYM, 22);       f_symtb = F(SYM, 19)

img = Image.new('RGB', (W, H), L['bg'])
d = ImageDraw.Draw(img)

# ── 标题区：整块羊皮纸底 ──
TITLE_H = 142
d.rectangle([0, 0, W, TITLE_H], fill=L['bg'])
d.text((44, 34), '中英双打', font=f_title, fill=L['text'])
d.text((44, 88), '羊皮纸', font=f_title, fill=L['accent'])
d.text((W - 44, 46), 'V4', font=f_title, fill=L['edge'], anchor='ra')
d.text((W - 44, 100), '九宫格 · 全键混打 · 纯英文', font=f_sub, fill=L['hint'], anchor='ra')

# ── 键盘预览：左浅右深 ──
KB_T, KB_B = TITLE_H, H
MID = W // 2
d.rectangle([0, KB_T, MID, KB_B], fill=L['bg'])
d.rectangle([MID, KB_T, W, KB_B], fill=D['bg'])

def pal(x):
    return L if x + 1 < MID else D

def key(x, y, w, h, label, kind='key', hint=None, r=8):
    p = pal(x)
    fill = p[kind] if kind in ('key', 'sys') else p['accent']
    fg = p['accentFg'] if kind == 'accent' else p['text']
    d.rounded_rectangle([x, y + 2, x + w, y + h + 2], radius=r, fill=p['edge'])
    d.rounded_rectangle([x, y, x + w, y + h], radius=r, fill=fill)
    if hint:
        d.text((x + w / 2, y + 9), hint, font=f_tiny, fill=p['hint'], anchor='ma')
        d.text((x + w / 2, y + h / 2 + 6), label, font=f_key, fill=fg, anchor='mm')
    else:
        d.text((x + w / 2, y + h / 2), label, font=f_key,
               fill=fg, anchor='mm')

# 工具栏
TB_Y = KB_T + 14
for i, ic in enumerate(['⧉', '✂', '📋', '↺', '↻', '☺', '⚙']):
    cx = 46 + i * 87
    d.text((cx, TB_Y + 12), ic, font=f_symtb, fill=pal(cx)['hint'], anchor='mm')

# 三行字母
ROWS = [('QWERTYUIOP', '1234567890'), ('ASDFGHJKL', None), ('ZXCVBNM', None)]
KW, KH, GAP = 60, 62, 6
y = TB_Y + 40
for row, (letters, hints) in enumerate(ROWS):
    n = len(letters)
    total = n * KW + (n - 1) * GAP
    x0 = (W - total) / 2
    if row == 2:
        x0 = (W - (n * KW + (n - 1) * GAP)) / 2
        key(x0 - KW - GAP - 14, y, KW + 14, KH, '', 'sys')
        key(x0 + total + GAP + 14, y, KW + 14, KH, '', 'sys')
        sx = x0 - KW - GAP - 14 + (KW + 14) / 2
        bx = x0 + total + GAP + 14 + (KW + 14) / 2
        d.text((sx, y + KH / 2), '⇧', font=f_sym, fill=pal(sx)['text'], anchor='mm')
        d.text((bx, y + KH / 2), '⌫', font=f_sym, fill=pal(bx)['text'], anchor='mm')
    for i, ch in enumerate(letters):
        x = x0 + i * (KW + GAP)
        key(x, y, KW, KH, ch, 'key', hints[i] if hints else None)
    y += KH + GAP + 4

# 底行：123 | En | ，| 空格 | T9 | 换行
BW = [78, 62, 62, 250, 62, 118]
LBL = [('123', 'sys'), ('En', 'sys'), ('，', 'key'), ('中英双打', 'key'),
       ('T9', 'sys'), ('换行', 'accent')]
x = (W - (sum(BW) + 5 * GAP)) / 2
for (lbl, kind), w in zip(LBL, BW):
    p = pal(x)
    d.rounded_rectangle([x, y + 2, x + w, y + KH + 2], radius=8, fill=p['edge'])
    d.rounded_rectangle([x, y, x + w, y + KH], radius=8,
                        fill=p['accent'] if kind == 'accent' else p[kind])
    fnt = f_small if lbl == '中英双打' else f_key
    d.text((x + w / 2, y + KH / 2), lbl, font=fnt,
           fill=p['accentFg'] if kind == 'accent' else p['text'], anchor='mm')
    x += w + GAP

img.save('skin/demo.png')
print(f'已生成 skin/demo.png  {W}x{H}')
