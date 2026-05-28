#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""将文件顶部的 /// 文件说明 转为 //，避免 dangling_library_doc_comments。"""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def convert(content: str) -> str:
    lines = content.splitlines(keepends=True)
    i = 0
    while i < len(lines) and lines[i].strip().startswith(
        ("// ignore", "// @dart", "library ", "part ")
    ):
        i += 1
    if i >= len(lines) or not lines[i].startswith("/// 文件："):
        return content

    while i < len(lines) and (lines[i].startswith("///") or lines[i].strip() == ""):
        line = lines[i]
        if line.startswith("///"):
            lines[i] = "//" + line[3:]
        i += 1
    return "".join(lines)


def main() -> None:
    n = 0
    for path in ROOT.rglob("*.dart"):
        rel = path.relative_to(ROOT).as_posix()
        if not rel.startswith(("lib/", "test/")):
            continue
        text = path.read_text(encoding="utf-8")
        updated = convert(text)
        if updated != text:
            path.write_text(updated, encoding="utf-8")
            n += 1
    print(f"converted {n} files")


if __name__ == "__main__":
    main()
