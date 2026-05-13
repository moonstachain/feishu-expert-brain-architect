# Schema: T08_知识概念索引 + T16_meeting_inventory (v0.2)

> These tables live in 工作台 5.0 base (`<your_workstation_5_base>`).
> T08 is the **index** layer — concept bodies live in Layer 0 (LLM-Wiki), not here.

---

## T08_知识概念索引 — 12 Fields

This table holds one row per concept. The `wiki_path` field links each row to the canonical `.md` file in LLM-Wiki.

| # | Field Name | Type | Notes |
|---|---|---|---|
| 1 | title | text (primary) | Human-readable concept name, e.g. "OSA Loop" |
| 2 | concept_slug | text | Slug key, e.g. `osa-loop`. Lowercase, hyphens only. Chinese concepts → pinyin + date suffix if collision risk. |
| 3 | summary | text | AI-generated ≤200 char summary. NOT the full body. |
| 4 | page_type | select | Always `concept` for this table. Options: `concept` |
| 5 | category | select | Governance category. Options: `governance` / `skill` / `architecture` / `methodology` / `tool` / `domain` / `evolution`. **NO `vision`** — map to `architecture`. |
| 6 | confidence | select | Confidence in correctness. Options: `low` / `medium` / `high`. Default `medium`. |
| 7 | adoption_status | select | Adoption lifecycle. Options: `active` / `draft` / `deprecated` / `adopted`. **NO `developing`/`mature`**. Map `developing`→`draft`, `mature`→`active` or `adopted`. |
| 8 | source_count | number | Count of source meetings / documents that informed this concept. |
| 9 | related_concepts | text | Comma-separated slugs of related concepts, e.g. `osa-loop,n1-rule`. |
| 10 | wiki_path | text (url-typed display) | Plain path relative to LLM-Wiki root: `concepts/<slug>.md`. Store as plain text — do NOT markdown-wrap. Bitable may display as link; that's fine. See drift signal #4. |
| 11 | last_modified | text | ISO datetime string when the LLM-Wiki .md was last updated, e.g. `2026-05-13T14:00:00`. |
| 12 | _sync_ts | text | ISO datetime string when this T08 row was last synced/written. |

### Record Batch-Create Format

Use `{"fields":[<field_names_in_order>], "rows":[[<v1>,<v2>...]]}` with field names in the EXACT column order matching the T08 schema. Do NOT use array-of-objects form (see drift signal #3).

Example:
```json
{
  "fields": ["title","concept_slug","summary","page_type","category","confidence","adoption_status","source_count","related_concepts","wiki_path","last_modified","_sync_ts"],
  "rows": [
    ["OSA Loop","osa-loop","OSA 是目标(O)/策略(S)/行动(A)三段拆解法","concept","methodology","high","draft",1,"n1-rule","concepts/osa-loop.md","2026-05-13T14:00:00","2026-05-13T14:00:00"]
  ]
}
```

---

## T16_meeting_inventory — 9 User Fields (+ auto ID)

This table holds one row per 妙记 (meeting minute). Bitable auto-adds a record ID.

| # | Field Name | Type | Notes |
|---|---|---|---|
| 1 | meeting_title | text (primary) | Title from 妙记, e.g. "AI 交互界面及工作模式规划" |
| 2 | started_at | datetime | Meeting start time |
| 3 | meeting_type | select | Options: `methodology` / `business` / `chat` / `sensitive` / `unknown` |
| 4 | minute_url | text (url display) | URL to 妙记 page, stored as plain text |
| 5 | duration_min | number | Meeting duration in minutes |
| 6 | keywords | text | Comma-separated keywords extracted from summary |
| 7 | selected_for_extraction | checkbox | Ray marks `true` when this meeting should be extracted |
| 8 | extracted_at | text | ISO datetime when extraction was completed |
| 9 | extracted_concept_count | number | How many concepts were extracted from this meeting |

### Notes

- `meeting_type = sensitive` rows require explicit Ray confirmation before extraction — never auto-extract.
- `selected_for_extraction = true` is the trigger for SP2 extraction pipeline.
- After extraction, write back `extracted_at` and `extracted_concept_count` (Step 5 of extraction-playbook.md).
