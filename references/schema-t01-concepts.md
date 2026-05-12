# T01_concepts Schema（v0.1）

> 飞书 Bitable 主表，对应 LLM-Wiki 的 `concepts/`。每行 = 一张概念卡。

## 12 字段定义

| # | 字段名 | 飞书 type | 额外属性 | 对应 LLM-Wiki | 强制 | 备注 |
|---|---|---|---|---|---|---|
| 1 | `concept_name` | text | (primary) | title | ✅ | 中英文均可，建议 ≤30 字 |
| 2 | `type` | select | concept / comparison / synthesis / entity | type | ✅ | 默认 concept |
| 3 | `lens` | select | **multiple: true** | ontology_lens | ✅ | 觉醒/创业/财富/量化/龙虾/绿皮书 |
| 4 | `maturity` | select | stub / developing / mature | maturity | ✅ | 默认 developing |
| 5 | `sources_url` | text | (multi-line) | sources | ✅ | 妙记/Get笔记/原始 URL，逗号分隔 |
| 6 | `maintainer` | user | (default multi) | maintainer | ⚪ | 责任人 |
| 7 | `last_reviewed` | datetime | `yyyy-MM-dd` | last_reviewed | ⚪ | 上次人类审过的日期 |
| 8 | `body` | text | (multi-line) | 正文 | ✅ | **必须以 `【原文 ...】"..."` 开头** |
| 9 | `wiki_doc_url` | url | (text 存储) | (新增) | ⚪ | 成熟后 promote 出的综合页 URL |
| 10 | `obsidian_synced` | select | not_synced / synced / drifted | (新增) | ✅ | 默认 not_synced |
| 11 | `created` | created_at | (auto) | created | ✅ | 飞书自动写 |
| 12 | `updated` | updated_at | (auto) | updated | ✅ | 飞书自动写 |

## ⚠️ 字段创建关键坑（来源：dry-run 实测）

### lens 字段必须显式 `multiple:true`

**正确**：
```bash
lark-cli base +field-create --base-token <T> --table-id <T> \
  --json '{"name":"lens","type":"select","multiple":true,"options":[{"name":"觉醒"},{"name":"创业"},{"name":"财富"},{"name":"量化"},{"name":"龙虾"},{"name":"绿皮书"}]}'
```

**错误**（变成单选）：
```bash
# multi_select 类型不存在
{"name":"lens","type":"multi_select",...}
# property 字段不被接受
{"name":"lens","type":"select","property":{"multiple":true,...}}
```

### 改单选为多选：必须 delete + recreate

`field-update` 不接受 `property` 字段。改 multiple 属性只能：
```bash
lark-cli base +field-delete --base-token <T> --table-id <T> --field-id lens --yes
lark-cli base +field-create --base-token <T> --table-id <T> --json '...multiple:true...'
```

### user 字段创建时不要带 property

**正确**：`{"name":"maintainer","type":"user"}`
**错误**：`{"name":"maintainer","type":"user","property":{"multiple":false}}` → 创建失败

### 飞书 Bitable 16 种合法 type

`text | number | select | datetime | created_at | updated_at | user | group_chat | created_by | updated_by | link | formula | lookup | auto_number | attachment | location | checkbox`

**没有** `multi_select` / `url` / `phone`。
- 多选用 `select + multiple:true`
- URL 用 `text`（写入时存 URL 字符串即可，飞书会自动渲染）

## body 字段格式规范（硬约束）

每条 concept 的 `body` 字段**必须**以原文 quote 开头：

```
【原文 <speaker> HH:MM】「<原文片段，至少 1 句，逐字稿原文>」

【AI 概括】<AI 总结，可以多段，但不能脱离原文太远>

【关联】<可选：与其他概念的关系，如 "与 OSA 闭环模式互补"、"反对走重启动派">
```

**为什么强制**：
- 防止 AI 幻觉（grep 反查可立刻验真）
- 让人类 reviewer 30 秒内判断这条卡是否值得 promote
- mature 后可直接 sync 到 LLM-Wiki concepts 不丢精度

## 字段顺序建议

Bitable 视图默认顺序应该是：
```
concept_name | type | lens | maturity | maintainer | last_reviewed | sources_url | body | wiki_doc_url | obsidian_synced | created | updated
```

这样的好处：人类打开表格时第一眼看到的是「这是什么概念 + 哪个 lens + 成熟度 + 谁负责」，最右侧才是 metadata。

## v0.2 计划（N=2 后补）

- T02_entities（人/公司/项目）
- T01.related（self-link 关联字段，类型 `link`，需要先有数据）
- T01.entities（→ T02 关联字段）

不在 v0.1 加的原因：sandbox 阶段没有足够的实体数据点支撑双向关联。
