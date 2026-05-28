#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""去除重复「// 文件：」文件头，保留最后一段说明。"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

FILE_MARK = re.compile(r"^// 文件：", re.MULTILINE)
IMPORT_MARK = re.compile(r"^(import |export |part |library )", re.MULTILINE)


def dedupe(content: str) -> str:
    matches = list(FILE_MARK.finditer(content))
    if len(matches) <= 1:
        return content

    last = matches[-1].start()
    # 保留 last 之前的 ignore 等前缀
    prefix_end = matches[0].start()
    prefix = content[:prefix_end]

    # 从 last 到第一个 import
    rest = content[last:]
    m_import = IMPORT_MARK.search(rest)
    header_end = m_import.start() if m_import else len(rest)
    header = rest[:header_end]
    body = rest[header_end:]
    return prefix + header + body


def main() -> None:
    n = 0
    for path in sorted(ROOT.rglob("*.dart")):
        rel = path.relative_to(ROOT).as_posix()
        if not rel.startswith(("lib/", "test/")):
            continue
        text = path.read_text(encoding="utf-8")
        updated = dedupe(text)
        if updated != text:
            path.write_text(updated, encoding="utf-8")
            n += 1
    print(f"deduped {n} files")


if __name__ == "__main__":
    main()
