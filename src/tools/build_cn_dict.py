#!/usr/bin/env python3
"""
构建个人中文词库 cn_dicts/personal.dict.yaml

词条来自 src/tools/cn_terms/*.txt（每行空格分隔，# 开头为注释）。
拼音由 pypinyin 自动生成，多音字用 OVERRIDE 表人工修正。

多音字是本脚本最大的风险点。pypinyin 的词组词典能覆盖大部分情况，
但专业术语常不在其中（如「公差」会被判成 gong chai）。
新增词条后请跑 --audit 检查含多音字的词。
"""
import sys
import pathlib
from pypinyin import lazy_pinyin, Style

sys.stdout.reconfigure(encoding='utf-8')
ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / 'src' / 'tools' / 'cn_terms'
OUT = ROOT / 'src' / 'cn_dicts' / 'personal.dict.yaml'

WEIGHT = 1000   # 高于绝大多数通用词条，保证专业词优先

# 多音字人工修正表：键为词，值为正确的空格分隔拼音。
OVERRIDE = {
    # 差 cha / chai
    '公差': 'gong cha', '尺寸公差': 'chi cun gong cha',
    '形位公差': 'xing wei gong cha', '几何公差': 'ji he gong cha',
    '公差带': 'gong cha dai', '差速器': 'cha su qi',
    '限滑差速器': 'xian hua cha su qi', '托森差速器': 'tuo sen cha su qi',
    '电子差速锁': 'dian zi cha su suo', '差动轮系': 'cha dong lun xi',
    '压差': 'ya cha', '温差': 'wen cha',
    # 模 mu / mo
    '模具': 'mu ju', '模具钢': 'mu ju gang', '模锻': 'mu duan',
    # 弹 tan / dan
    '弹簧': 'tan huang', '弹簧垫圈': 'tan huang dian quan',
    '压缩弹簧': 'ya suo tan huang', '拉伸弹簧': 'la shen tan huang',
    '扭转弹簧': 'niu zhuan tan huang', '碟形弹簧': 'die xing tan huang',
    '弹簧指数': 'tan huang zhi shu', '弹性模量': 'tan xing mo liang',
    '弹性联轴器': 'tan xing lian zhou qi', '弹射座椅': 'tan she zuo yi',
    # 调 tiao / diao
    '调质': 'tiao zhi', '调焦': 'tiao jiao', '可调进气道': 'ke tiao jin qi dao',
    # 行 xing / hang
    '行程': 'xing cheng', '对焦行程': 'dui jiao xing cheng',
    '冲程': 'chong cheng',
    # 重 zhong / chong
    '重心': 'zhong xin', '视觉重心': 'shi jue zhong xin',
    '中央重点测光': 'zhong yang zhong dian ce guang',
    '重合度': 'zhong he du', '前后配重': 'qian hou pei zhong',
    '推重比': 'tui zhong bi',
    # 曝 bao / pu
    '曝光': 'bao guang', '曝光三角': 'bao guang san jiao',
    '曝光补偿': 'bao guang bu chang', '包围曝光': 'bao wei bao guang',
    '自动包围曝光': 'zi dong bao wei bao guang',
    '曝光锁定': 'bao guang suo ding', '长曝光': 'chang bao guang',
    '定时曝光': 'ding shi bao guang', '曝光合成': 'bao guang he cheng',
    '过曝': 'guo bao', '欠曝': 'qian bao',
    # 卡 ka / qia
    '卡口': 'ka kou', '卡钳': 'ka qian', '刹车卡钳': 'sha che ka qian',
    '对向活塞卡钳': 'dui xiang huo sai ka qian', '虎口': 'hu kou',
    # 长 chang / zhang
    '长焦': 'chang jiao', '超长焦': 'chao chang jiao', '长离': 'chang li',
    '长桁': 'chang heng', '弦长': 'xian chang',
    # 散 san / san(3)
    '散华': 'san hua', '色散': 'se san', '低色散镜片': 'di se san jing pian',
    '散热': 'san re', '散热器': 'san re qi', '扩散器': 'kuo san qi',
    # 干 gan
    '干涉': 'gan she', '干扰阻力': 'gan rao zu li',
    '干式双离合': 'gan shi shuang li he',
    # 载 zai
    '载荷': 'zai he', '翼载荷': 'yi zai he', '临界载荷': 'lin jie zai he',
    # 转 zhuan / zhuan(4)
    '转速': 'zhuan su', '主轴转速': 'zhu zhou zhuan su',
    '滚转力矩': 'gun zhuan li ju', '转向节': 'zhuan xiang jie',
    '转动副': 'zhuan dong fu',
    # 相 xiang
    '相机': 'xiang ji', '相位': 'xiang wei', '相位对焦': 'xiang wei dui jiao',
    '片上相位': 'pian shang xiang wei', '相里要': 'xiang li yao',
    # 强 qiang
    '强度': 'qiang du', '屈服强度': 'qu fu qiang du',
    '抗拉强度': 'kang la qiang du', '疲劳强度': 'pi lao qiang du',
    '高强度钢': 'gao qiang du gang', '强度校核': 'qiang du jiao he',
    # 校 jiao / xiao
    '校核': 'jiao he', '刚度校核': 'gang du jiao he',
    '稳定性校核': 'wen ding xing jiao he',
    '显示器校色': 'xian shi qi jiao se',
    # 空 kong
    '空速': 'kong su', '真空速': 'zhen kong su',
    '空气滤清器': 'kong qi lv qing qi', '空气悬架': 'kong qi xuan jia',
    '空气动力学': 'kong qi dong li xue',
    # 数 shu
    '数控': 'shu kong', '数控机床': 'shu kong ji chuang', '参数': 'can shu',
    '数据坞': 'shu ju wu', '模数': 'mo shu',
    # 处 chu
    '处理': 'chu li', '表面处理': 'biao mian chu li',
    '时效处理': 'shi xiao chu li', '固溶处理': 'gu rong chu li',
    '气源处理': 'qi yuan chu li', '热管理': 're guan li',
    '电池管理系统': 'dian chi guan li xi tong',
    '推进剂管理': 'tui jin ji guan li', '色彩管理': 'se cai guan li',
    # 折 zhe
    '折枝': 'zhe zhi', '折返镜头': 'zhe fan jing tou',
    # 掠 lue
    '后掠角': 'hou lve jiao', '变后掠翼': 'bian hou lve yi',
    '梢根比': 'shao gen bi',
    # 轴承 zhou cheng
    '轴瓦': 'zhou wa', '轴承': 'zhou cheng', '分离轴承': 'fen li zhou cheng',
    # 传 chuan
    '带传动': 'dai chuan dong', '链传动': 'lian chuan dong',
    '传动比': 'chuan dong bi', '传动轴': 'chuan dong zhou',
    '传动系统': 'chuan dong xi tong',
    # 比 bi
    '主减速比': 'zhu jian su bi', '扁平比': 'bian ping bi',
    '涵道比': 'han dao bi', '大涵道比': 'da han dao bi', '压比': 'ya bi',
    '压缩比': 'ya suo bi', '升阻比': 'sheng zu bi',
    '喷管扩张比': 'pen guan kuo zhang bi', '齿比': 'chi bi', '光比': 'guang bi',
    # 着 zhuo
    '着陆': 'zhuo lu', '着陆器': 'zhuo lu qi', '着陆距离': 'zhuo lu ju li',
    '着陆腿': 'zhuo lu tui',
    # 量 liang
    '当量': 'dang liang', '整备质量': 'zheng bei zhi liang',
    # 姓氏特读
    '朴槿惠': 'piao jin hui',            # 朝鲜姓氏「朴」读 Piao 非 Pu
    '仇远': 'qiu yuan',                  # 姓氏「仇」读 Qiu 非 Chou
    '朴正熙': 'piao zheng xi',           # 同上，朝鲜姓氏朴
    '呼日勒苏赫': 'hu ri le su he',      # 蒙古语音译，勒读 le 非 lei
    '巴特图勒嘎': 'ba te tu le ga',
    # 专业术语判错
    '重构控制': 'chong gou kong zhi',        # 控制律重构，chong 非 zhong
    '可重构性分析': 'ke chong gou xing fen xi',
    '控制律重构': 'kong zhi lv chong gou',
    '长细比': 'chang xi bi',                 # 细长比，chang 非 zhang
    '蛤壳式': 'ge ke shi',                   # 蛤壳式反推，ge 非 ha
    # 「勒」在音译中读 le，pypinyin 一律给 lei —— 这批全是它导致的
    '勒庞': 'le pang',
    '勒夏特列原理': 'le xia te lie yuan li',
    '布加勒斯特': 'bu jia le si te',
    '萨格勒布': 'sa ge le bu',
    '锡林郭勒': 'xi lin guo le',
    '克孜勒苏': 'ke zi le su',
    '阿勒泰': 'a le tai',
    '库尔勒': 'ku er le',
    '俄勒冈': 'e le gang',
    '泰勒公式': 'tai le gong shi',
    '泰勒级数': 'tai le ji shu',
    '克莱斯勒': 'ke lai si le',
    '阿尔勒': 'a er le',          # Arles
    '巴勒莫': 'ba le mo',         # Palermo
    '蒙特勒': 'meng te le',       # Montreux
    '乌得勒支': 'wu de le zhi',   # Utrecht
    '加里宁格勒': 'jia li ning ge le',
    '伏尔加格勒': 'fu er jia ge le',
    '惠斯勒': 'hui si le',        # Whistler
    # 「的」在音译地名中多读 di，pypinyin 一律给轻声 de
    '的黎波里': 'di li bo li',        # Tripoli
    '亚的斯亚贝巴': 'ya di si ya bei ba',  # Addis Ababa
    '的里雅斯特': 'di li ya si te',   # Trieste
    '加的斯': 'jia di si',            # Cadiz
    '蒙得维的亚': 'meng de wei di ya',  # Montevideo
    '的的喀喀湖': 'di di ka ka hu',   # Titicaca
    # 堡在此读 bao 非 pu
    '大堡礁': 'da bao jiao',
    # 漯河（河南）读 Luohe；读 ta 的是山东古漯河
    '漯河': 'luo he',
    # 审计中抓到的 pypinyin 判错
    '重积分': 'chong ji fen',            # 多重积分，chong 非 zhong
    '重排': 'chong pai',                 # 有机化学重排反应
    '潜望式长焦': 'qian wang shi chang jiao',
    '长焦微距': 'chang jiao wei ju',
    '联名调校': 'lian ming tiao jiao',   # 调校 = tiaojiao
    '出厂校色': 'chu chang jiao se',     # 校色 = jiaose
    '半长轴': 'ban chang zhou',          # 轨道半长轴，长 = chang 非 zhang
    '调心球轴承': 'tiao xin qiu zhou cheng',  # 调心 = 自动对中，tiao 非 diao
    # 其它
    '垂直回收': 'chui zhi hui shou', '分度圆': 'fen du yuan',
    '座舱盖': 'zuo cang gai', '缸盖': 'gang gai', '缸垫': 'gang dian',
    '缸体': 'gang ti', '缸径': 'gang jing', '缸内直喷': 'gang nei zhi pen',
    '露帕': 'lu pa', '柔光箱': 'rou guang xiang', '束光筒': 'shu guang tong',
    '中曲台地': 'zhong qu tai di', '苦竹林': 'ku zhu lin',
    '模块': 'mo kuai', '模组': 'mo zu', '模拟领域': 'mo ni ling yu',
    '战术模拟': 'zhan shu mo ni', '机构简图': 'ji gou jian tu',
    '主词条': 'zhu ci tiao', '副词条': 'fu ci tiao',
}


# 一词多读：两种读音都通行的词，两个音都收，按哪个习惯打都能出。
# 值为「额外」读音，主读音仍由 OVERRIDE / pypinyin 决定，别名权重减半。
ALIAS = {
    '薄膜干涉': ['bo mo gan she'],   # 物理书读 bomo，口语常读 baomo
    '薄层色谱': ['bo ceng se pu'],
    '模具': ['mo ju'],               # 正音 muju，但很多人习惯打 moju
    '公差': ['gong chai'],           # 正音 gongcha，防习惯性误打时打不出
    '弹簧': ['dan huang'],
    '重积分': ['zhong ji fen'],
    '调心球轴承': ['diao xin qiu zhou cheng'],
    # 「薄」在专业语境读 bo，口语读 bao，两个都收
    '薄翼理论': ['bo yi li lun'],
    '薄板弯曲': ['bo ban wan qu'],
    '薄壳': ['bo ke'],
    '薄膜应力': ['bo mo ying li'],
}


def to_pinyin(word):
    if word in OVERRIDE:
        return OVERRIDE[word]
    return ' '.join(lazy_pinyin(word, style=Style.NORMAL))


def load_groups():
    groups = {}
    for p in sorted(SRC.glob('*.txt')):
        words, section = [], ''
        for line in p.read_text(encoding='utf-8').splitlines():
            line = line.strip()
            if not line:
                continue
            if line.startswith('##'):
                section = line.lstrip('#').strip()
                continue
            if line.startswith('#'):
                continue
            for w in line.split():
                words.append((w, section))
        groups[p.stem] = words
    return groups


HEADER = """# Rime dictionary
# encoding: utf-8
#
# 个人中文词库
#
# 汽车（含品牌车型） / 机械工程 / 数码电子 / 摄影 / 航空航天
# 数学（含高数） / 物理 / 化学 / 政治人物 / 鸣潮 / 红色警戒2 / 影视人物
#
# 由 src/tools/build_cn_dict.py 生成，请勿手工编辑。
# 增删词条请改 src/tools/cn_terms/*.txt 后重新运行构建。
#
# 拼音由 pypinyin 自动生成，多音字用脚本内的 OVERRIDE 表人工修正。
# 新增词条后建议跑 `python3 src/tools/build_cn_dict.py --audit`
# 检查含多音字的词是否标注正确。
#
---
name: personal
version: "1.0.0"
...
"""

# 常见多音字，用于审计筛选
POLY = set('差行长重调弹模卡曲度载空干处相应中转传数系分和强参露塞校散着量'
           '勒漯朴仇覃single单曾解查华乐燕都藏')


def main():
    groups = load_groups()

    if '--audit' in sys.argv:
        print('含多音字且未在 OVERRIDE 中的词条（请人工确认拼音）：\n')
        n = 0
        for g, words in groups.items():
            hits = [w for w, _ in words if (set(w) & POLY) and w not in OVERRIDE]
            if hits:
                print(f'【{g}】')
                for w in hits:
                    print(f'   {w}\t{to_pinyin(w)}')
                n += len(hits)
        print(f'\n合计 {n} 条待确认')
        return

    total = 0
    dup = 0
    seen = set()   # 跨领域去重：如「弹簧」同时出现在机械工程与汽车表中
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open('w', encoding='utf-8', newline='\n') as f:
        f.write(HEADER)
        for g, words in groups.items():
            f.write(f'\n# ===== {g} =====\n')
            last = None
            for w, section in words:
                py = to_pinyin(w)
                if (w, py) in seen:
                    dup += 1
                    continue
                seen.add((w, py))
                if section != last:
                    f.write(f'# --- {section} ---\n')
                    last = section
                f.write(f'{w}\t{py}\t{WEIGHT}\n')
                total += 1
                for alt in ALIAS.get(w, []):
                    if (w, alt) in seen:
                        continue
                    seen.add((w, alt))
                    # 别名读音权重减半，正音仍排在前
                    f.write(f'{w}\t{alt}\t{WEIGHT // 2}\n')
                    total += 1

    if dup:
        print(f'  跨领域去重      : {dup:5d} 条')
    print(f'  输出 {OUT.relative_to(ROOT)}')
    print(f'  总词条 {total} 条, {OUT.stat().st_size / 1024:.0f} KB')
    for g, words in groups.items():
        print(f'    {g:8s} {len(words):5d}')


if __name__ == '__main__':
    main()
