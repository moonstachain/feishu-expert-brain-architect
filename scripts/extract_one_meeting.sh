#!/usr/bin/env bash
# extract_one_meeting.sh — Run α-path extraction for one meeting
#
# Usage:
#   bash extract_one_meeting.sh <minute_token> <workstation_base_token> \
#     <t08_table_id> <t16_table_id> <t16_record_id> \
#     <expert_brain_space_id> <prod_node_token>
#
# Output to stdout: instructions for Claude to consume (transcript path + context JSON path)

set -e

if [ "$#" -ne 7 ]; then
  echo "Usage: $0 <minute_token> <workstation_base_token> <t08_table_id> <t16_table_id> <t16_record_id> <expert_brain_space_id> <prod_node_token>" >&2
  exit 1
fi

MINUTE_TOKEN=$1
WS_TOKEN=$2
T08_ID=$3
T16_ID=$4
T16_RECORD_ID=$5
EB_SPACE_ID=$6
PROD_NODE=$7

WORK_DIR="/tmp/extract-${MINUTE_TOKEN}"
mkdir -p "$WORK_DIR"

# Pull transcript (must use relative path — pitfall #9)
cd "$WORK_DIR"
lark-cli vc +notes --minute-tokens "$MINUTE_TOKEN" --output-dir ./transcripts >/dev/null 2>&1
TRANSCRIPT=$(find transcripts -name "transcript.txt" | head -1)
if [ ! -f "$TRANSCRIPT" ]; then
  echo "ERROR: transcript not pulled for $MINUTE_TOKEN" >&2
  exit 2
fi

cat > "$WORK_DIR/extraction_context.json" <<JSONEOF
{
  "minute_token": "$MINUTE_TOKEN",
  "transcript_path": "$WORK_DIR/$TRANSCRIPT",
  "workstation_base_token": "$WS_TOKEN",
  "t08_table_id": "$T08_ID",
  "t16_table_id": "$T16_ID",
  "t16_record_id": "$T16_RECORD_ID",
  "expert_brain_space_id": "$EB_SPACE_ID",
  "prod_node_token": "$PROD_NODE",
  "llm_wiki_path": "/Users/liming/Documents/LLM-Wiki"
}
JSONEOF

echo "STEP1_OK transcript=$WORK_DIR/$TRANSCRIPT lines=$(wc -l <"$TRANSCRIPT")"
echo "STEP2_OK context=$WORK_DIR/extraction_context.json"
echo ""
echo "Claude: read transcript + concepts.json template, then:"
echo "  1) Extract 3-5 concepts with quote anchors"
echo "  2) Write LLM-Wiki concepts/<slug>.md (cd to LLM-Wiki)"
echo "  3) Write T08 index rows with {fields:[...], rows:[[...]]} format"
echo "  4) Generate synthesis docx + whiteboard under PROD_NODE_TOKEN"
echo "  5) Update T16 record extracted_at + extracted_concept_count"
echo "  6) Git commit LLM-Wiki"
