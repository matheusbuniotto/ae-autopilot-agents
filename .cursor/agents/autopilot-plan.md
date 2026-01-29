---
description: "Classify task and generate plan if needed"
model: claude-opus-4-5
tools: ["Read", "Write", "Bash"]
---

# Autopilot Plan - Task Classification & Planning

## Purpose

Classify task complexity (L0-L3) and generate execution plan if needed.

**Stage:** plan
**Input:** Existing state from pull stage
**Output:** Classification result and plan (if L2+), state updated

## Status

**Phase 1 - Foundation (Current Phase)**

This skill is implemented in Phase 1 to establish classification heuristics and risk escalation for Silver layer tasks.

Core responsibilities:
- Load JIRA task and current state
- Analyze task for complexity signals
- Classify as L0-L3 based on heuristics
- Escalate Silver layer changes
- Generate structured plan for L2+ tasks
- Emit soft stop triggers if needed
- Persist classification and plan to state

## Implementation Details

### Classification Levels

The plan skill implements the L0-L3 classification framework from `docs/01_task_classification.md`:

- **L0:** Documentation only
- **L1:** Single model, low risk
- **L2:** Multi-model or medium risk
- **L3:** High risk or complex

### Silver Layer Escalation

Special handling for Silver layer models:

```
Base classification + risk escalation factors:
- Table size (row count)
- Downstream dependencies
- JOIN complexity
- Backfill requirements
- Schema changes
```

### Decision Tree

```
1. Any model changes? → L0 if no
2. How many models? → 1/2-5/6+ determine base level
3. Is Silver involved? → Escalate if yes
4. Check size/downstream → Apply additional escalation
5. Emit soft stops → If ambiguous logic or missing criteria
```

### Output Format

Classification results follow `shared/schemas/classification-schema.json`:

```json
{
  "task_id": "TSK-123",
  "classification_level": "L2",
  "signals": {
    "is_silver_layer": true,
    "downstream_model_count": 3,
    "affected_models": ["silver.orders"],
    "has_sql_changes": true,
    "sql_lines_of_code": 250,
    "join_count": 5,
    "requires_backfill": true,
    "risk_score": 65
  },
  "rationale": "Silver model with complex JOIN logic",
  "requires_plan": true,
  "classified_at": "2026-01-29T10:45:00Z"
}
```

## Planned Implementation Order

1. **Load state** - Verify pull stage completed
2. **Fetch task details** - From .autopilot/task.json
3. **Analyze JIRA description** - Extract signals
4. **Detect models** - Parse dbt files for affected models
5. **Run dbt analysis** - Get downstream impacts
6. **Classify** - Apply L0-L3 heuristics
7. **Generate plan** - If L2+ classification
8. **Persist** - Save classification.json to state
9. **Report** - Output classification results

## References

- Classification heuristics: `docs/01_task_classification.md`
- Schema: `shared/schemas/classification-schema.json`
- Prompts: `shared/prompts/classification.md`

## Next Phase

Phase 2 will implement full autopilot:plan skill with:
- Complete dbt integration for model detection
- Downstream impact analysis
- Full L0-L3 classification engine
- Structured plan generation for L2+ tasks

## See Also

- [Cursor skill](./autopilot-plan.md) (this file)
- [OpenCode command](../../.opencode/command/autopilot-plan.md)
- `docs/01_task_classification.md` - Classification details
- `shared/prompts/classification.md` - Heuristics and examples
