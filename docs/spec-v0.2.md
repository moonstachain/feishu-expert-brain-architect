# 「随身企业大脑」落地 v0.1 — Design Spec

| | |
|---|---|
| **Date** | 2026-05-13 |
| **Author** | Ray + Claude (via `/using-superpowers`) |
| **Status** | Draft — awaits user review before `writing-plans` |
| **Origin** | 2026-05-11 妙记《AI 交互界面及工作模式规划》Ray 提出「随身企业大脑」概念；2026-05-12 完成飞书侧 N=1 dry-run；本 spec 把 master roadmap 落到 v0.1 实施计划。 |
| **Scope** | Week 1-3，SP2 + SP5 双线并行；后续 SP1/SP3/SP4/SP6 在 spec 末 §11 列入 backlog 但不展开。 |

---

## 1. 决策日志

5 轮 brainstorming AskUserQuestion 锁定：

| # | 决策点 | 选择 | 影响 |
|---|---|---|---|
| D1 | 「企业大脑」指哪个？ | C — Ray 总体愿景落地（不是单纯 A/B 子项目） | scope = master roadmap |
| D2 | 主要用户 | 1 号位自用（Ray 个人驾驶舱） | 5 协作层暂缓；不做 B2B/多租户 |
| D3 | Sequencing | 混合 SP2 + SP5 并行起步 | 双线 Week 1 同时启动 |
| D4 | SP5 驾驶舱载体 | 挂工作台 5.0 base（已有 16 表） | 暴露命名碰撞 |
| D5 | 命名碰撞解 | ii 合并到工作台 5.0 | 把 sandbox 表整合，T08/T16 |
| D6 | Concept 正文住所 | α 拥抱 5.0 哲学：LLM-Wiki 存正文，T08 存索引 | 三层架构定型 |

---

## 2. 三层架构

```
┌─ Layer 0: LLM-Wiki (Obsidian)               真相源 / 主存储
│   • /Users/liming/Documents/LLM-Wiki/concepts/<slug>.md
│   • concept 正文唯一存放点（wikilinks / frontmatter / dataview 全可用）
│   • 已有 1087 concepts + 1364 知识总量
│   ↑ wiki_path 指向（相对 Wiki 根，如 "concepts/osa-loop.md"）
│
┌─ Layer 1: 工作台 5.0 base                   索引 + 治理 + 驾驶舱
│   base_token: <workstation_5_base>
│   • T00 系统总控 / T01 战略任务 / T02 进化闭环 / T03 协作摘要
│   • T04 提案 / T05 决策 / T06 治理成熟度 / T07 三方协同
│   • T08_知识概念索引   ⭐ concept 索引行，wiki_path 指 Layer 0
│   • T09 进化模式 / T10 能力全景 / T11 信息健康
│   • T12 卫星克隆 / T13 行为日志 / T14 治理对象 / T15 审查批次
│   • T16_meeting_inventory   ⭐ new，妙记元数据索引（50 行迁入）
│   ↑ 抽取产物附加链接
│
┌─ Layer 2: 飞书【专家大脑】wiki space         协同入口
│   space_id: <expert_brain_space_id>
│   • 30-产出/synthesis-<topic>.docx          抽取后的综合页
│   • 30-产出/whiteboard-<topic>             协同画板
│   • 不存 concept 主体；仅存"展示给同事看"的产物
│
└─ Layer X: 99-Sandbox-2026-05-12             deprecated（30 天后删）
    <sandbox_node>
```

**层间边界**（铁律）：

| 内容 | Layer 0 | Layer 1 | Layer 2 |
|---|---|---|---|
| Concept 正文 | ✅ 唯一 | ❌ 不存 | ❌ 不存 |
| Concept 索引行 | — | ✅ T08 | ❌ |
| 妙记元数据 | ❌ | ✅ T16 | ❌ |
| 妙记原文转写 | ✅ sources/feishu/ | ❌ | ❌ |
| synthesis 综合页 | ❌ syntheses/ 仅 mature | ❌ | ✅ docx |
| 协同画板 | ❌ | ❌ | ✅ |
| 治理状态 / 决策 | ❌ | ✅ T01-T15 | ❌ |
| 战略任务 / 大 O | ❌ | ✅ T01 | ❌ |

---

## 3. SP2 详细设计 — N=2/N=3 + skill v0.2 bump

### 3.1 输入

从 T16_meeting_inventory（50 行）由 Ray 手动勾 2-3 场 `selected_for_extraction=true`。

**优先池建议**（基于已 ingest 的 50 场启发式分类）：
- methodology=8 场 → 优先池
- business=12 场 → 次优池
- sensitive=12 场 → 需 Ray 单独确认每场
- chat=2 + unknown=16 → 不选

### 3.2 抽取流程（每场会议）

```
1. lark-cli vc +notes --minute-tokens <T> --output-dir ./transcripts
2. AI 抽 3-5 concept（保留 N=1 dry-run 的 quote 强制约束）
3. cwd 切到 LLM-Wiki：cd /Users/liming/Documents/LLM-Wiki
   写 concepts/<slug>.md（frontmatter + 原文 quote + AI 概括 + 关联）
4. 工作台 5.0 base T08 写索引行：
   - title / concept_slug / page_type=concept
   - summary（≤2 句）/ wiki_path（如 "concepts/osa-loop.md"）
   - source_count=1 / category=（映射 LLM-Wiki lens）
   - confidence / adoption_status=developing / last_modified
5. 生成 synthesis docx + 画板 → Layer 2【专家大脑】「30-产出」节点下
6. 工作台 5.0 base T16 更新行：
   - selected_for_extraction=true
   - extracted_at=<ISO date>
   - extracted_concept_count=<N>
```

### 3.3 v0.2 schema 漂移预期

T08 现有 12 字段对照飞书【专家大脑】sandbox T01 的 12 字段：

| T08 已有 | Sandbox T01 对应 | 状态 |
|---|---|---|
| title | concept_name | ✅ |
| concept_slug | (新增需求) | ✅ slug 规则定为：英文 lowercase + hyphen（如 `osa-loop`）；中文 concept 取首要英文术语，若无则用拼音 + 短日期后缀避免撞名 |
| page_type | type | ✅ |
| summary | (从 body 切短) | ✅ 限 200 字以内 |
| category | (与 lens 解耦) | ✅ category 保留 5.0 原语义（治理类别），不映射 lens；lens 用 v0.2 新增的独立字段 |
| confidence | maturity 部分 | ✅ confidence 表示「我对此概念正确度的把握」，独立于 maturity；初始值 `medium` |
| adoption_status | maturity + obsidian_synced | ✅ 合并：stub/developing/mature 直接用 adoption_status；obsidian_synced 信息折入 `_sync_ts` 时间戳 |
| source_count | (新增) | ✅ |
| related_concepts | (新增) | ✅ |
| wiki_path | (新增) | ✅ |
| last_modified | last_reviewed | ⚠️ |
| _sync_ts | (sync 信号) | ✅ |

T08 缺、需在 v0.2 加：
- `lens` (select multiple, options: 觉醒/创业/财富/量化/龙虾/绿皮书)
- `original_quote_count` (number, 用于 audit "概念是否锚定原文")
- `meeting_origin` (link → T16，溯源到哪场会议)
- `maintainer` (user, accountable owner)

### 3.4 skill v0.2 改动

`~/.claude/skills/feishu-expert-brain-architect/`：

- SKILL.md frontmatter：`maturity: experimental → developing`；`sample_size: N=1 → N=3`；`primary_base: workstation-5.0 not sandbox`
- `references/architecture-card.md`：B 路径 → α 路径（三层架构）；sync 章节大改
- `references/schema-t01-concepts.md` → 改名 `schema-t08-concept-index.md`
- `references/n1-dry-run-playbook.md` → `references/extraction-playbook.md`（同时支持新 + 复用）
- `scripts/bootstrap_sandbox.sh` → deprecated；新 `scripts/migrate_to_workstation_5.sh` + `scripts/extract_one_minute.sh`
- 新 `references/migration-notes.md` 记录 sandbox→workstation 5.0 迁移过程

GitHub repo `moonstachain/feishu-expert-brain-architect`：v0.2 release notes + changelog 链到本 spec。

---

## 4. SP5 详细设计 — 驾驶舱

### 4.1 载体

工作台 5.0 base 内置 dashboard（飞书 Bitable 原生 dashboard 功能）。复用现有 `feishu-dashboard-automator` skill。

### 4.2 Dashboard blocks v0.1（6 个 block）

| # | Block 名 | 数据源 | 类型 | Ray 原话对应 |
|---|---|---|---|---|
| 1 | 大 O 进度 | T01_战略任务追踪 | 饼图 by status | 「大O 几个板块」 |
| 2 | 概念库分布 | T08_知识概念索引 | 柱状 by category | 「知识管理」 |
| 3 | 妙记本周流入 | T16_meeting_inventory | 计数 (extracted=true vs false) | 「逐字稿小卡片」 |
| 4 | 协作日志 stream | T03_日终协作摘要 | 时间线 | 「养卡」 |
| 5 | 进化时间线 | T02_进化闭环追踪 | 折线 | 「关停并转」 |
| 6 | 信息健康 | T11_信息健康度汇总 | 数字大字 | 「辨识度」 |

### 4.3 入口

手机/PC 飞书 App → 工作台 5.0 base → 默认 dashboard tab。

### 4.4 v0.2 期间增量（依赖 SP2）

- T08 加 `lens` 字段后 → 加 block 7「概念 lens 分布」
- T08 累积 ≥ 15 行 → block 2 从空状态变实数据
- T16 ≥ 50 行 → block 3 加趋势对比

### 4.5 配置而非 hardcode

每个 block 的字段映射写在 `dashboard_blocks.json` 配置文件：

```json
{
  "blocks": [
    {"id":"b2","title":"概念库分布","table":"T08","group_by":"category","type":"bar"},
    ...
  ]
}
```

SP2 改 schema 时 patch 此文件，不需要重建 dashboard。

---

## 5. SP2 ↔ SP5 协调点

| 触发条件 | SP5 反应 |
|---|---|
| SP2 改 T08 字段名 | 改 `dashboard_blocks.json` 字段映射 |
| SP2 给 T08 加 `lens` 字段 | 加 block 7「lens 分布」 |
| SP2 N=2/N=3 完毕、T08 累积 ≥ 10 行 | block 2 从空状态变实数据；截屏归档 |
| SP5 发现 dashboard 缺数据 | 倒推回 SP2 / 后续 SP4 补字段 |

---

## 6. 迁移计划（30-45 分钟一次性）

执行顺序严格：

| Step | 动作 | 工具 | 预计时长 | 验真 |
|---|---|---|---|---|
| A | 在工作台 5.0 base 建 T16_meeting_inventory（7 字段照搬 sandbox T05） | lark-cli wiki +node-create + base +field-create | 5 min | field-list 7 字段全到位 |
| B | sandbox T05 的 50 行迁到 T16 | record-list → record-batch-create | 5 min | T16 count=50 |
| C | sandbox T01 的 5 个 concept body 作为 markdown 写到 LLM-Wiki concepts/ | cd Wiki + Write | 10 min | 5 个 .md 文件存在；grep 原文 quote 可命中 |
| D | T08_知识概念索引 写 5 行索引（wiki_path 指 Step C 的 md 路径） | record-batch-create | 5 min | T08 count=5 |
| E | sandbox 入口 docx 加 `[已废弃，迁移于 2026-05-13]` banner + 链接到新位置 | docs +update | 5 min | 打开 sandbox docx 看到 banner |
| F | 在【专家大脑】wiki 根下若不存在「30-产出」节点先建（docx 类型），再用 `wiki +move` 把 sandbox 下 synthesis docx + 画板移到「30-产出」之下 | wiki +node-create + wiki +move | 10 min | 节点 parent_node_token 已切到 30-产出 |

迁移失败回滚：sandbox 旧表保留 30 天不删，可随时退回原状。

---

## 7. 时间表 + Milestones

| 周 | 工作日 | 里程碑 | 验真标准 |
|---|---|---|---|
| **W1**（5/13-5/19） | M 早 | Ray 在 T16_meeting_inventory 勾 2-3 场 `selected_for_extraction=true`（W2 N=3 一并勾） | T16 至少 2 行 selected |
| W1 | M-T | 迁移 6 步完成 | T08=5 行 / T16=50 行 / Wiki concepts/=5 文件 |
| W1 | W-Th | SP2 N=2（跑 1 场新妙记，全程使用新架构） | T08≥8 行 / T16 有 1 行 extracted=true |
| W1 | F | SP5 dashboard 骨架 3 blocks | 打开能看到 block 1+2+3 |
| **W2**（5/20-5/26） | M-T | SP2 N=3（跑第 3 场） | T08≥11 行 |
| W2 | W-Th | skill v0.2 bump + GitHub release | repo tag v0.2 |
| W2 | F | SP5 完整 6 blocks + 配置文件化 | dashboard_blocks.json 存在；6 blocks 显示 |
| **W3**（5/27-6/2） | M-T | schema 稳定评估 | 至少 1 周无 schema 改动 |
| W3 | W-Th | sandbox 旧表删除（迁移后已超 30 天） | sandbox 节点空 |
| W3 | F | 启动下一 sub-project（SP3 OSA 自动拆解 或 SP1 sync） | spec 草稿 |

---

## 8. 风险 + 失真护栏

| 风险 | 概率 | 影响 | 护栏 |
|---|---|---|---|
| LLM-Wiki 写权限：cwd 不在 wiki 时 read-only | 高 | 抽取失败 | 抽取脚本前置 `cd /Users/liming/Documents/LLM-Wiki` 检查 |
| Concept slug 与已有 1087 concepts 撞名 | 中 | 覆盖现有内容 | 抽取前 `ls concepts/<slug>*` 检测，撞了加日期 / 序号后缀 |
| T08 wiki_path 失效（concept 被人改名或删除） | 中 | 索引腐烂 | 周度 lint：扫 T08 wiki_path → 文件存在性；失效行标 `adoption_status=stale` |
| SP5 schema 配置硬编码 | 低 | 后续重建 dashboard 痛苦 | block 配置写 dashboard_blocks.json |
| skill v0.2 命名漂移：sandbox 路径仍出现在文档 | 中 | 用户照旧建错位置 | v0.2 SKILL.md 头部加 deprecation notice + migration guide |
| 1 号位自用边界扩散 | 低 | 拖累进度 | T07 / T12 协同字段不动；5 协作层不在本 spec |
| 命名冲突 T01 同名（专家大脑 vs 5.0）历史 sandbox 文件还在 | 高 | 后续读 memory 混淆 | 更新 memory 标 sandbox T01 为 deprecated |
| 妙记敏感会议被 ingest | 高 | 数据治理风险 | sensitive 类必须 Ray 单条确认；不放入 LLM-Wiki concepts/ |
| Week 1 同时启动 SP2 + SP5 资源紧张 | 中 | 拖延 | 严格按时间表，发现资源冲突时 SP2 优先 |

---

## 9. Out-of-scope（本 spec 不做）

- SP1 A↔B sync 回流脚本（W3 之后）
- SP3 OSA 自动拆解器（W3 之后）
- SP4 多源聚合：邮件/IM/自由笔记（W3 之后）
- SP6 对外能力包生成器（W3 之后）
- 5 协作层：跨人龙虾握手 / 共享权限 / 多人改卡（暂缓）
- B2B 产品化（不做）
- 实时事件订阅（不做）
- 工作台 5.0 已有 16 表的字段重设（不动 5.0 已有表）

---

## 10. 6 轴评分

| 轴 | 分 | 说明 |
|---|---|---|
| 创新 | 4 | 三层路径厘清（索引/正文/协同分层）是真创新 |
| 可信 | 5 | 全基于已 N=1 验过的 schema + 工作台 5.0 实物 |
| 复用 | 5 | 复用 feishu-expert-brain-architect + feishu-dashboard-automator + LLM-Wiki write-back rule |
| 验真 | 4 | 每个 SP / Milestone 都有 testable verifier |
| 维护 | 4 | 单一真相源减负 |
| 美感 | 5 | 三层架构干净，与已有治理设计同源 |
| **总** | **27/30** | |

---

## 11. Backlog（W3 后展开）

下一 sub-project 候选（按优先级）：

1. **SP3 OSA 自动拆解器**：从 transcript 直接出 O/S/A 三段 + 工作域标签（最接近 Ray 妙记愿景，需先有 SP2 schema 稳）
2. **SP1 A↔B sync 自动化**：write-back 规则脚本化（W3 schema 稳后做）
3. **SP4 多源聚合**：邮件 / IM / 自由笔记 ingest 入口（依赖 SP3 OSA 拆解器跑通）
4. **SP6 对外能力包**：T08 mature concepts → 「能力卡片」docx 自动生成（依赖 ≥ 30 个 mature concepts）
5. **5 协作层**：跨人龙虾握手（最远，看 Ray 团队规模演化）

各 sub-project 在 W3 评估时再决定下一个 spec 主题。

---

## 12. Spec 自检 checklist（写完后自查）

- [ ] 无 TBD / TODO / 占位符
- [ ] 各 section 一致：架构 §2 与 SP2 §3 / SP5 §4 不冲突
- [ ] scope 足够小：W1-W3、SP2+SP5 双线、迁移一次性
- [ ] 无歧义：每个表名 / 字段名 / token 唯一指向
- [ ] 失真护栏覆盖了已识别的所有风险

---

## 13. 同步沉淀

本 spec 落地后须更新：

- `~/.claude/projects/.../memory/project_feishu_expert_brain_v0.md`：标 deprecated，指向本 spec
- `~/.claude/projects/.../memory/MEMORY.md`：加本 spec 索引行
- 新 project memory：`project_suishen_qiye_dalao_v0.md`
