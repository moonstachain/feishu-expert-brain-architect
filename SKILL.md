---
name: feishu-expert-brain-architect
description: >
  把会议妙记 / 长会议讨论 / 跨会议系列素材，蒸馏成飞书侧的「专家大脑」知识体系：
  Bitable 概念库 + 飞书文档综合页 + 协同画板。借鉴 LLM-Wiki 的 3 层架构 / 6 lens / 代谢循环
  / write-back 规则，但用飞书原生存储（Bitable 关系字段替代 wikilinks、Wiki 节点替代 folder
  树）。
  当用户说「把会议沉淀成知识库」「专家大脑」「飞书侧知识中枢」「把妙记变成概念卡」
  「borrow LLM-Wiki 思路到飞书」时使用本 skill。
maturity: developing
since: 2026-05-12
last_bump: 2026-05-13
sample_size: N=3
sample_run: 2026-05-13 SP2 N=2 in workstation 5.0 base (2 meetings, 10 new concepts)
upgrade_after: N≥5 + 30 concepts in T08 + ≥5 mature
metadata:
  requires:
    bins: ["lark-cli"]
    skills_optional: ["lark-cli", "lark-minutes", "lark-vc", "lark-base", "lark-doc", "lark-whiteboard", "lark-wiki"]
  cliHelp: "lark-cli --version (must be ≥ 1.0.19)"
---

> 🟡 **v0.2 developing** (bumped 2026-05-13): Architecture pivoted from "B path" (飞书 sandbox 主存储) → "α path" (3-layer: LLM-Wiki 正文 / 工作台 5.0 索引+治理 / 飞书 wiki 协同).
>
> Concept body is NO LONGER in Bitable. Look in `/Users/liming/Documents/LLM-Wiki/concepts/<slug>.md`.
> Sandbox base (`RRRtbWseDaeBaYsn0TYceziJnZc`) is DEPRECATED but kept 30 days for N=1 evidence.
>
> See [docs/spec-v0.2.md](docs/spec-v0.2.md) for full architecture; [docs/plan-v0.2.md](docs/plan-v0.2.md) for implementation; [docs/drift-signals.md](docs/drift-signals.md) for 13 schema drift signals discovered during Phase 1-3.

## 决策树

| 用户场景 | 路径 |
|---|---|
| 第一次为某个飞书 wiki 搭专家大脑（冷启动） | [§ 冷启动流程](#冷启动流程)（5 步全跑） |
| 已建好 sandbox，要再 ingest 一场妙记 | [§ 增量 ingest](#增量-ingest)（只跑 Step 3-5） |
| 想把 sandbox 里 mature 的概念 promote 到生产 wiki | [§ Promote 流程](#promote-流程)（未实现，等 v1） |
| 想把飞书 mature 概念回流到 LLM-Wiki | [§ 与 LLM-Wiki sync](#与-llm-wiki-sync-未实现-等-v1)（未实现，等 v1） |

## Architecture（B-营业窗口路径）

LLM-Wiki = **私有真相源**（Obsidian / markdown / wikilinks / 4-layer）。
飞书【专家大脑】= **协同营业窗口 + 对外暴露层**（Bitable + Wiki + 画板）。

**Sync 边界**：只 sync `maturity=mature`；stub/developing 各自待在原地；insights 永不 sync。

完整设计 + 6 lens 映射 + DNA 取舍表 → [references/architecture-card.md](references/architecture-card.md)

## 冷启动流程

### Pre-flight（必跑）

```bash
lark-cli --version                       # 必须 ≥ 1.0.19
lark-cli auth status | jq '.tokenStatus' # 必须 valid，scope 需含 minutes/wiki/base/whiteboard
echo $HTTPS_PROXY                        # 记下来，第 4 步要 LARK_CLI_NO_PROXY=1 绕开
```

### Step 1：选场次

```bash
lark-cli minutes +search --start <YYYY-MM-DD> --end <YYYY-MM-DD> --format table --page-size 30
```

**N=1 dry-run 原则**：一次只抽 1 场，3-5 个 concept。选场次时避开含**客户/财务/合规**敏感信息的会，优先纯方法论会。

### Step 2：建 sandbox + Bitable

参数化脚本：[scripts/bootstrap_sandbox.sh](scripts/bootstrap_sandbox.sh)

```bash
bash scripts/bootstrap_sandbox.sh <space_id> <parent_node_token> <sandbox_title>
# 输出：sandbox_node_token / bitable_app_token / table_id
```

12 字段 schema 详解 + 字段顺序 + 类型坑 → [references/schema-t01-concepts.md](references/schema-t01-concepts.md)

### Step 3：拉妙记转写

```bash
cd /tmp/expert-brain-<date> && \
lark-cli vc +notes --minute-tokens <minute_token> --output-dir ./transcripts
# transcript.txt 落在 ./transcripts/artifact-<title>-<token>/transcript.txt
```

⚠️ `--output-dir` 必须**相对路径**（详见 [references/pitfalls.md#9](references/pitfalls.md)）。

### Step 4：AI 抽 3-5 个概念卡 → 写 Bitable

**硬约束**：每条 concept body **必须**以 `【原文 <speaker> HH:MM】"..."` 开头，再写 AI 概括。无 quote 即失败。

抽取 prompt 模板 + cell value 格式 → [references/n1-dry-run-playbook.md#step-4](references/n1-dry-run-playbook.md)

```bash
lark-cli base +record-batch-create \
  --base-token <app_token> --table-id <table_id> \
  --json @records.json
```

### Step 5：综合页 + 协同画板

综合页（docx）：

```bash
LARK_CLI_NO_PROXY=1 lark-cli docs +update --api-version v2 \
  --doc <synthesis_obj_token> --command overwrite \
  --doc-format markdown --content @synthesis.md
```

画板（mermaid）：

```bash
# 1. 用 docs +update 在 wrapper docx 插 <whiteboard type="blank"></whiteboard>
# 2. 从响应 new_blocks[].block_token 取 board_token
# 3. 用 whiteboard +update + mermaid 写入
cat graph.mmd | LARK_CLI_NO_PROXY=1 lark-cli whiteboard +update \
  --whiteboard-token <board_token> --source - --input_format mermaid --overwrite --yes
```

### Step 6（验真）：回填 wiki_doc_url + 检查 evidence

```bash
lark-cli base +record-batch-update --base-token <app_token> --table-id <table_id> \
  --json '{"record_id_list":[...],"patch":{"wiki_doc_url":"<synthesis URL>"}}'
```

验真清单（必须 5/5）：
- [ ] 每条 concept body 开头有原文 quote（grep 原文反查）
- [ ] sources_url 字段非空且能跳转到妙记
- [ ] 综合页含 ≥5 个 quote 时间戳
- [ ] 画板 ≥3 节点 + ≥3 边，且能拖动
- [ ] 全部产物在 sandbox 节点下，未污染生产

## 增量 ingest

适用：sandbox/Bitable 已建好，要追加一场妙记。

跳过 Step 2，直接跑 Step 3-5。新概念追加到同一 T01_concepts 表，新综合页作为 sandbox 的子节点。

## 失真护栏

| 护栏 | 来源 | 落地方式 |
|---|---|---|
| **N=1 原则** | dyad-card P7 母题 | 一次只抽 1 场，3-5 概念 |
| **原文 quote 强制** | dry-run 用户拍板 | body 字段开头必带 `【原文 ...】"..."` |
| **sandbox 隔离** | LLM-Wiki "no insights write" 规则 | 全部产物在 `99-Sandbox-<date>` 节点下 |
| **lens 多选** | LLM-Wiki 6 lens 设计 | lens 字段必须 `multiple=true`（坑 1） |
| **代理绕开** | 实测 EOF | docs/whiteboard `+update` 必须 `LARK_CLI_NO_PROXY=1` |
| **N=1 上限** | experimental 状态 | 用户超过 N=3 / 50 概念时，本 skill 必须升 v1 |

完整 9 个 lark-cli 坑 → [references/pitfalls.md](references/pitfalls.md)

## 与 LLM-Wiki sync（未实现，等 v1）

设计已写在 [architecture-card.md#sync-边界](references/architecture-card.md)，但脚本未落地。触发条件：
- T01_concepts 至少 30 行
- 至少 5 行 maturity=mature
- 用户明确说「回流到 LLM-Wiki」

v1 之前手工 sync：人类在 Obsidian 里另写一份 concept 页，参考飞书 wiki_doc_url。

## Promote 流程（未实现，等 v1）

把 sandbox 里 mature 的概念 promote 到对应 lens 主节点下（覺醒/創業/財富/量化/龍蝦/綠皮書）。v1 设计：

1. 按 lens 字段拆分 record 到 6 个 lens 子表（T01_觉醒 / T01_创业 / ...）
2. 综合页从 sandbox 移动到 lens 节点下（`wiki +move`）
3. 标 `promoted_at = today`
4. sandbox 节点保留 30 天后归档

## Sources

本 skill 蒸馏自 2026-05-12 一次 **N=1 dry-run 实战**（一次 33 分钟会议妙记 → 5 张概念卡 + 1 篇综合页 + 1 张协同画板，全链 25 分钟跑通）。

具体产物 URL 含真实 tenant / 文档 token，不对外公开。如需 dry-run 参考样本，请按 [`references/n1-dry-run-playbook.md`](references/n1-dry-run-playbook.md) 在你自己的飞书 tenant 跑一次。

理论框架借鉴：[LLM-Wiki](https://github.com/moonstachain/llm-wiki)（4-layer 架构 / 6 ontology lens / write-back rule / metabolism dashboard）。

## 升级路线

| 版本 | 触发条件 | 加什么 |
|---|---|---|
| **v0.1 (now)** | N=1 实战 | 5 步流水线 + 12 字段 schema + 9 坑 |
| v0.2 | N=2 通过 | 改 schema 漂移点；如发现 lens 不够用，扩 MOC |
| v0.3 | N=3 通过 | 加 Promote 流程；改名为 stable |
| v1.0 | N≥5 + 至少 30 concepts + 至少 5 mature | sync 回流 LLM-Wiki 脚本；删 experimental |
