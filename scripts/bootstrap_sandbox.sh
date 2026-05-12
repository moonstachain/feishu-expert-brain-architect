#!/usr/bin/env bash
# bootstrap_sandbox.sh
# 一键建 sandbox 节点 + T01_concepts Bitable + 12 字段
#
# Usage:
#   bash bootstrap_sandbox.sh <space_id> <parent_node_token> <sandbox_title>
#
# Example:
#   bash bootstrap_sandbox.sh <your_space_id> <parent_node_token> "99-Sandbox-2026-05-12"
#
# Output (stdout):
#   SANDBOX_NODE_TOKEN=...
#   BITABLE_APP_TOKEN=...
#   TABLE_ID=tbl...
#   T01_URL=https://...

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <space_id> <parent_node_token> <sandbox_title>" >&2
  exit 1
fi

SPACE_ID="$1"
PARENT_NODE_TOKEN="$2"
SANDBOX_TITLE="$3"

# Resolve the tenant domain by looking up the parent node
echo "[1/6] Resolving tenant..." >&2
TENANT_INFO=$(lark-cli wiki spaces get_node --params "{\"token\":\"${PARENT_NODE_TOKEN}\",\"obj_type\":\"wiki\"}" 2>/dev/null)
TENANT_OK=$(echo "$TENANT_INFO" | grep -c '"code": 0' || true)
if [ "$TENANT_OK" -lt 1 ]; then
  echo "ERROR: failed to resolve parent node" >&2
  echo "$TENANT_INFO" >&2
  exit 2
fi

# Step 1: Create sandbox docx node under parent
echo "[2/6] Creating sandbox docx node..." >&2
SANDBOX_RESP=$(lark-cli wiki +node-create \
  --space-id "$SPACE_ID" \
  --parent-node-token "$PARENT_NODE_TOKEN" \
  --obj-type docx \
  --title "$SANDBOX_TITLE" 2>/dev/null)

SANDBOX_NODE_TOKEN=$(echo "$SANDBOX_RESP" | python3 -c 'import sys,json; print(json.load(sys.stdin)["data"]["node_token"])')

# Step 2: Create T01_concepts Bitable under sandbox
echo "[3/6] Creating T01_concepts Bitable..." >&2
BITABLE_RESP=$(lark-cli wiki +node-create \
  --space-id "$SPACE_ID" \
  --parent-node-token "$SANDBOX_NODE_TOKEN" \
  --obj-type bitable \
  --title "T01_concepts_sandbox" 2>/dev/null)

BITABLE_APP_TOKEN=$(echo "$BITABLE_RESP" | python3 -c 'import sys,json; print(json.load(sys.stdin)["data"]["obj_token"])')

# Step 3: Get default table ID
echo "[4/6] Getting default table ID..." >&2
TABLE_RESP=$(lark-cli base +table-list --base-token "$BITABLE_APP_TOKEN" 2>/dev/null)
TABLE_ID=$(echo "$TABLE_RESP" | python3 -c 'import sys,json; print(json.load(sys.stdin)["data"]["tables"][0]["id"])')

# Step 4: Rename default table to T01_concepts
echo "[5/6] Renaming table and configuring fields..." >&2
lark-cli base +table-update \
  --base-token "$BITABLE_APP_TOKEN" \
  --table-id "$TABLE_ID" \
  --name "T01_concepts" >/dev/null 2>&1

# Step 5: Rename default fields and create the 12-field schema
# Default fields after table creation are: "Text", "Single option", "Date", "Attachment"

# Rename Text -> concept_name
lark-cli base +field-update \
  --base-token "$BITABLE_APP_TOKEN" \
  --table-id "$TABLE_ID" \
  --field-id "Text" \
  --json '{"name":"concept_name","type":"text"}' >/dev/null 2>&1 || true

# Rename Single option -> type (concept/comparison/synthesis/entity)
lark-cli base +field-update \
  --base-token "$BITABLE_APP_TOKEN" \
  --table-id "$TABLE_ID" \
  --field-id "Single option" \
  --json '{"name":"type","type":"select","options":[{"name":"concept"},{"name":"comparison"},{"name":"synthesis"},{"name":"entity"}]}' >/dev/null 2>&1 || true

# Rename Date -> last_reviewed
lark-cli base +field-update \
  --base-token "$BITABLE_APP_TOKEN" \
  --table-id "$TABLE_ID" \
  --field-id "Date" \
  --json '{"name":"last_reviewed","type":"datetime","style":{"format":"yyyy-MM-dd"}}' >/dev/null 2>&1 || true

# Delete Attachment (not needed)
lark-cli base +field-delete \
  --base-token "$BITABLE_APP_TOKEN" \
  --table-id "$TABLE_ID" \
  --field-id "Attachment" \
  --yes >/dev/null 2>&1 || true

# Create the remaining 9 fields
echo "[6/6] Creating remaining fields..." >&2

# 9 new fields to create
declare -a FIELDS=(
  '{"name":"lens","type":"select","multiple":true,"options":[{"name":"觉醒"},{"name":"创业"},{"name":"财富"},{"name":"量化"},{"name":"龙虾"},{"name":"绿皮书"}]}'
  '{"name":"maturity","type":"select","options":[{"name":"stub"},{"name":"developing"},{"name":"mature"}]}'
  '{"name":"sources_url","type":"text"}'
  '{"name":"maintainer","type":"user"}'
  '{"name":"body","type":"text"}'
  '{"name":"wiki_doc_url","type":"url"}'
  '{"name":"obsidian_synced","type":"select","options":[{"name":"not_synced"},{"name":"synced"},{"name":"drifted"}]}'
  '{"name":"created","type":"created_at"}'
  '{"name":"updated","type":"updated_at"}'
)

for FIELD_JSON in "${FIELDS[@]}"; do
  lark-cli base +field-create \
    --base-token "$BITABLE_APP_TOKEN" \
    --table-id "$TABLE_ID" \
    --json "$FIELD_JSON" >/dev/null 2>&1 || echo "  WARN: failed to create field: $FIELD_JSON" >&2
done

# Resolve the tenant domain from any existing node URL (best-effort)
# Note: tenant domain isn't returned by API; users should already know their wiki URL

# Output
echo "" >&2
echo "===== BOOTSTRAP COMPLETE =====" >&2
echo "SANDBOX_NODE_TOKEN=$SANDBOX_NODE_TOKEN"
echo "BITABLE_APP_TOKEN=$BITABLE_APP_TOKEN"
echo "TABLE_ID=$TABLE_ID"
echo ""
echo "# Next steps:"
echo "# 1. Open sandbox: https://<tenant>.feishu.cn/wiki/$SANDBOX_NODE_TOKEN"
echo "# 2. Open Bitable: https://<tenant>.feishu.cn/base/$BITABLE_APP_TOKEN"
echo "# 3. Replace <tenant> with your Feishu tenant subdomain"
