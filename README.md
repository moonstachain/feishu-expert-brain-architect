# feishu-expert-brain-architect

> 把会议妙记 / 长讨论 / 跨场次素材，**自动蒸馏成飞书侧的「专家大脑」知识体系**——Bitable 概念库 + Wiki 综合页 + 协同画板。
> Claude Code skill。借鉴 LLM-Wiki 设计 DNA，飞书原生存储。

[![status](https://img.shields.io/badge/status-experimental-orange)](#status)
[![sample size](https://img.shields.io/badge/sample-N%3D1-yellow)](#status)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

## What it does

A 5-step pipeline that runs end-to-end in ~25 minutes:

```
妙记 / Minutes
    ↓ lark-cli vc +notes
逐字稿 (transcript)
    ↓ AI 抽 3-5 概念 (强制原文 quote 锚定)
Bitable T01_concepts (12 字段, 6 lens 多选)
    ↓ 综合
飞书 Wiki 综合页 (docx)
    ↓ 可视化
飞书协同画板 (mermaid → 同事可拖动)
```

每张 concept 卡都强制带原文 quote，可 grep 反查防止 AI 幻觉。

## Why borrow LLM-Wiki?

[LLM-Wiki](https://github.com/moonstachain/llm-wiki) 是一个 4 年沉淀的 Obsidian 知识仓库（592 concepts / 5713 sources / 6 ontology lens）。它的设计 DNA（4-layer / write-back / metabolism）适用于私有冷知识仓库，但**不直接适合多人协作**。

本 skill 走「**B-营业窗口**」路径：飞书 = Wiki 的协同营业窗口 + 对外暴露层。详见 [`references/architecture-card.md`](references/architecture-card.md)。

## Quickstart

### 前置条件

- macOS / Linux
- [lark-cli](https://github.com/larksuite/lark-cli) ≥ 1.0.19
- 飞书 tenant 管理员权限（创建 Wiki space / Bitable / 画板）
- 一个 Anthropic Claude Code 环境

### 安装

```bash
# Clone 到你的 ~/.claude/skills/ 下（让 Claude Code 自动发现）
git clone https://github.com/moonstachain/feishu-expert-brain-architect.git \
  ~/.claude/skills/feishu-expert-brain-architect

# Verify lark-cli auth + scopes
lark-cli auth status | jq '.scope' | grep -E "minutes|wiki|base|whiteboard"
```

### 第一次使用

在 Claude Code 里直接说：

> 用 feishu-expert-brain-architect 把 [某场妙记 URL] 抽成专家大脑

或更自然的说法：

> 把这周三的选题会沉淀进我的专家大脑

Claude 会自动按 [`references/n1-dry-run-playbook.md`](references/n1-dry-run-playbook.md) 跑 5 步流水线。

## What you get

| 产物 | 形态 |
|---|---|
| Sandbox 节点 | 飞书 Wiki 子节点，隔离测试用 |
| T01_concepts | Bitable 表，12 字段 schema（含 6 lens 多选） |
| 5 张概念卡 | Bitable 行，每行带原文 quote |
| 综合页 | 飞书 docx，含一句话总结 / 概念卡 / mini 图谱 / LLM-Wiki 候选连接 |
| 协同画板 | 飞书 board，同事可拖动节点 / 改文字 / 加批注 |

## What's in this repo

```
SKILL.md                              入口：决策树 + 5 步流水线 + 失真护栏
references/
├── architecture-card.md              设计哲学：B 路径 + DNA 映射 + 6 lens + sync 边界
├── schema-t01-concepts.md            12 字段 schema 详解 + 创建坑
├── pitfalls.md                       9 个 lark-cli 实战坑 + 排错优先级
└── n1-dry-run-playbook.md            5 步 25 分钟完整命令模板
scripts/
└── bootstrap_sandbox.sh              一键建 sandbox + Bitable + 12 字段
LICENSE                                MIT
```

## Status

**experimental, sample_size=N=1, since 2026-05-12**

本 skill 仅在 1 场真实会议妙记上验证过完整链路。在扩到生产数据前，请：

1. 先用本 skill 在你自己的 `99-Sandbox-<date>` 节点跑一次 N=1
2. 跑通后改 1 个字段 schema 试试
3. 再跑 N=2 / N=3 验证稳健性

升级路线：

| 版本 | 触发条件 | 加什么 |
|---|---|---|
| **v0.1 (current)** | N=1 实战 | 5 步流水线 + 12 字段 + 9 坑 |
| v0.2 | N=2 通过 | schema 漂移修正 + 可能扩 lens |
| v0.3 | N=3 通过 | Promote 流程（从 sandbox 到正式 lens 节点） |
| v1.0 | N≥5 + 30 concepts + 5 mature | LLM-Wiki sync 回流脚本；删 experimental |

## Constraints

- **N=1 原则**：一次只抽 1 场妙记，3-5 个概念。批量 ingest 留 v0.2 后。
- **原文 quote 强制**：每条 concept 的 body 必须以 `【原文 <speaker> HH:MM】"..."` 开头。
- **Sandbox 隔离**：所有产物默认在 `99-Sandbox-<date>` 节点下，不直接污染生产 wiki。
- **代理绕开**：飞书 v2 API + 本地 HTTPS_PROXY 会 EOF，所有 `docs +update` / `whiteboard +update` 必须 `LARK_CLI_NO_PROXY=1` 前置。

## Contributing

跑通后发现新的失真点 / 新坑 / 新需求？欢迎 PR。优先级：

1. **新坑** → `references/pitfalls.md` 加第 N+1 条
2. **schema 改动** → `references/schema-t01-concepts.md` + 同步 `scripts/bootstrap_sandbox.sh`
3. **新流程** → 先在自己环境 N=1 验证，再开 PR

如果你跑到了 N=2 / N=3 / N=5，欢迎在 Issues 里贴 sample run 数据，帮我们决定何时升 v0.2 / v0.3 / v1.0。

## Related

- [LLM-Wiki](https://github.com/moonstachain/llm-wiki) — 私有真相源（Obsidian 4-layer 仓库）
- [yuanli-os-company-brain-skill](https://github.com/moonstachain/yuanli-os-company-brain-skill) — 同源蒸馏的 Obsidian 侧 skill
- [lark-cli](https://github.com/larksuite/lark-cli) — 本 skill 依赖的飞书 CLI

## License

[MIT](LICENSE) © 2026 moonstachain
