# Extraction Playbook — α 3-layer (v0.2)

> Replaces the v0.1 N=1 sandbox playbook.
> **v0.2 α path**: concept body → LLM-Wiki; index row → T08 workstation 5.0; synthesis artifacts → Layer 2 【专家大脑】wiki.

## Pre-flight

```bash
lark-cli --version                       # must be ≥ 1.0.19
lark-cli auth status | jq '.tokenStatus' # must be valid; scope must include minutes/wiki/base/whiteboard
echo $HTTPS_PROXY                        # note proxy — some commands need LARK_CLI_NO_PROXY=1
```

## 8-Step Pipeline (per meeting)

### Step 1: Pull transcript

```bash
cd /tmp/extract-<minute_token>
mkdir -p transcripts
lark-cli vc +notes --minute-tokens <minute_token> --output-dir ./transcripts
# transcript.txt is at: ./transcripts/artifact-<title>-<token>/transcript.txt
```

**Pitfall**: `--output-dir` must be a RELATIVE path. Absolute paths fail silently.

### Step 2: Extract 3-5 concept cards from transcript

**Hard constraint**: every concept body MUST start with `【原文 <speaker> HH:MM】"..."` (original quote anchor). No quote = extraction failure.

For each concept produce:
- `slug`: lowercase-hyphen English key (Chinese → pinyin + date suffix if collision)
- `title`: display name
- `summary`: ≤200 chars, no jargon expansion
- `category`: one of `governance/skill/architecture/methodology/tool/domain/evolution`
- `confidence`: `low/medium/high`
- `related_concepts`: comma-separated slugs of existing LLM-Wiki concepts (check with `ls concepts/`)
- `body`: full markdown body (original quote + AI summary + related wikilinks)

### Step 3: Write LLM-Wiki concept files (Layer 0)

**Critical**: must `cd` to LLM-Wiki root before writing (write is only allowed inside Wiki root).

```bash
cd /Users/liming/Documents/LLM-Wiki
# Check for slug collision first:
ls concepts/<slug>*.md 2>/dev/null && echo "COLLISION — add date suffix"

# Write concept file:
cat > concepts/<slug>.md << 'EOF'
---
title: <concept_title>
type: concept
sources: ["feishu/transcript-<minute_token>.txt"]
related: [<related_slug1>, <related_slug2>]
ontology_lens: [<lens>]
tags: []
maintainer: liming
last_reviewed: <YYYY-MM-DD>
---

【原文 <speaker> HH:MM】"<verbatim quote>"

<AI summary paragraph>

## 相关概念

- [[<related_slug1>]]
- [[<related_slug2>]]

## 出处

- 妙记 `<minute_token>` — `<meeting_title>`
EOF
```

### Step 4: Write T08 index rows (Layer 1)

```bash
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S")
lark-cli base +record-batch-create \
  --base-token <workstation_5_base_token> \
  --table-id <t08_table_id> \
  --json '{
    "fields":["title","concept_slug","summary","page_type","category","confidence","adoption_status","source_count","related_concepts","wiki_path","last_modified","_sync_ts"],
    "rows":[
      ["<title>","<slug>","<summary>","concept","<category>","<confidence>","draft",1,"<related>","concepts/<slug>.md","'"$NOW"'","'"$NOW"'"]
    ]
  }'
```

**Pitfall**: use `rows` array-of-arrays form (not array-of-objects). See drift signal #3.
**Pitfall**: `wiki_path` stores plain text `concepts/<slug>.md` — Bitable auto-displays as link. See drift signal #4.

### Step 5: Generate synthesis docx (Layer 2)

```bash
# Write synthesis.md locally first, then push:
LARK_CLI_NO_PROXY=1 lark-cli docs +update --api-version v2 \
  --doc <prod_node_obj_token> \
  --command overwrite \
  --doc-format markdown \
  --content @synthesis.md
```

**Pitfall**: `LARK_CLI_NO_PROXY=1` is required for `docs +update --api-version v2` and `whiteboard +update`. Without it, EOF error.

### Step 6: Generate collaborative whiteboard (Layer 2)

```bash
# Mermaid graph:
cat graph.mmd | LARK_CLI_NO_PROXY=1 lark-cli whiteboard +update \
  --whiteboard-token <board_token> \
  --source - \
  --input_format mermaid \
  --overwrite \
  --yes
```

### Step 7: Update T16 record (Layer 1)

After extraction is complete, write back to the T16 row that was selected:

```bash
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S")
lark-cli base +record-batch-update \
  --base-token <workstation_5_base_token> \
  --table-id <t16_table_id> \
  --json '{
    "record_id_list": ["<t16_record_id>"],
    "patch": {
      "extracted_at": "'"$NOW"'",
      "extracted_concept_count": <N>
    }
  }'
```

### Step 8: Git commit LLM-Wiki

```bash
cd /Users/liming/Documents/LLM-Wiki
git add concepts/<slug>.md
git commit -m "feat(concept): add <slug> from meeting <minute_token>"
```

## Verification Checklist (5/5 required)

- [ ] Every concept body starts with `【原文 <speaker> HH:MM】"..."` (grep original quote → can find match)
- [ ] LLM-Wiki `concepts/<slug>.md` exists and has valid frontmatter
- [ ] T08 row exists with matching `concept_slug` and non-empty `wiki_path`
- [ ] Synthesis docx visible in Layer 2 【专家大脑】wiki `30-产出/`
- [ ] T16 row has `extracted_at` set (not null) and `extracted_concept_count > 0`

## Parameterized Script

For a full scripted version, see `scripts/extract_one_meeting.sh`.
