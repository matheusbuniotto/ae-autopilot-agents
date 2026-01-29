# Task Classification Prompts

This document provides reusable prompts and heuristics for L0-L3 task classification.

## Classification Levels

### L0: Documentation Only
- No SQL changes
- No model/test creation
- Examples: Update README, add comments, docs-only changes

**Signals:**
- No files in `models/` directory touched
- No dbt YML/SQL files modified
- Description mentions "doc", "comment", "readme", "typo"

### L1: Single Model, Low Risk
- Changes to one model (or one table + tests)
- Simple SQL (no joins, or few joins)
- No downstream impact
- No backfill needed

**Signals:**
- 1 model affected
- Downstream model count: 0
- Join count: 0-2
- Row count: < 1M (if Silver)
- No backfill keywords in description
- SQL lines of code: < 100

### L2: Multi-Model or Medium Risk
- Changes to 2-5 models
- Moderate SQL complexity
- Limited downstream impact
- Possible backfill needed

**Signals:**
- 2-5 models affected
- Downstream model count: 1-5
- Join count: 2-5
- Row count: 1M-10M (if Silver)
- May require backfill
- SQL lines of code: 100-500
- Silver layer involved

### L3: High Risk or Complex
- Changes to 6+ models
- Complex SQL or significant logic
- High downstream impact
- Backfill required
- Breaking changes possible

**Signals:**
- 6+ models affected
- Downstream model count: 5+
- Join count: 5+
- Row count: 10M+ (if Silver)
- Requires backfill
- SQL lines of code: 500+
- Involves multiple layers (Bronze, Silver, Gold)
- High business impact

## Silver Layer Risk Escalation

If ANY of these conditions are true for Silver models, escalate classification:

1. **Table Size:**
   - Row count > 5M: escalate by +1 level
   - Row count > 20M: escalate by +2 levels

2. **Downstream Dependencies:**
   - Downstream models > 10: escalate by +1 level
   - Downstream models > 20: escalate by +2 levels

3. **Schema Changes:**
   - Column removal: escalate by +2 levels
   - Column rename: escalate by +1 level
   - Type change on high-impact column: escalate by +1 level

4. **Logic Changes:**
   - JOIN logic changes: escalate by +1 level
   - Aggregation logic changes: escalate by +1 level
   - Filter logic removal: escalate by +2 levels

5. **Data Validation:**
   - No tests on affected table: escalate by +1 level
   - Removing existing tests: escalate by +2 levels

## Detection Heuristics

### Downstream Model Detection (via dbt)

```bash
# Get downstream models for a given model
dbt ls --select +model_name+ --output json | \
  jq '[.[] | select(.name != "model_name") | .name]' | \
  jq 'length'
```

### SQL Complexity Analysis

```bash
# Count JOIN keywords in SQL
grep -i "JOIN" models/silver/table.sql | wc -l

# Count SELECT statements (nested queries)
grep -i "SELECT" models/silver/table.sql | wc -l

# Estimate lines of code
wc -l models/silver/table.sql
```

### Table Size Detection (if dbt stats available)

```bash
# Check for row count in dbt sources or manifest
dbt parse  # generates manifest.json
jq '.nodes["model.project.model_name"].meta.row_count' target/manifest.json
```

## Decision Tree

```
START: New task T

1. Do any files in models/ or dbt YML change?
   NO  → L0 (Documentation only)
   YES → Go to 2

2. How many models are affected?
   1   → Go to 3
   2-5 → Go to 4
   6+  → L3 (High complexity)

3. Is the affected model in Silver?
   NO  → L1 (Bronze/Gold single model)
   YES → Go to 5

4. Are any Silver models affected?
   NO  → L2 (Multi-model, non-Silver)
   YES → Go to 6

5. Silver model size & complexity:
   Size < 1M, joins < 2, no backfill → L1
   Size 1-5M, joins 2-5 → L2
   Size > 5M OR joins > 5 → Escalate L2 → L3

6. Multi-model complexity check:
   Downstream > 10 OR Row count > 10M → Escalate → L3
   Otherwise → L2

END: Classification L0-L3 → Next stage
```

## Example Classifications

### Example 1: Add Column to Gold Model
```
Task: Add retention column to gold.customers
Models: 1 (gold.customers)
SQL: Simple SELECT with computed column (15 LOC)
Joins: 0 (it's a Gold model sourcing from Silver)
Downstream: 0 (no models depend on it)
Backfill: Not mentioned

Classification: L1
Reason: Single model, low complexity, no downstream impact
```

### Example 2: Refactor Silver Join
```
Task: Optimize join logic in silver.orders
Models: 1 (silver.orders) + 3 downstream (gold.revenue, gold.margin, reporting.dashboard)
SQL: JOIN logic refactored (250 LOC)
Joins: 5 (complex multi-table join)
Table size: 50M rows
Backfill: "Requires full reload of downstream models"
Downstream: 3

Classification: L2
Reason:
- Silver model affected (escalates base classification)
- Complex JOIN logic (5 joins)
- Moderate downstream (3 models)
- Size is significant but < 100M
- Backfill required but scoped
```

### Example 3: Massive Refactor
```
Task: Restructure data warehouse layers
Models: 12 total (3 Bronze, 6 Silver, 3 Gold)
SQL: Major logic changes across all layers
Joins: Varies, average 4 per model
Table sizes: 5M-500M across affected models
Backfill: "Full rebuild of Silver and Gold"
Downstream: 18+ models depend on affected tables

Classification: L3
Reason:
- 12 models affected (6+)
- Multiple layers (Bronze, Silver, Gold)
- High complexity (multi-layer refactor)
- Massive downstream (18+)
- Full rebuild required
```

## Soft Stop Triggers

Classification should emit soft stop triggers when:

1. **Ambiguous business logic:**
   - Example: "Optimize join" without clear definition
   - Action: Request clarification before proceeding

2. **Missing acceptance criteria:**
   - Example: No clear success metrics
   - Action: Request detailed acceptance criteria

3. **Risky operations on critical tables:**
   - Example: Column removal from high-impact Silver table
   - Action: Request confirmation + rollback plan

4. **Multi-phase required (L3 only):**
   - Example: 6+ models, requires phased rollout
   - Action: Generate multi-phase plan, await confirmation

## Output Format

Classification results must follow `classification-schema.json`:

```json
{
  "task_id": "TSK-123",
  "classification_level": "L2",
  "signals": {
    "is_silver_layer": true,
    "downstream_model_count": 3,
    "affected_models": ["silver.orders", "gold.revenue", "gold.margin"],
    "has_sql_changes": true,
    "sql_lines_of_code": 250,
    "join_count": 5,
    "table_row_count": 50000000,
    "requires_backfill": true,
    "risk_score": 65
  },
  "rationale": "Silver model with complex JOIN logic and moderate downstream impact requires structured planning",
  "requires_plan": true,
  "soft_stop_triggers": [],
  "classified_at": "2026-01-29T10:45:00Z"
}
```
