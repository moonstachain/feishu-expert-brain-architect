# Schema Drift Signals — v0.1 → v0.2 (discovered Phases 1-3, 2026-05-13)

## 1. T08 `adoption_status` options
Spec said `developing/mature`. Actual: `active/draft/deprecated/adopted`.
Mapping: `developing` → `draft`; `mature` → `active` or `adopted`.

## 2. T08 `category` options
Spec said `vision` allowed. Actual: `governance/skill/architecture/methodology/tool/domain/evolution`.
Mapping: `vision` → `architecture` (closest fit for high-level concept blueprints).

## 3. T08 record-batch-create format
Use `{"fields":[<field_names>], "rows":[[<v1>,<v2>...]]}` with fields in EXACT column order matching the T08 schema. Don't use array-of-objects form.

## 4. wiki_path field auto-wraps as markdown
If you write `concepts/foo.md`, lark-cli auto-wraps to `[concepts/foo.md](http://concepts/foo.md)`.
Fix: explicitly write plain text `concepts/<slug>.md` — verified works in Phase 2 Meeting 2.

## 5. URL field displays as text
Bitable normalizes `type:"url"` fields to `text` in field-list output. Stored value is fine; just don't be alarmed.

## 6. Sandbox T05 had 100 rows (dup ingest)
Earlier session accidentally ran batch-create twice. Phase 1 dedupe brought T16 from 100 → 50 unique. For new sandboxes, always verify count after batch-create.

## 7. Chinese curly quotes break JSON
When generating concepts.json with Chinese content, use Python `json.dump(ensure_ascii=False, indent=2)`. Avoid manually writing JSON with embedded Chinese punctuation (curly `"…"` will break parse).

## 8. lark-cli dashboard chart types
Spec assumed `timeline` exists. Actual supported: `column|bar|line|pie|ring|area|combo|scatter|funnel|wordCloud|radar|statistics|text`.
Mapping: `timeline` → `column`; `number` → `statistics`.

## 9. lark-cli dashboard data_config requires `table_name` not `table_id`
The block payload needs `table_name: "T08_知识概念索引"` (display name), not `table_id: "<t08_table_id>"`. This contradicts how other Bitable APIs work — be aware.

## 10. dashboard `series` and `count_all` mutually exclusive
Statistics cards use EITHER `count_all: true` OR `series: [{field_name, rollup}]`. Don't combine.

## 11. T01_战略任务追踪 status field name
Actual field name is `task_status` (not just `status`). Options: `completed/in_progress/blocked/pending/active`.

## 12. T02_进化闭环追踪 has no datetime field
"Timeline by date" grouping isn't possible. Use `trigger_type` (select) as group + `score_after` (number, AVERAGE) as metric for the line chart.

## 13. lark-cli command flag drift
- `+dashboard-arrange` does NOT take `--yes` flag
- `+dashboard-create` only takes `--name` and `--theme-style` (simple, no JSON body)
- `whiteboard +update` requires `--whiteboard-token <T>` (no positional arg) + `--yes`
- `docs +update --api-version v2` requires `LARK_CLI_NO_PROXY=1` prefix or hits EOF

## Additional smaller signals

- `vc +notes --output-dir` must be RELATIVE path
- `field-delete` always requires `--yes`
- 16 allowed Bitable field types (NO multi_select / url / phone — use `select+multiple:true` / `text`)
- LLM-Wiki write requires cwd inside Wiki (cd before write)

These 13 signals are now baked into v0.2 scripts and references. Future agents shouldn't re-discover them.
