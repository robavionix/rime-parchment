"""在原项目内同步公开版、个人版及三套皮肤的完整发布包。

先执行 build-rime.sh（ios 与 android），再运行：
python src/tools/package_release.py --public 5.2 --personal 10.3 --previous 10.2
需要 PyYAML。个人词库和语言模型保留原文件；归档校验通过后才替换旧包。
"""
import argparse
import hashlib
import re
import shutil
import sys
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from check_skin_config import check, check_source, read

ROOT = Path(__file__).resolve().parents[2]
SKINS = ("parchment-skin", "doraemon-pocket", "winnie-honeypot")


def version(value):
    if not re.fullmatch(r"\d+\.\d+(?:\.\d+)?", value):
        raise argparse.ArgumentTypeError("版本号格式应为 5.2 或 10.3")
    return value


def text(path, content):
    path.write_text(content, encoding="utf-8", newline="\n")


def archive(folder, target, prefix="", release=None, release_name="RELEASE.md"):
    temporary = target.with_suffix(".zip.tmp")
    files = {prefix + p.relative_to(folder).as_posix(): p for p in folder.rglob("*")
             if p.is_file() and "__pycache__" not in p.parts}
    with ZipFile(temporary, "w", ZIP_DEFLATED) as out:
        for name, path in sorted(files.items()):
            if release is None or name != prefix + release_name:
                out.write(path, name)
        if release is not None:
            out.writestr(prefix + release_name, release)
    # 验证每个文件的实际字节，不只检查 zip 能否打开。
    with ZipFile(temporary) as zipped:
        assert zipped.testzip() is None, f"损坏的压缩包 {temporary}"
        for name, path in files.items():
            if release is None or name != prefix + release_name:
                assert hashlib.sha256(zipped.read(name)).digest() == hashlib.sha256(path.read_bytes()).digest(), name
    temporary.replace(target)
    print(f"PACK {target.relative_to(ROOT)} ({len(files)} files)")


def current_path(parent, stem, new, old):
    target = parent / f"{stem}-V{new}"
    previous = parent / f"{stem}-V{old}"
    assert target.is_dir() or previous.is_dir(), f"缺少个人版目录 {previous}"
    assert not (target.is_dir() and previous.is_dir() and target != previous), f"新旧目录同时存在，请先检查 {target}"
    return target if target.is_dir() else previous


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--public", required=True, type=version)
    parser.add_argument("--personal", required=True, type=version)
    parser.add_argument("--previous", required=True, type=version)
    args = parser.parse_args()
    pub, personal, old = args.public, args.personal, args.previous
    private = current_path(ROOT / "test/rime", "rime-config", personal, old)
    skins = [(stem, current_path(ROOT / "test", stem, personal, old)) for stem in SKINS]
    for directory in (ROOT / "dist/rime", ROOT / "dist/rime-android", private):
        assert (directory / "melt_eng.schema.yaml").is_file(), f"缺少构建目录 {directory}"
    # 禁止源码已改但 dist 尚未构建时打出旧包。
    shared = [(ROOT / "src/patches" / name, name) for name in
              ("default.custom.yaml", "melt_eng.custom.yaml")]
    shared += [(source, "lua/" + source.name) for source in (ROOT / "src/lua").glob("*.lua")]
    shared += [(ROOT / "src/en_dicts/en_merged.dict.yaml", "en_dicts/en_merged.dict.yaml"),
               (ROOT / "src/melt_eng.dict.yaml", "melt_eng.dict.yaml"),
               (ROOT / "src/custom_phrase.txt", "custom_phrase.txt")]
    for directory in (ROOT / "dist/rime", ROOT / "dist/rime-android"):
        for source, relative in shared:
            assert (directory / relative).read_bytes() == source.read_bytes(), f"产物落后于源码，请重新构建：{directory / relative}"
        for schema in ("rime_ice", "melt_eng"):
            actual = read(directory / f"{schema}.custom.yaml")["patch"].get("schema/version")
            assert actual == pub, f"公开版号不一致：{schema} 为 {actual}，打包参数为 {pub}"
    for _, directory in skins:
        assert len(list(directory.glob("*/config.yaml"))) == 1, directory
        skin = next(directory.glob("*/config.yaml")).parent
        check_source(skin)
        check(ROOT / "dist/rime", skin)
    # 保存所有个人词库和语言模型的指纹，后续只同步公共英文组件。
    protected = {p.relative_to(private): hashlib.sha256(p.read_bytes()).digest()
                 for p in list((private / "cn_dicts").glob("*")) + list(private.glob("*.gram")) if p.is_file()}
    english = (ROOT / "src/patches/melt_eng.custom.yaml").read_text(encoding="utf-8")
    english = re.sub(r'(?m)^  schema/version:.*$', f'  schema/version: "{personal}"', english)
    text(private / "melt_eng.custom.yaml", english)
    for source in (ROOT / "src/lua").glob("*.lua"):
        shutil.copyfile(source, private / "lua" / source.name)
    patch = private / "rime_ice.custom.yaml"
    content = patch.read_text(encoding="utf-8")
    content = re.sub(r'(?m)^  schema/version:.*\n', '', content)
    content = content.replace("patch:\n", f'patch:\n  schema/version: "{personal}"\n', 1)
    if "lua_filter@*en_auto_space_filter" not in content:
        marker = "    - uniquifier"
        assert content.count(marker) == 1, "无法定位个人版滤镜列表"
        content = content.replace(marker, "    - lua_filter@*en_auto_space_filter\n" + marker)
        content += "\n  # 连续英文词之间补空格，保持中文及标点行为。\n  engine/processors/@before 1: lua_processor@*en_auto_space_processor\n  en_auto_space/timeout: 10\n"
    content = content.replace(f"test/V{old}说明.md", f"test/V{personal}说明.md")
    text(patch, content)
    for relative, digest in protected.items():
        assert hashlib.sha256((private / relative).read_bytes()).digest() == digest, relative
    private_target = ROOT / "test/rime" / f"rime-config-V{personal}"
    # 所有重命名均限定在已确认的项目目录内。
    assert private.resolve().is_relative_to(ROOT / "test/rime")
    if private != private_target:
        private.rename(private_target)
    private = private_target
    release = f"# V{personal} 个人版 / 公开版 {pub}\n\n纯英文空格选词、点选候选及回车上屏后立即补一个尾空格；混打英文词之间补空格。\n同时覆盖 C++、.NET、3D 等技术词。三套皮肤与本版配置一起更新；布局、键位、配色和方案切换保持原样。\n个人词库和语言模型保持原文件。接英文标点前可退格去掉尾空格。\n安装本目录 Rime 完整包及任选一套同版本皮肤，然后重新部署。\n"
    text(private / "RELEASE.md", release)
    for stem, directory in skins:
        target = ROOT / "test" / f"{stem}-V{personal}"
        assert directory.resolve().is_relative_to(ROOT / "test")
        if directory != target:
            directory.rename(target)
        skin = next(target.glob("*/config.yaml")).parent
        check(private, skin)
        check(ROOT / "dist/rime", skin)
        text(skin / "RELEASE.md", release)
        archive(target, ROOT / "test" / f"{stem}-V{personal}.zip")
        public_release = f"# V{pub} 公开版配套皮肤\n\n配套公开版 rime-config-V{pub}.zip。保持原有布局、键位、配色及方案绑定。\n安装本皮肤及同版本 Rime 配置后重新部署。\n"
        archive(target, ROOT / "dist" / f"{stem}-V{pub}.zip", release=public_release, release_name=skin.name + "/RELEASE.md")
        if old != personal:
            (ROOT / "test" / f"{stem}-V{old}.zip").unlink(missing_ok=True)
    archive(private, ROOT / "test/rime" / f"rime-config-V{personal}.zip")
    if old != personal:
        (ROOT / "test/rime" / f"rime-config-V{old}.zip").unlink(missing_ok=True)
    for kind in ("rime", "rime-android"):
        directory = ROOT / "dist" / kind
        text(directory / "RELEASE.md", f"# 公开版 {pub}\n\n配套三套 V{pub} 皮肤；纯英文自动尾空格修复。\n")
        name = "rime-config" if kind == "rime" else kind
        archive(directory, ROOT / "dist" / f"{name}-V{pub}.zip")
    old_doc = ROOT / "test" / f"V{old}说明.md"
    new_doc = ROOT / "test" / f"V{personal}说明.md"
    if old_doc != new_doc and old_doc.is_file():
        history = old_doc.read_text(encoding="utf-8")
        text(new_doc, release + "\n本版四个完整包：\n\n" + "\n".join(
            [f"- rime/rime-config-V{personal}.zip"] + [f"- {stem}-V{personal}.zip" for stem in SKINS])
            + f"\n\n以下保留 V{old} 的历史说明；其中旧版本安装路径仅供回顾。\n\n---\n\n" + history)
        old_doc.unlink()
    elif new_doc.is_file():
        existing = new_doc.read_text(encoding="utf-8")
        marker = "本版四个完整包："
        if marker in existing:
            text(new_doc, release + "\n" + marker + existing.split(marker, 1)[1])


if __name__ == "__main__":
    main()
