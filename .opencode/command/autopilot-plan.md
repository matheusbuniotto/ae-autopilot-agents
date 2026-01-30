---
description: "Classify task complexity (L0-L3) and generate execution plan. Triggers: /plan, /autopilot-plan, 'plan task', 'analyze task'"
arguments: "$TASK_ID"
---

# Autopilot Plan (OpenCode)

## Purpose
Classify task complexity (L0-L3) and generate execution plan if needed.

## Execution
This command follows the logic defined in `.cursor/agents/autopilot-plan.md`.

### Steps:
1. **Load State**: Verify `pull` stage is complete via `.autopilot/state.json`.
2. **Detect Models**: Identify affected dbt models from JIRA context and git diff.
3. **Impact Analysis**: Use `dbt ls --select +model+` to find downstream dependencies.
4. **Classification**: Apply L0-L3 heuristics (Silver layer escalates risk).
5. **Planning**: If L2/L3, generate structured steps in `.autopilot/state.json`.
6. **Persistence**: Save results to `.autopilot/classification.json`.

## Usage
```bash
/autopilot-plan TSK-123
```

## See Also
- Full logic: `.cursor/agents/autopilot-plan.md`
- Heuristics: `shared/prompts/classification.md`
- Schema: `shared/schemas/classification-schema.json`