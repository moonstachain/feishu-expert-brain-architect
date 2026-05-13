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

## Architecture（α 3-layer，v0.2）

- **Layer 0** — LLM-Wiki (Obsidian): concept body 唯一主存储；`concepts/<slug>.md`
- **Layer 1** — 飞书原力 OS 工作台 5.0 base: 索引 + 治理 + 驾驶舱（T08 知识概念索引 / T16 妙记元数据索引 / SP5 dashboard）
- **Layer 2** — 飞书【专家大脑】wiki space: 协同入口（synthesis docx + 协同画板，挂在「30-产出」节点下）

**Sync 边界**：concept body **只**在 Layer 0；Layer 1 T08 wiki_path 指向 Layer 0；mature 概念可写 syntheses/ 在 Layer 0。Insights 永不 sync。

完整设计 + 6 lens 映射 + 边界铁律 → [references/architecture-card.md](references/architecture-card.md)

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

### Step 2：抽取一场会议（α-path）

参数化脚本：[scripts/extract_one_meeting.sh](scripts/extract_one_meeting.sh)

```bash
bash scripts/extract_one_meeting.sh \
  <minute_token> <workstation_base_token> \
  <t08_table_id> <t16_table_id> <t16_record_id> \
  <expert_brain_space_id> <prod_node_token>
# 输出：transcript path + extraction_context.json（喂给 Claude 继续抽取）
```

> v0.1 用的 `scripts/bootstrap_sandbox.sh` 已 DEPRECATED（运行时显警告）。新流程不再建 sandbox，直接写工作台 5.0 base。

T08（12 字段）+ T16（9 字段）schema 详解 → [references/schema-t08-concept-index.md](references/schema-t08-concept-index.md)

### Step 3：拉妙记转写

```bash
cd /tmp/expert-brain-<date> && \
lark-cli vc +notes --minute-tokens <minute_token> --output-dir ./transcripts
# transcript.txt 落在 ./transcripts/artifact-<title>-<token>/transcript.txt
```

⚠️ `--output-dir` 必须**相对路径**（详见 [references/pitfalls.md#9](references/pitfalls.md)）。

### Step 4：AI 抽 3-5 个概念卡 → 写 LLM-Wiki + T08 索引

**硬约束**：每条 concept body **必须**以 `## 原文 quote` section + `> 「<quote>」—— <speaker> @ HH:MM` 开头。无 quote 即失败。

抽取 prompt 模板 + 8 步流水线 + cell value 格式 → [references/extraction-playbook.md](references/extraction-playbook.md)

```bash
# 1. cd LLM-Wiki, write concepts/<slug>.md per concept
cd /Users/liming/Documents/LLM-Wiki && # ... Write markdown

# 2. write T08 index rows (fields-in-order, NOT array-of-objects)
lark-cli base +record-batch-create \
  --base-token <workstation_base_token> --table-id <t08_table_id> \
  --json @t08_rows.json
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

适用：工作台 5.0 base 已迁移完成（T08 + T16 已存在），要追加一场新妙记。

直接跑 [extraction-playbook.md](references/extraction-playbook.md) 的 Step 1-8。新 concept 正文写到 LLM-Wiki `concepts/`，新 T08 索引行追加到工作台 5.0 base，新综合页 docx + 协同画板挂到飞书【专家大脑】wiki 的「30-产出」节点下。

## 失真护栏

| 护栏 | 来源 | 落地方式 |
|---|---|---|
| **N=1 抽取原则** | dyad-card P7 母题 | 一次只抽 1 场，3-5 概念；不批量 |
| **原文 quote 强制** | dry-run + Phase 2 用户拍板 | body 必含 `## 原文 quote` + `> 「...」—— <speaker> @ HH:MM` |
| **Layer 0 唯一正文源** | α 3-layer 设计 | concept body **只**在 LLM-Wiki `concepts/<slug>.md`，不在 Bitable |
| **lens 多选** | LLM-Wiki 6 lens 设计 | T08 用 `category` 字段（不映射 lens）；lens 单独存 Layer 0 frontmatter |
| **代理绕开** | 实测 EOF | docs/whiteboard `+update` 必须 `LARK_CLI_NO_PROXY=1` |
| **wiki_path 不要 markdown 包装** | Phase 2 实测 | 写 `concepts/<slug>.md` 纯文本，lark-cli 不会自动包 markdown |
| **N=3 上限** | developing 状态 | 用户超过 N=5 / 30 concepts / 5 mature 时，本 skill 必须升 v1.0 |

完整 13 个 schema drift signals → [docs/drift-signals.md](docs/drift-signals.md)
完整 lark-cli 9 个坑 → [references/pitfalls.md](references/pitfalls.md)

## 与 LLM-Wiki sync（未实现，等 v1）

设计已写在 [architecture-card.md#sync-边界](references/architecture-card.md)，但脚本未落地。触发条件：
- T08_知识概念索引 至少 30 行
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

本 skill v0.2 = 2026-05-12 N=1 sandbox dry-run + 2026-05-13 N=2 workstation 5.0 dry-run（共 3 次实战）：

- N=1: 1 场 33 min 妙记 → 5 concepts → sandbox（已 deprecated，30 天保留）
- N=2 (2 场, 2026-05-13): 专家IP复盘 42m → 5 concepts；教育项目视频运营 35m → 5 concepts → 工作台 5.0 base T08 + LLM-Wiki concepts/

具体产物 URL 含真实 tenant / 文档 token，不对外公开。如需参考样本，按 [`references/extraction-playbook.md`](references/extraction-playbook.md) 在你自己的飞书 tenant 跑一次。

理论框架借鉴：[LLM-Wiki](https://github.com/moonstachain/llm-wiki)（4-layer 架构 / 6 ontology lens / write-back rule / metabolism dashboard）。

## 升级路线

| 版本 | 触发条件 | 加什么 |
|---|---|---|
| v0.1 | N=1 sandbox 实战 | 5 步流水线 + 12 字段 sandbox schema + 9 lark-cli 坑 |
| **v0.2 (now)** | N=2 workstation 5.0 实战 + 13 drift signals + α 3-layer 架构 | T08/T16 schema 修正 + extract_one_meeting.sh + dashboard config + spec/plan/drift docs |
| v0.3 | N=3 通过 + Promote 流程上线 | sandbox → 工作台 5.0 promote 自动化 |
| v1.0 | N≥5 + 至少 30 concepts in T08 + 至少 5 mature | sync 回流 LLM-Wiki 自动脚本；删 developing 标签 |
