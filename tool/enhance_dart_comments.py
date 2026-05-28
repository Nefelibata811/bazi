#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""用更贴切的中文重写文件头，并为关键方法补充实现说明注释。"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# 词块 → 中文（用于自动生成文件名说明）
WORDS = {
    "ai": "AI",
    "api": "API",
    "app": "应用",
    "auth": "认证",
    "bazi": "八字",
    "birth": "出生",
    "bootstrap": "启动引导",
    "calendar": "历法",
    "chart": "命盘",
    "chat": "对话",
    "china": "中国",
    "collection": "合集",
    "controller": "控制器",
    "converter": "转换",
    "core": "核心",
    "cycle": "运程",
    "database": "数据库",
    "deepseek": "DeepSeek",
    "display": "展示",
    "element": "五行",
    "encoder": "编解码",
    "engine": "引擎",
    "entities": "实体",
    "extra": "辅",
    "five": "五",
    "follow": "追问",
    "formatted": "格式化",
    "four": "四",
    "gan": "干",
    "gender": "性别",
    "generator": "生成器",
    "geo": "地理",
    "hidden": "藏干",
    "history": "历史",
    "home": "首页",
    "input": "录入",
    "interaction": "刑冲合害",
    "julian": "儒略",
    "label": "标签",
    "local": "本地",
    "login": "登录",
    "luck": "大运",
    "lunar": "农历",
    "mapper": "映射",
    "messages": "文案",
    "page": "页面",
    "pattern": "格局",
    "picker": "选择器",
    "pillar": "柱",
    "pillars": "柱",
    "place": "地点",
    "places": "地点",
    "profile": "个人资料",
    "provider": "提供者",
    "record": "记录",
    "records": "记录",
    "register": "注册",
    "ren": "人元",
    "report": "报告",
    "repository": "仓库",
    "request": "请求",
    "reset": "重置",
    "result": "结果",
    "reverse": "反查",
    "rule": "规则",
    "save": "保存",
    "secrets": "密钥",
    "session": "会话",
    "shensha": "神煞",
    "si": "司",
    "solar": "公历",
    "splash": "启动页",
    "streaming": "流式",
    "strings": "文案",
    "supabase": "Supabase",
    "term": "节气",
    "theme": "主题",
    "timeline": "时间轴",
    "true": "真",
    "typewriter": "打字机",
    "usecase": "用例",
    "useful": "用神",
    "user": "用户",
    "value": "值",
    "widgets": "组件",
    "yin": "阴",
    "yuan": "元",
    "zhi": "支",
}

# 文件名 → (标题, 说明行)
OVERRIDES: dict[str, tuple[str, list[str]]] = {
    "record_picker_sheet": (
        "AI 看盘 — 选盘底部弹窗",
        [
            "供用户在对话前选择已保存的命盘。",
            "支持「全部命盘 / 命盘合集」；合集内二级浏览命盘列表。",
            "弹窗高度固定；系统返回在合集内先退回合集列表。",
        ],
    ),
    "chat_page": (
        "AI 看盘 — 对话主页面",
        [
            "展示选中的命盘上下文与 AI 分析对话。",
            "处理选盘、流式回复、清空对话与返回键逻辑。",
        ],
    ),
    "app": (
        "应用根路由与主壳",
        [
            "登录态路由、底部 Tab（主页 / AI 看盘）、全局返回键分级处理。",
            "预加载命盘列表与合集；IndexedStack 保持 Tab 状态。",
        ],
    ),
    "main": (
        "应用入口",
        ["初始化 Flutter、全局错误捕获，挂载 Riverpod 与 BootstrapApp。"],
    ),
    "collection_page": (
        "命盘合集 — 列表与详情页",
        ["创建/重命名/删除合集；向合集添加或移除已保存命盘。"],
    ),
    "people_list_page": (
        "主页 — 命主列表",
        ["展示已保存命主；支持搜索、删除、进入排盘与 AI 看盘。"],
    ),
    "bazi_input_controller": (
        "生辰录入 — 状态控制器",
        [
            "管理公历/农历、出生时刻、出生地、真太阳时与排盘 sect。",
            "农历变更时同步公历；触发排盘并缓存 BaziReport。",
        ],
    ),
    "interaction_calculator": (
        "刑冲合害计算器",
        [
            "基于四柱干支计算合、冲、刑、害等关系。",
            "仅使用主四柱（chart.pillars），辅宫不参与计算。",
        ],
    ),
}

METHOD_HINTS = {
    "initState": "初始化：注册首帧回调、预加载列表数据。",
    "build": "构建界面布局。",
    "dispose": "释放监听器与控制器资源。",
    "ensureLoaded": "确保列表已加载；有缓存时可静默刷新。",
    "refresh": "重新从网络拉取并更新状态。",
    "_bootstrap": "首次加载：优先读本地缓存，再请求网络。",
    "_retryLoad": "用户点击重试时重新加载当前视图数据。",
    "_maybeSavePendingChart": "若从排盘页跳转而来，自动保存当前命盘供 AI 选用。",
    "_openCollection": "进入某个合集内的命盘列表。",
    "_backToCollections": "从合集内返回到合集列表。",
    "_showRecordPicker": "打开选盘底部弹窗。",
    "_onSelectRecord": "选中命盘后更新状态并可选开始分析。",
    "_buildBody": "根据当前 Tab/合集层级渲染列表主体。",
    "main": "测试入口：注册用例分组。",
}


def humanize_stem(stem: str) -> str:
    if stem in OVERRIDES:
        return OVERRIDES[stem][0]
    parts = stem.replace("_test", "").split("_")
    zh_parts = [WORDS.get(p, p) for p in parts]
    return "".join(zh_parts)


def describe(stem: str, rel: str) -> tuple[str, list[str]]:
    if stem in OVERRIDES:
        return OVERRIDES[stem]
    if rel.startswith("test/"):
        topic = humanize_stem(stem)
        return (
            f"单元测试 — {topic}",
            [f"验证 {topic} 的正确性与边界情况。", "修改实现时请同步维护本测试。"],
        )
    title = humanize_stem(stem)
    details = [f"路径：`{rel}`。"]
    if stem.endswith("_page"):
        details.insert(0, "页面：负责 UI 展示与用户操作。")
    elif stem.endswith("_controller"):
        details.insert(0, "控制器：管理状态并协调数据层。")
    elif "/calendar/" in rel:
        details.insert(0, "历法算法：八字排盘核心计算。")
    elif "/entities/" in rel:
        details.insert(0, "领域实体：承载业务数据字段。")
    elif "/widgets/" in rel:
        details.insert(0, "UI 组件：可复用的界面片段。")
    return title, details


def build_header(rel: str, stem: str) -> str:
    title, details = describe(stem, rel)
    lines = [f"/// 文件：{title}", "///", *[f"/// {d}" for d in details], "///", ""]
    return "\n".join(lines)


def replace_header(content: str, rel: str) -> str:
    stem = Path(rel).stem
    new_header = build_header(rel, stem)
    # 去掉旧文件头（/// 文件： 或 连续 // 说明）
    lines = content.splitlines(keepends=True)
    i = 0
    while i < len(lines) and lines[i].strip().startswith(
        ("// ignore", "// @dart", "library ", "part ")
    ):
        i += 1
    if i < len(lines) and lines[i].startswith("/// 文件："):
        while i < len(lines) and (
            lines[i].startswith("///") or lines[i].strip() == ""
        ):
            i += 1
    elif i < len(lines) and lines[i].startswith("//"):
        while i < len(lines) and lines[i].startswith("//"):
            i += 1
        if i < len(lines) and lines[i].strip() == "":
            i += 1
    return "".join(lines[:i]) + new_header + "".join(lines[i:])


def add_method_comments(content: str) -> str:
    lines = content.splitlines(keepends=True)
    out: list[str] = []
    method_re = re.compile(
        r"^(\s+)(?:@\w+\([^)]*\)\s*)*(?:static\s+)?(?:Future<[^>]+>|void|Widget|bool|int|String|double|List<[^>]+>|[\w?]+)\s+(\w+)\s*\("
    )
    for i, line in enumerate(lines):
        m = method_re.match(line.rstrip("\n"))
        if m:
            name = m.group(2)
            indent = m.group(1)
            hint = METHOD_HINTS.get(name)
            if hint:
                prev = out[-1] if out else ""
                if not prev.strip().startswith("//") and "///" not in prev:
                    out.append(f"{indent}// {hint}\n")
        out.append(line)
    return "".join(out)


def main() -> None:
    n = 0
    for path in sorted(ROOT.rglob("*.dart")):
        rel = path.relative_to(ROOT).as_posix()
        if not rel.startswith(("lib/", "test/")):
            continue
        text = path.read_text(encoding="utf-8")
        updated = replace_header(text, rel)
        updated = add_method_comments(updated)
        if updated != text:
            path.write_text(updated, encoding="utf-8")
            n += 1
    print(f"enhanced {n} files")


if __name__ == "__main__":
    main()
