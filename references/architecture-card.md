# Architecture Card (v0.2 — α 3-layer)

> **v0.1 was B path** (飞书 sandbox 主存储 + 协同). Deprecated 2026-05-13.
> **v0.2 is α path** (LLM-Wiki 正文 / 工作台 5.0 索引 / 飞书 wiki 协同). Single truth source = LLM-Wiki.

## 3 Layers (with hard boundaries)

```
┌─ Layer 0: LLM-Wiki (Obsidian)           真相源 / concept body 主存储
│   • /Users/liming/Documents/LLM-Wiki/concepts/<slug>.md
│   • frontmatter: title / type / sources / related / ontology_lens / tags / maintainer / last_reviewed
│   • body: 原文 quote (强制) + AI 概括 + 相关概念 (wikilinks) + 出处
│   ↑ wiki_path 字段从 Layer 1 指向
│
┌─ Layer 1: 飞书原力 OS 工作台 5.0 base     索引 / 治理 / 驾驶舱
│   base_token: <your_workstation_5_base>
│   • T00-T15 (governance/clones/governance objects/etc — pre-existing, don't touch)
│   • T08_知识概念索引                       concept 索引行，wiki_path 指 Layer 0
│   • T16_meeting_inventory                  妙记元数据索引（新建 by 本 skill）
│   • SP5 dashboard "随身企业大脑驾驶舱"
│
┌─ Layer 2: 飞书【专家大脑】wiki space         协同入口（synthesis + 画板）
│   • 30-产出/synthesis-<topic>-<date>.docx
│   • 30-产出/whiteboard-<topic>             协同画板
│   • 不存 concept 主体
│
└─ Layer X: sandbox（deprecated 2026-06-12 删）
```

## Layer Boundaries (Iron Law)

| 内容 | Layer 0 | Layer 1 | Layer 2 |
|---|---|---|---|
| Concept 正文 (body) | ✅ 唯一 | ❌ | ❌ |
| Concept 索引 (title/slug/category) | ❌ | ✅ T08 | ❌ |
| 妙记元数据 (title/duration/keywords) | ❌ | ✅ T16 | ❌ |
| 妙记转写 (transcript.txt) | ✅ sources/feishu/ | ❌ | ❌ |
| Synthesis 综合页 | ⚪ (mature only) syntheses/ | ❌ | ✅ docx |
| 协同画板 | ❌ | ❌ | ✅ |

## v0.1 → v0.2 Migration

If you're holding v0.1 sandbox: see `docs/spec-v0.2.md §6` for 6-step migration. Don't re-migrate if you're starting fresh.

## 6 Ontology Lenses (unchanged from v0.1)

Direct re-use of LLM-Wiki canonical lenses:
- yuanli-juexing / yuanli-chuangye / yuanli-caifu / lianghua-touzi / yuanli-longxia / greenbook

Lens validation rules:
- `moc-greenbook` is RESERVED for `concepts/playbook-*` (操作手册/使用攻略). Don't put startup philosophy here — use `moc-yuanli-chuangye`.
