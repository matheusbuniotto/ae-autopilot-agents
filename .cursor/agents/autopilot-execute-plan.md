---
description: "Execute dbt/SQL changes based on plan. Triggers: /execute-plan, /execute, 'implement changes', 'do work'"
model: claude-3-5-sonnet
tools: ["Read", "Write", "Bash"]
---

# Autopilot Execute-Plan - Work Execution

## Purpose

Execute dbt model changes, tests, and documentation according to the generated plan.

**Stage:** execute-plan
**Input:** Plan from plan stage or inline instructions for L0/L1
**Output:** Commits made, dbt validation passed, state updated

## Execution Flow

### 1. Load State & Plan

Verify that the plan stage was completed successfully:

```bash
if [ ! -f ".autopilot/state.json" ]; then
  echo "❌ ERROR: No state file found. Run autopilot:pull first."
  exit 1
fi

STAGE=$(jq -r '.stage' .autopilot/state.json)
if [ "$STAGE" != "plan" ] && [ "$STAGE" != "execute-plan" ]; then
  echo "❌ ERROR: Previous stage not completed (current stage: $STAGE). Expected 'plan' or 'execute-plan'."
  exit 1
fi

CLASSIFICATION=$(jq -r '.classification' .autopilot/state.json)
echo "Classification: $CLASSIFICATION"
```

### 2. Determine Next Phase

If a structured plan exists, find the next incomplete phase:

```bash
HAS_PLAN=$(jq -r '.plan.exists // false' .autopilot/state.json)
if [ "$HAS_PLAN" = "true" ]; then
  # Find first phase in .plan.phases not in .plan.completed_phases
  NEXT_PHASE=$(jq -r '(.plan.phases - .plan.completed_phases)[0]' .autopilot/state.json)
  if [ "$NEXT_PHASE" = "null" ]; then
    echo "✅ All planned phases complete."
    exit 0
  fi
  echo "Starting Phase: $NEXT_PHASE"
else
  echo "Executing L0/L1 inline task."
fi
```

### 3. Execute Changes

This is where the agent performs the actual work.
**General Rules:**
- Follow existing SQL patterns in the repo.
- Follow dbt best practices.
- Ask user before creating new tests or documentation if not explicitly requested.

### 4. Validate Changes (dbt build)

After making changes, validate with dbt:

```bash
echo "Validating changes with dbt..."
# Target the affected models and their immediate downstreams
AFFECTED_MODELS=$(jq -r '.signals.affected_models | join(" ")' .autopilot/classification.json)
dbt build --select $AFFECTED_MODELS

if [ $? -ne 0 ]; then
  echo "❌ ERROR: dbt build failed."
  # State persistence for failure is handled by autopilot-core.mdc
  exit 1
fi
echo "✅ dbt build passed."
```

### 5. Create Atomic Commits

Create a commit for the completed work/phase:

```bash
# SAFETY: Never use 'git add .'
# Stage only the files we intended to change
STAGED_FILES=$(git diff --name-only)
if [ -z "$STAGED_FILES" ]; then
  echo "⚠️ No changes to commit."
else
  # Use deterministic commit message format
  TASK_ID=$(jq -r '.task_id' .autopilot/state.json)
  COMMIT_MSG="Feat - $TASK_ID – Executa alterações da fase $NEXT_PHASE"
  
  for file in $STAGED_FILES; do
    git add "$file"
  done
  
  git commit -m "$COMMIT_MSG"
  
  COMMIT_SHA=$(git rev-parse --short HEAD)
  echo "✅ Committed: $COMMIT_SHA"
fi
```

### 6. Update State

Record progress in the state file:

```bash
# Update completed_phases and stage
if [ "$HAS_PLAN" = "true" ]; then
  jq --arg phase "$NEXT_PHASE" \
     '.plan.completed_phases += [$phase] | .stage = "execute-plan"' \
     .autopilot/state.json > .autopilot/state.json.tmp && mv .autopilot/state.json.tmp .autopilot/state.json
else
  jq '.stage = "execute-plan"' .autopilot/state.json > .autopilot/state.json.tmp && mv .autopilot/state.json.tmp .autopilot/state.json
fi

# Record commit
jq --arg sha "$COMMIT_SHA" \
   --arg msg "$COMMIT_MSG" \
   --arg now "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
   '.commits += [{"sha": $sha, "message": $msg, "stage": "execute-plan", "timestamp": $now}]' \
   .autopilot/state.json > .autopilot/state.json.tmp && mv .autopilot/state.json.tmp .autopilot/state.json
```

### 7. Report Progress

```bash
echo ""
echo "✅ Execution update"
if [ "$HAS_PLAN" = "true" ]; then
  echo "   Phase complete: $NEXT_PHASE"
else
  echo "   Task execution complete."
fi
echo "   Commit: $COMMIT_SHA"
echo ""
echo "Next step: autopilot:execute-plan (for next phase) or autopilot:review"
echo ""
```

## Safety Rules Applied

✅ No `git add .` (GIT-02)
✅ Atomic commits (EXEC-04)
✅ Phase-based execution (EXEC-05)
✅ dbt validation (EXEC-06)
✅ State persistence (STATE-03)

## See Also

- `docs/03_failures_git_state.md` - Failure modes and recovery
- `shared/schemas/state-schema.json` - State file format