# lark-cli Bitable + 画板 + 妙记 9 个坑

> 来源：2026-05-12 N=1 dry-run 全链 25 分钟实测（妙记 → Bitable → 综合页 → 画板）。
> 同步沉淀在 `feedback_lark_cli_bitable_whiteboard_pitfalls.md`。

每个坑都标注：**症状** / **根因** / **修法**。下次直接搜索使用。

---

## 1. `multi_select` 类型不存在

**症状**：`{"type":"multi_select"}` → API 报 `Invalid discriminator value. Expected 'text' | 'number' | 'select' ...`

**根因**：lark-cli base 只接受 16 种 type（详见 schema-t01-concepts.md）。多选不是独立类型，是 select + `multiple:true`。

**修法**：
```json
{"name":"lens","type":"select","multiple":true,"options":[...]}
```

**关键**：`multiple` 在**顶层**，不是 `property.multiple`。

---

## 2. `field-update` 不接受 `property` 字段

**症状**：把单选改多选用 `field-update --json '{...property:{multiple:true}}'` → API 报 `Unrecognized key(s) in object: 'property'`

**根因**：v2 API 在 field-update 通道不接受 property 子对象。

**修法**：**delete + recreate**。
```bash
lark-cli base +field-delete --base-token <T> --table-id <T> --field-id <name> --yes
lark-cli base +field-create --base-token <T> --table-id <T> --json '<new schema>'
```

---

## 3. URL 字段在 field-list 输出里显示为 text

**症状**：创建时用 `{"type":"url"}` 成功，但 `field-list` 显示 `"type":"text"`。

**根因**：飞书内部把 url/phone 等都存为 text 子类型。

**修法**：不用修。**只要写入时 cell value 是合法 URL 字符串，飞书前端会正确渲染**。

---

## 4. `field-delete` 必须显式 `--yes`

**症状**：`field-delete` 默认拒绝 → `add --yes to confirm`

**修法**：高风险操作必须 `--yes`。

---

## 5. `user` 字段创建别带 property

**症状**：`{"type":"user","property":{"multiple":false}}` → 创建失败

**修法**：直接 `{"name":"maintainer","type":"user"}`，飞书默认多选。要单选用 `multiple:false` 顶层属性。

---

## 6. lark-cli 合法 field type 完整 16 种

```
text | number | select | datetime | created_at | updated_at |
user | group_chat | created_by | updated_by |
link | formula | lookup | auto_number | attachment | location | checkbox
```

**不存在**：`multi_select` / `url` / `phone` / `email` / `barcode` / `progress` / `rating`（这些都被 text/number 替代或在 style 字段里配置）。

---

## 7. `docs +update v2` 遇到 EOF

**症状**：
```
Error: Put "https://open.feishu.cn/open-apis/docs_ai/v1/documents/<token>": EOF
```

**根因**：HTTPS_PROXY（127.0.0.1:7897）会断 v2 长请求。

**修法**：所有 `docs +update --api-version v2` 和 `whiteboard +update` 命令前置：
```bash
LARK_CLI_NO_PROXY=1 lark-cli docs +update --api-version v2 ...
```

**注意**：只 v2 受影响，v1 不会。但 v1 已 deprecated。

---

## 8. 妙记转写在 `vc` skill 不在 `minutes` skill

**症状**：`lark-cli minutes` 子命令只有 `+search` / `+download` / `minutes get`，**没有** transcript export。

**修法**：用 vc skill：
```bash
lark-cli vc +notes --minute-tokens <T> --output-dir ./transcripts
```

转写文件路径：`./transcripts/artifact-<title>-<token>/transcript.txt`

---

## 9. `vc +notes --output-dir` 必须相对路径

**症状**：
```bash
lark-cli vc +notes --output-dir /tmp/xxx
# Error: --output must be a relative path within the current directory
```

**修法**：
```bash
cd /tmp/expert-brain-2026-05-12 && \
lark-cli vc +notes --minute-tokens <T> --output-dir ./transcripts
```

---

## 10. 画板（whiteboard）专门坑

### 10.1 `whiteboard +update` 必须 `--yes`

```
Error: high-risk operation requires confirmation
add --yes to confirm
```

### 10.2 token 用 `--whiteboard-token` 不能裸位置参数

```bash
# 错误
lark-cli whiteboard +update <token> --source - --input_format mermaid

# 正确
lark-cli whiteboard +update --whiteboard-token <token> --source - --input_format mermaid --yes
```

### 10.3 画板的 mermaid 不支持 classDef / 标签内 `|` 分隔

**症状**：
```
Parse error on line N:
...OSA,LX,WP workunit
---------------------^
Expecting 'LINK', 'UNICODE_TEXT', 'EDGE_TEXT', got '1'
```

**修法**：
- ❌ `classDef synth fill:#FFD966,...` → 删除
- ❌ `N1 -.约束| OSA` → 改成 `N1 -->|约束| OSA`
- ✅ 用 `-->|label|` 紧贴写法
- ✅ 简单 graph TD + 节点 + 边 + label，**不要花哨语法**

### 10.4 画板必须通过 docx 占位创建

不能直接建 board 类型节点（wiki +node-create 的 obj-type 里没有 board）。流程：
```bash
# 1. 建 docx wrapper
lark-cli wiki +node-create --obj-type docx --title <name>

# 2. docx +update 插占位
LARK_CLI_NO_PROXY=1 lark-cli docs +update --api-version v2 --doc <docx_token> \
  --command overwrite --doc-format markdown \
  --content '<whiteboard type="blank"></whiteboard>'

# 3. 从响应 data.document.new_blocks[].block_token 取 board_token

# 4. 用 board_token 写 mermaid
cat g.mmd | LARK_CLI_NO_PROXY=1 lark-cli whiteboard +update \
  --whiteboard-token <board_token> --source - --input_format mermaid --overwrite --yes
```

---

## 排错优先级

遇到错误按这个顺序检查：
1. token 过期？ → `lark-cli auth status` / `lark-cli auth login --scope ...`
2. 网络代理？ → 加 `LARK_CLI_NO_PROXY=1`
3. high-risk 操作？ → 加 `--yes`
4. 字段类型错？ → 查本文坑 1-6
5. 路径错？ → 查坑 9
6. 工具找错 skill？ → 查坑 8
