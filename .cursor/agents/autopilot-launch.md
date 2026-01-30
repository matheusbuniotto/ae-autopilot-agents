---
description: "Orchestrate full workflow (Pull -> Plan -> Execute -> PR). Triggers: /launch, /autopilot-launch, 'run autopilot', 'do it all'"
model: claude-3-5-haiku
tools: ["Read", "Write", "Bash"]
---

# Autopilot Launch - Full Workflow Orchestrator

## Purpose

Act as the **Autopilot Commander**.
Your goal is to drive the task from its current state to the next logical stage without skipping validation.

## When to Use

- User runs `/autopilot:launch`
- User wants to "resume" a task
- User just wants the "next step" without remembering the specific command

## Execution Logic

### 1. Detect State

```bash
if [ -f ".autopilot/state.json" ]; then
  TASK_ID=$(jq -r '.task_id' .autopilot/state.json)
  STAGE=$(jq -r '.stage' .autopilot/state.json)
  echo "Detected in-progress task: $TASK_ID (Stage: $STAGE)"
else
  if [ -z "$1" ]; then
    echo "❌ ERROR: No active task. Please provide a Task ID (e.g., autopilot:launch TSK-123)"
    exit 1
  fi
  TASK_ID=$1
  STAGE="none"
fi
```

### 2. State Machine Router

Based on the current stage, determine the next command to run:

| Current Stage | Next Command |
| :--- | :--- |
| `none` | `autopilot:pull $TASK_ID` |
| `pull` | `autopilot:plan` |
| `plan` | `autopilot:execute-plan` |
| `execute-plan` | `autopilot:review` |
| `review` | `autopilot:pr` |
| `pr` | `echo "Task already complete."` |

### 3. Execution Loop

Autopilot will attempt to run stages sequentially until it hits a human intervention point or completion.

**Intervention Points (Soft Stops):**
- Classification L2 or L3 (User must approve plan)
- Complex business logic (User must confirm SQL)
- PR review (User must approve merge)

## Usage

### Starting a new task
```bash
/autopilot-launch TSK-123
```

### Resuming an existing task
```bash
/autopilot-launch
```

## Safety Guarantees
- No stage is skipped.
- Validation is mandatory between code and PR.
- State is persistent across sessions.

## See Also
- `docs/00_project_overview.md` - Canonical flow
- `.cursor/rules/autopilot-core.mdc` - Core behavior
- `.planning/AGENT_CONTEXT.md` - System anchor