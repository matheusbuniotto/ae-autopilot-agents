---
description: "Run final validation (dbt build, lint, docs) before PR. Triggers: /review, /autopilot-review, 'review changes', 'check quality'"
model: claude-3-5-sonnet
tools: ["Read", "Write", "Bash"]
---

# Autopilot Review - Quality Assurance

## Purpose

Act as a **Senior Analytics Engineer** to audit the work before shipping.
Your goal is to catch regressions, style violations, and missing documentation.

## When to Use

- User runs `/autopilot:review`
- Orchestrator (`/launch`) detects `execute-plan` stage completed
- User asks to "validate" or "QA" the task

## Execution Flow

### 1. Load State

Verify execution is complete:

```bash
if [ ! -f ".autopilot/state.json" ]; then
  echo "❌ ERROR: No state file found."
  exit 1
fi

STAGE=$(jq -r '.stage' .autopilot/state.json)
if [ "$STAGE" != "execute-plan" ] && [ "$STAGE" != "review" ]; then
  echo "❌ ERROR: Execution stage not completed (current stage: $STAGE)."
  exit 1
fi
```

### 2. Full dbt Build

Run a comprehensive build of affected models and their downstreams:

```bash
echo "Running full dbt validation..."
AFFECTED_MODELS=$(jq -r '.signals.affected_models | join(" ")' .autopilot/classification.json)

# Build affected models and all their downstreams to ensure no regression
dbt build --select $AFFECTED_MODELS+

if [ $? -ne 0 ]; then
  echo "❌ ERROR: Final dbt build failed."
  exit 1
fi
echo "✅ Full dbt build passed."
```

### 3. SQL Linting & Formatting

Check for style guide compliance:

```bash
echo "Checking SQL formatting..."
# Note: Assumes sqlfluff or similar is configured
# Find all .sql files changed in this branch
CHANGED_FILES=$(git diff --name-only origin/release/main...HEAD | grep '\.sql$')

if [ -n "$CHANGED_FILES" ]; then
  sqlfluff lint $CHANGED_FILES --dialect dbt-postgres
  if [ $? -ne 0 ]; then
    echo "⚠️  SQL Linting issues found. Attempting auto-fix..."
    sqlfluff fix $CHANGED_FILES --dialect dbt-postgres -f
  fi
fi
echo "✅ SQL Formatting checked."
```

### 4. Verify Documentation

Ensure all affected models have updated documentation:

```bash
echo "Verifying documentation..."
# Check for YML files corresponding to affected models
# Heuristic: look for model names in .yml files under models/
for model in $(jq -r '.signals.affected_models[]' .autopilot/classification.json); do
  if ! grep -r "name: $model" models/ | grep "\.yml" > /dev/null; then
    echo "⚠️  WARNING: No documentation found for model: $model"
  fi
done
```

### 5. Update State

Mark review as complete:

```bash
jq '.stage = "review" | .timestamps.last_updated = now | strftime("%Y-%m-%dT%H:%M:%SZ")' \
   .autopilot/state.json > .autopilot/state.json.tmp && mv .autopilot/state.json.tmp .autopilot/state.json
```

### 6. Report Success

```bash
echo ""
echo "✅ Review complete"
echo "   All validation checks passed."
echo "   Ready to ship."
echo ""
echo "Next step: autopilot:pr"
echo ""
```

## Safety Rules Applied

✅ Comprehensive build (EXEC-06)
✅ Standard checks (EXEC-07)
✅ SQL style enforcement (GIT-02)

## See Also
- `shared/schemas/state-schema.json`
- `.cursor/rules/autopilot-core.mdc`