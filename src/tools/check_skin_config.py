"""校验皮肤配置文件、键盘切换与 Rime 方案是否配套。需要 PyYAML。

python src/tools/check_skin_config.py <rime目录> <皮肤目录> [<皮肤目录> ...]
皮肤目录必须直接包含 config.yaml、light/、dark/。
"""
import sys
import subprocess
import tempfile
from pathlib import Path

import yaml


def read(path):
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def walk(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def check_source(skin):
    """确认手机重新运行 main.jsonnet 后不会恢复成另一份配置。"""
    executable = Path(__file__).resolve().parents[2] / "tools/jsonnet.exe"
    with tempfile.TemporaryDirectory(prefix="rime-skin-check-") as temporary:
        output = Path(temporary)
        for theme in ("light", "dark"):
            (output / theme).mkdir()
        subprocess.run([str(executable), "-S", "-m", str(output), "--tla-code", "debug=true",
                        str(skin / "jsonnet/main.jsonnet")], check=True, stdout=subprocess.DEVNULL)
        generated = list(output.rglob("*.yaml"))
        assert generated, f"{skin}: 未生成皮肤配置"
        for path in generated:
            actual = skin / path.relative_to(output)
            assert actual.is_file() and read(path) == read(actual), f"源码和已编译皮肤不一致：{actual}"
    print(f"PASS {skin.name}: Jsonnet 源码与已编译配置一致")


def check(rime, skin):
    schemas = {x["schema"] for x in read(rime / "default.custom.yaml")["patch"]["schema_list"]}
    assert {"rime_ice", "melt_eng"} <= schemas, "缺少中文或纯英文方案"
    for schema in schemas:
        assert (rime / f"{schema}.schema.yaml").is_file(), f"缺少方案 {schema}"
    config = read(skin / "config.yaml")
    assert {"english", "pinyin", "pinyin9"} <= config.keys(), "缺少三套键盘映射"
    count = 0
    for keyboard, platforms in config.items():
        layouts = {name for platform in platforms.values() for name in platform.values()}
        for name in layouts:
            for theme in ("light", "dark"):
                path = skin / theme / (name + ".yaml")
                data = read(path)
                for node in walk(data):
                    if "Cell" in node:
                        assert node["Cell"] in data, f"{path}: 缺少 Cell {node['Cell']}"
                    if "switchRimeSchema" in node:
                        assert node["switchRimeSchema"] in schemas, f"{path}: 未安装的方案 {node}"
                    if "combine" in node:
                        actions = node["combine"]
                        targets = [x["keyboardType"] for x in actions if "keyboardType" in x]
                        switches = [x["switchRimeSchema"] for x in actions if "switchRimeSchema" in x]
                        for target in targets:
                            if target in ("english", "pinyin", "pinyin9"):
                                expected = "melt_eng" if target == "english" else "rime_ice"
                                assert switches == [expected], f"{path}: 键盘与方案错配 {node}"
                if keyboard in ("english", "pinyin", "pinyin9"):
                    # 三套键盘应当两两直达，检查可见布局实际引用的按钮。
                    cells = {n["Cell"] for n in walk(data["keyboardLayout"]) if "Cell" in n}
                    targets = set()
                    for cell in cells:
                        for node in walk(data[cell].get("action", {})):
                            if "keyboardType" in node:
                                targets.add(node["keyboardType"])
                    assert ({"english", "pinyin", "pinyin9"} - {keyboard}) <= targets, f"{path}: 缺少直达切换键"
                if keyboard == "english":
                    for letter in "abcdefghijklmnopqrstuvwxyz":
                        action = data[letter + "Button"]["action"]
                        assert action == {"character": letter}, f"{path}: 英文字母绕过 Rime {action}"
                    assert data["spaceButton"]["action"] == "space", f"{path}: 空格动作异常"
                count += 1
    print(f"PASS {skin.name}: {count} 个布局，配置映射、Cell 引用、方案绑定、两两切换和英文字母路径一致")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    for path in sys.argv[2:]:
        check(Path(sys.argv[1]), Path(path))
