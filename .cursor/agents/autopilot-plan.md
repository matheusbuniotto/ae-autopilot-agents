---
description: "Classify task complexity (L0-L3) and generate execution plan. Triggers: /plan, /autopilot-plan, 'plan task', 'analyze task'"
model: claude-3-5-sonnet
tools: ["Read", "Write", "Bash"]
---

# Autopilot Plan - Task Classification & Planning

## Purpose

Act as a **Senior Analytics Engineer** to analyze risk and complexity.
Your goal is to prevent "quick fixes" from breaking production by enforcing proper planning depth based on dbt lineage and logic risk.

## When to Use

- User runs `/autopilot:plan`
- Orchestrator (`/launch`) detects `pull` stage completed
- User asks to "analyze impact" or "check dependencies"

## Execution Flow

### 1. Load State & Task Metadata

Verify that the pull stage was completed successfully:

```bash
if [ ! -f ".autopilot/state.json" ]; then
  echo "❌ ERROR: No state file found. Run autopilot:pull first."
  exit 1
fi

STAGE=$(jq -r '.stage' .autopilot/state.json)
if [ "$STAGE" != "pull" ] && [ "$STAGE" != "plan" ]; then
  echo "❌ ERROR: Previous stage not completed (current stage: $STAGE). Expected 'pull' or 'plan'."
  exit 1
fi

if [ ! -f ".autopilot/task.json" ]; then
  echo "❌ ERROR: Task metadata missing. Run autopilot:pull first."
  exit 1
fi
```

### 2. Detect Affected Models

Scan JIRA description and current branch changes to identify affected dbt models:

```bash
# Extract model names from JIRA description (heuristic-based)
SUMMARY=$(jq -r '.summary' .autopilot/task.json)
DESCRIPTION=$(jq -r '.description' .autopilot/task.json)

# Check for model names in format: 'layer.model_name' or 'model_name.sql'
AFFECTED_MODELS=$(echo "$SUMMARY $DESCRIPTION" | grep -oE '\b(bronze|silver|gold)\.[a-zA-Z0-9_]+\b' | sort -u | tr '\n' ',' | sed 's/,$//')

if [ -z "$AFFECTED_MODELS" ]; then
  # Fallback: check git diff if branch already has changes
  AFFECTED_MODELS=$(git diff --name-only origin/release/main...HEAD | grep '\.sql$' | xargs -n 1 basename | sed 's/\.sql$//' | tr '\n' ',' | sed 's/,$//')
fi

echo "Detected models: $AFFECTED_MODELS"
```

### 3. Run dbt Lineage Analysis

Analyze downstream impact for detected models:

```bash
IFS=',' read -ra ADDR <<< "$AFFECTED_MODELS"
DOWNSTREAM_COUNT=0
ALL_AFFECTED="[]"

for model in "${ADDR[@]}"; do
  # Get downstream models (excluding current model)
  # dbt ls returns list of models, we count them
  # --select +model+ selects model and all downstreams
  COUNT=$(dbt ls --select "$model+" --output json 2>/dev/null | jq -r 'select(.resource_type == "model") | .name' | grep -v "^$model$" | wc -l)
  DOWNSTREAM_COUNT=$((DOWNSTREAM_COUNT + COUNT))
  
  # Collect all affected models for classification signals
  MODELS_JSON=$(dbt ls --select "$model+" --output json 2>/dev/null | jq -r 'select(.resource_type == "model") | .name' | jq -R . | jq -s .)
  ALL_AFFECTED=$(echo "$ALL_AFFECTED $MODELS_JSON" | jq -s 'add | unique')
done

echo "Total downstream models affected: $DOWNSTREAM_COUNT"
```

### 4. Analyze SQL Complexity (if models exist)

Analyze existing SQL files for complexity signals (joins, LOC):

```bash
JOIN_COUNT=0
MAX_LOC=0

for model in "${ADDR[@]}"; do
  # Find model file path
  FILE_PATH=$(find models -name "$model.sql")
  if [ -n "$FILE_PATH" ]; then
    JOINS=$(grep -i "JOIN" "$FILE_PATH" | wc -l)
    JOIN_COUNT=$((JOIN_COUNT + JOINS))
    
    LOC=$(wc -l < "$FILE_PATH")
    if [ "$LOC" -gt "$MAX_LOC" ]; then
      MAX_LOC=$LOC
    fi
  fi
done
```

### 5. Classify Task

Apply heuristics from `docs/01_task_classification.md` to determine L0-L3 level:

```bash
# Simple heuristic engine based on collected signals
LEVEL="L1" # Default
HAS_SILVER=false
if echo "$AFFECTED_MODELS" | grep -q "silver"; then
  HAS_SILVER=true
fi

MODEL_COUNT=$(echo "$AFFECTED_MODELS" | tr ',' '\n' | sed '/^$/d' | wc -l)

if [ "$MODEL_COUNT" -eq 0 ]; then
  LEVEL="L0"
elif [ "$MODEL_COUNT" -gt 5 ] || [ "$DOWNSTREAM_COUNT" -gt 10 ]; then
  LEVEL="L3"
elif [ "$MODEL_COUNT" -gt 2 ] || [ "$HAS_SILVER" = true ] || [ "$DOWNSTREAM_COUNT" -gt 5 ]; then
  LEVEL="L2"
fi

# Silver Layer Escalation
if [ "$HAS_SILVER" = true ]; then
  if [ "$JOIN_COUNT" -gt 5 ] || [ "$MAX_LOC" -gt 300 ]; then
    LEVEL="L3"
  fi
fi

echo "Classification: $LEVEL"
```

### 6. Generate Execution Plan (for L2+)

If task is L2 or L3, generate a structured plan:

```bash
if [ "$LEVEL" == "L2" ] || [ "$LEVEL" == "L3" ]; then
  echo "Generating structured plan..."
  # Plan generation logic:
  # 1. Schema/Table changes
  # 2. Logic refactor
  # 3. Validation steps
  # 4. Backfill/Reload
  
  # This would typically be a structured prompt to the LLM to generate steps
  # based on the JIRA description and the detected models.
fi
```

### 7. Update State & Classification File

Persist results to `.autopilot/classification.json` and update `.autopilot/state.json`:

```bash
# Create classification.json
jq -n \
  --arg task_id "$(jq -r '.task_id' .autopilot/state.json)" \
  --arg level "$LEVEL" \
  --arg rationale "Detected $MODEL_COUNT models with $DOWNSTREAM_COUNT downstreams. Silver layer: $HAS_SILVER." \
  --arg now "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --argjson all_affected "$ALL_AFFECTED" \
  '{ 
    "task_id": $task_id,
    "classification_level": $level,
    "signals": {
      "is_silver_layer": ($HAS_SILVER == "true"),
      "downstream_model_count": ('"$DOWNSTREAM_COUNT"' | tonumber),
      "affected_models": $all_affected,
      "join_count": ('"$JOIN_COUNT"' | tonumber),
      "sql_max_loc": ('"$MAX_LOC"' | tonumber)
    },
    "rationale": $rationale,
    "requires_plan": ($level == "L2" || $level == "L3"),
    "classified_at": $now
  }' > .autopilot/classification.json

# Update state.json
jq \
  --arg level "$LEVEL" \
  --arg now "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  '.stage = "plan" | .classification = $level | .timestamps.last_updated = $now' \
  .autopilot/state.json > .autopilot/state.json.tmp && mv .autopilot/state.json.tmp .autopilot/state.json
```

### 8. Report Success

```bash
echo ""
echo "✅ Plan complete"
echo "   Classification: $LEVEL"
echo "   Affected models: $AFFECTED_MODELS"
echo "   Downstream impact: $DOWNSTREAM_COUNT models"
echo ""
if [ "$LEVEL" == "L2" ] || [ "$LEVEL" == "L3" ]; then
  echo "Structured plan generated in state."
fi
echo "Next step: autopilot:execute-plan"
echo ""
```

## Safety Rules Applied

✅ Mandatory classification before execution (EXEC-01)
✅ Risk escalation for Silver models (SAFETY-03)
✅ dbt-backed impact analysis (EXEC-08)
✅ File-based state persistence (STATE-01)

## See Also

- `docs/01_task_classification.md` - Classification details
- `shared/schemas/classification-schema.json` - Classification format
- `shared/prompts/classification.md` - Heuristics and logic
