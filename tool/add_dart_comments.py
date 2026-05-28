#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""为 bazi 项目 Dart 文件添加文件头与类级注释（不修改业务逻辑）。"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def _camel_to_zh(name: str) -> str:
    s = re.sub(r"([a-z])([A-Z])", r"\1 \2", name)
    return s.replace("_", " ").strip() or name


def describe_file(rel: str, stem: str) -> tuple[str, list[str]]:
    if rel.startswith("test/"):
        topic = stem.replace("_test", "").replace("_", " ")
        return (
            f"测试：{topic}",
            [
                f"验证 {topic} 相关逻辑、边界与回归场景。",
                "修改对应实现时请同步更新本测试。",
            ],
        )

    if stem == "main":
        return ("应用入口", ["初始化 Flutter 绑定、加载配置并启动根 Widget。"])

    layer = ""
    if rel.startswith("lib/app/"):
        layer = "应用壳层"
    elif rel.startswith("lib/core/"):
        layer = "核心公共模块"
    elif rel.startswith("lib/domain/"):
        layer = "领域层"
    elif rel.startswith("lib/infrastructure/"):
        layer = "基础设施层"
    elif rel.startswith("lib/features/"):
        parts = rel.split("/")
        feat = parts[2] if len(parts) > 2 else "feature"
        feat_map = {
            "ai_chat": "AI 看盘对话",
            "auth": "账号认证",
            "chart": "命盘图表展示",
            "collection": "命盘合集",
            "history": "命主与历史记录",
            "input": "生辰录入",
            "result": "排盘结果页",
            "reverse_lookup": "四柱反查",
        }
        layer = feat_map.get(feat, feat)

    kind = ""
    if stem.endswith("_page"):
        kind = "页面 UI"
    elif stem.endswith("_controller"):
        kind = "状态控制器"
    elif "provider" in stem.lower():
        kind = "Riverpod 数据提供"
    elif "repository" in stem.lower():
        kind = "数据仓库"
    elif stem.endswith("_usecase"):
        kind = "用例编排"
    elif "/entities/" in rel or "/value_objects/" in rel:
        kind = "领域模型"
    elif "/widgets/" in rel:
        kind = "可复用组件"
    elif "/application/" in rel and rel.startswith("lib/features"):
        kind = "应用层逻辑"
    elif "/calendar/" in rel:
        kind = "历法与排盘算法"
    elif "/database/" in rel:
        kind = "数据库访问"
    elif "/theme/" in rel:
        kind = "主题样式"

    title = f"{layer} — {_camel_to_zh(stem)}" if layer else _camel_to_zh(stem)
    details: list[str] = []
    if kind:
        details.append(f"本文件属于{kind}。")
    details.append(f"路径：`{rel}`。")
    if stem.endswith("_page"):
        details.append("负责界面布局、用户交互与导航。")
    elif stem.endswith("_controller"):
        details.append("管理状态、调用用例/仓库并驱动 UI 刷新。")
    elif "/entities/" in rel:
        details.append("定义业务数据结构，供各层传递与序列化。")
    elif "/calendar/" in rel:
        details.append("实现八字历法计算、节气、大运等核心算法。")
    elif "/widgets/" in rel:
        details.append("封装 UI 片段，供页面或其它组件组合使用。")

    return title, details


def has_file_doc(content: str) -> bool:
    head = "\n".join(content.lstrip().splitlines()[:6])
    return "/// 文件：" in head or "/// 文件:" in head


def build_file_header(rel: str, stem: str) -> str:
    title, details = describe_file(rel, stem)
    out = [f"/// 文件：{title}", "///"]
    for d in details:
        out.append(f"/// {d}")
    out.append("///")
    return "\n".join(out) + "\n\n"


def class_comment(kind: str, name: str) -> str:
    if kind == "enum":
        return f"/// 枚举 `{name}`：{_camel_to_zh(name)} 的取值集合。"
    if kind == "mixin":
        return f"/// Mixin `{name}`：复用 {_camel_to_zh(name)} 相关能力。"
    if kind == "extension":
        return f"/// 扩展 `{name}`：为类型增加 {_camel_to_zh(name)} 方法。"
    if name.startswith("_"):
        return f"/// 私有类 `{name}`：{_camel_to_zh(name.lstrip('_'))}。"
    return f"/// 类 `{name}`：实现 {_camel_to_zh(name)} 相关逻辑。"


def process_content(rel: str, content: str) -> str:
    lines = content.splitlines(keepends=True)
    result: list[str] = []
    i = 0

    if not has_file_doc(content):
        while i < len(lines) and lines[i].strip().startswith(
            ("// ignore", "// @dart", "library ", "part ")
        ):
            result.append(lines[i])
            i += 1
        result.append(build_file_header(rel, Path(rel).stem))

    class_re = re.compile(r"^(\s*)(class|enum|mixin|extension)\s+(\w+)")

    while i < len(lines):
        line = lines[i]
        m = class_re.match(line.rstrip("\n"))
        if m:
            indent, kind, name = m.group(1), m.group(2), m.group(3)
            prev = result[-1].rstrip() if result else ""
            if not prev.endswith("*/") and "///" not in prev:
                result.append(f"{indent}{class_comment(kind, name)}\n")
        result.append(line)
        i += 1

    return "".join(result)


def main() -> None:
    count = 0
    for path in sorted(ROOT.rglob("*.dart")):
        if not path.is_relative_to(ROOT):
            continue
        rel = path.relative_to(ROOT).as_posix()
        if not rel.startswith(("lib/", "test/")):
            continue
        original = path.read_text(encoding="utf-8")
        updated = process_content(rel, original)
        if updated != original:
            path.write_text(updated, encoding="utf-8")
            count += 1
    print(f"updated {count} files")


if __name__ == "__main__":
    main()
