# Architecture Card：飞书【专家大脑】v0.1

> 设计 DNA 借鉴：[LLM-Wiki](file:///Users/liming/Documents/LLM-Wiki/_schema.md)（4-layer + 6 ontology lens + write-back rule + 8 lint checks + metabolism dashboard）。
> 实测来源：2026-05-12 N=1 dry-run。

## 核心矛盾

| | Obsidian (LLM-Wiki) | 飞书 (专家大脑) |
|---|---|---|
| 写入模型 | 单人 markdown | 多人协作 |
| 存储 | 文件系统 + frontmatter | Bitable 关系字段 + Wiki 节点 |
| 连接 | `[[wikilinks]]` 双向 | Bitable 关联字段 + Wiki @ 提及 |
| 入口 | Obsidian app | 飞书 OpenAPI + 妙记自动转写 |
| 强项 | Dataview / Bases 查询 | 实时协同 + AI 自动化 + 画板 |

**结论**：不能 1:1 镜像。必须做 DNA mapping。

## 三条候选路径（决策记忆）

| 路径 | A. 完全镜像 | **B. 营业窗口（选定）** | C. 平台原生重设 |
|---|---|---|---|
| 关系 | 1:1 复制 | 飞书 = Wiki 协同营业窗口 | 飞书独立 |
| DNA 借鉴度 | 100% | 70% | 30% |
| 风险 | sync 漂移地狱 | 边界清晰 | 丢 4 年 Obsidian 沉淀 |
| 6 轴评分 | 14/30 | **26/30** | 21/30 |

## DNA 借鉴决策表（LLM-Wiki → 飞书）

| LLM-Wiki 要素 | 飞书对应 | 决策 |
|---|---|---|
| Layer 1 sources/ (immutable) | 妙记 + 云盘 + 邮件 + Get笔记 | ✅ 直接搬，只存 URL 引用 |
| Layer 2 entities/concepts/syntheses | Bitable 多表 + 关联字段 | ✅ 搬但改造 |
| Layer 3 insights/ (human only) | 飞书文档 + 评论 | ✅ 保留隔离，AI 永不写 |
| YAML frontmatter | Bitable 字段 | ✅ 改造，语义 100% 保留 |
| `[[wikilinks]]` | Bitable 双向关联 + Wiki @ 提及 | ⚠️ 改造（飞书无 wikilink） |
| 6 ontology lens (MOC) | `lens` 多选字段 | ✅ 直接复用 |
| 代谢引擎 4 循环 | n8n / Coze / lark-cli 流水线 | ✅ 重建 |
| L1-L8 lint | Bitable 视图过滤 + 定时校验 | ✅ 保留 7/8 |
| Write-back rule（跨 3 源 → 自动建页） | AI agent → 自动建 concept 记录 | ✅ 核心机制必须复刻 |
| Marp slides 导出 | 飞书画板 / 妙搭 | ✅ 置换（画板更协同） |

## Sync 边界（B 路径的命脉）

```
LLM-Wiki                          飞书【专家大脑】
─────────                          ──────────────
sources/         主存            ←  只存 URL 引用
concepts (stub/developing)  主存    不存
concepts (mature)  主存          ↔  T01 副本（双向 sync）
synthesis (mature) 主存          ↔  Wiki 文档（双向 sync）
insights/        主存            ✗  永不 sync（人类私有）
dashboard        各自维护         各自维护，不 sync
```

**铁律**：sync 只发生在 `maturity=mature`。stub/developing **一律各自待在原地**。

## 物理结构（飞书侧）

```
飞书【专家大脑】Wiki Space
│
├─ 📂 00-总图 (Wiki 文档)
│   ├─ MOC-总览.docx           ← 6 lens 入口
│   ├─ Schema-定义.docx        ← Bitable 字段规范
│   └─ 代谢仪表盘.docx          ← 嵌入 Bitable dashboard
│
├─ 📂 10-概念库 (Bitable Base)
│   ├─ T01_concepts            主表（对应 LLM-Wiki concepts/）
│   ├─ T02_entities            人/公司/项目（v0 未建，v0.2 加）
│   ├─ T03_syntheses           跨源综合（v0 未建，v0.2 加）
│   └─ T04_sources_ref         源引用（v0 用 T01 的 sources_url 替代）
│
├─ 📂 20-素材源 (引用，不存原文)
│   ├─ 妙记入口（按系列分文件夹）
│   └─ Get笔记/公众号链接库
│
├─ 📂 30-产出 (Wiki 文档 + 画板)
│   ├─ 综合页（mature 后从 T03 promote）
│   ├─ 画板/流程图
│   └─ 公众号草稿
│
└─ 📂 99-Sandbox-<date>  ← 本 skill 默认在此跑，不污染生产
```

## 6 ontology lens（直接沿用 LLM-Wiki）

| Lens id | MOC 中文名 | 适用主题 |
|---|---|---|
| `觉醒` | 原力觉醒 | 心智 / 内修 / 觉知 / 思想线 |
| `创业` | 原力创业 | 创业 / 商业模式 / 飞轮 / 增长 |
| `财富` | 原力财富 | 财富三观 / 资产配置 / 信托 / 传承 |
| `量化` | 量化投资 | 量化策略 / 因子 / KOL 观点 / 宏观 |
| `龙虾` | 原力龙虾 | 龙虾域 / 协作 / 商业应用 |
| `绿皮书` | 绿皮书 / Playbook | 使用攻略 / 操作手册 / 方法论 |

**多 lens 允许**：一个 concept 可属于多个 lens（如「N=1 轻启动」同属 `创业 + 绿皮书`）。

## 代谢循环（飞书侧）

| 循环 | 飞书工具 | v0 状态 |
|---|---|---|
| **摄入** | 妙记自动转写 + Get笔记 ingest | ✅ Step 1+3 实现 |
| **消化** | AI 抽 concept → T01_concepts | ✅ Step 4 实现 |
| **产出** | 综合页 / 画板 / 公众号草稿 | ✅ Step 5 实现（画板已通） |
| **反哺** | 飞书评论 + 互动数据 | ❌ v0 未实现 |

v0 已跑通 3/4 循环。反哺循环留 v0.3。
