---
description: "Pull JIRA task metadata and initialize Git branch. Triggers: /pull, /autopilot-pull, 'start task', 'pull task'"
model: claude-3-5-haiku
tools: ["Read", "Write", "Bash"]
---

# Autopilot Pull - JIRA Task Intake

## Purpose

Act as a **Senior Analytics Engineer** to safely initialize a new unit of work.
Your goal is to fetch intent from JIRA and prepare a clean, isolated Git workspace.

## When to Use

- User runs `/autopilot:pull TSK-123`
- User asks to "start task TSK-123"
- Orchestrator (`/launch`) detects `none` stage

## Execution Flow

### 1. Initialize State (or Load Existing)

Check if state already exists for this task:

```bash
if [ -f ".autopilot/state.json" ]; then
  TASK_ID=$(jq -r '.task_id' .autopilot/state.json 2>/dev/null)
  if [ "$TASK_ID" != "$1" ]; then
    echo "❌ ERROR: Different task already in progress"
    exit 1
  fi
  # Resume from existing state
  STAGE=$(jq -r '.stage' .autopilot/state.json)
  if [ "$STAGE" != "pull" ]; then
    echo "State shows stage=$STAGE, resuming from there"
    exit 0
  fi
fi
```

If new task, initialize state file:

```bash
mkdir -p .autopilot

jq -n \
  --arg task_id "$1" \
  --arg branch "$1" \
  '{
    "task_id": $task_id,
    "branch": $branch,
    "stage": "pull",
    "timestamps": {
      "started_at": now | strftime("%Y-%m-%dT%H:%M:%SZ"),
      "last_updated": now | strftime("%Y-%m-%dT%H:%M:%SZ")
    }
  }' > .autopilot/state.json
```

### 2. Validate Task ID Format

Task ID must follow pattern: `[A-Z]+-[0-9]+`

```bash
TASK_ID=$1

if ! echo "$TASK_ID" | grep -E '^[A-Z]+-[0-9]+$' > /dev/null; then
  echo "❌ HARD STOP: Invalid task ID format: $TASK_ID"
  echo ""
  echo "Expected format: PROJECT-NUMBER (e.g., TSK-123, DAAENG-456)"
  echo ""
  echo "Valid examples:"
  echo "  ✅ TSK-123"
  echo "  ✅ DAAENG-456"
  echo ""
  echo "Invalid examples:"
  echo "  ❌ TSK123 (missing dash)"
  echo "  ❌ tsk-123 (lowercase)"
  echo "  ❌ feature/my-feature (not JIRA format)"
  exit 1
fi
```

### 3. Fetch JIRA Task Metadata

Use JIRA MCP to fetch task details:

```bash
# Note: Actual implementation depends on available JIRA MCP tools
# This is a template for the expected flow

JIRA_RESPONSE=$(jira get-issue "$TASK_ID")

if [ $? -ne 0 ]; then
  echo "❌ HARD STOP: Cannot fetch JIRA task $TASK_ID"
  echo ""
  echo "The JIRA task could not be found or fetched."
  echo "Possible reasons:"
  echo "  - Task ID doesn't exist in JIRA"
  echo "  - JIRA connection is not configured"
  echo "  - You don't have access to this project"
  echo ""
  echo "Actions:"
  echo "1. Verify task exists: https://jira.company.com/browse/$TASK_ID"
  echo "2. Check JIRA credentials: jira config"
  echo "3. Retry: autopilot:pull $TASK_ID"
  exit 1
fi

# Validate JIRA response has required fields
if ! echo "$JIRA_RESPONSE" | jq -e '.key,.summary,.description' > /dev/null 2>&1; then
  echo "❌ HARD STOP: JIRA task response is incomplete"
  echo ""
  echo "The task was fetched but is missing required fields:"
  echo "  - task key"
  echo "  - summary"
  echo "  - description"
  echo ""
  echo "Actions:"
  echo "1. Open task: https://jira.company.com/browse/$TASK_ID"
  echo "2. Verify all fields are filled"
  echo "3. Retry: autopilot:pull $TASK_ID"
  exit 1
fi

# Save task metadata
mkdir -p .autopilot
echo "$JIRA_RESPONSE" | jq '.' > .autopilot/task.json
```

### 4. Fetch Release Branch

Ensure release branch is current before creating task branch:

```bash
echo "Fetching release branch..."
git fetch origin

RELEASE_BRANCH="${2:-release/main}"

# Verify release branch exists
if ! git rev-parse origin/$RELEASE_BRANCH > /dev/null 2>&1; then
  echo "❌ HARD STOP: Release branch not found: $RELEASE_BRANCH"
  echo ""
  echo "Possible reasons:"
  echo "  - Branch name is wrong"
  echo "  - Origin remote is not configured"
  echo "  - You don't have access to this branch"
  echo ""
  echo "Actions:"
  echo "1. List available branches: git branch -r | grep release"
  echo "2. Verify branch name: $RELEASE_BRANCH"
  echo "3. Retry with correct branch: autopilot:pull $TASK_ID <branch>"
  exit 1
fi

# Check if local release branch matches remote
LOCAL_SHA=$(git rev-parse $RELEASE_BRANCH 2>/dev/null || echo "")
REMOTE_SHA=$(git rev-parse origin/$RELEASE_BRANCH)

if [ "$LOCAL_SHA" != "$REMOTE_SHA" ]; then
  echo "❌ HARD STOP: Release branch is out of sync"
  echo ""
  echo "Your local $RELEASE_BRANCH is behind origin/$RELEASE_BRANCH"
  echo ""
  echo "Local SHA:  $LOCAL_SHA"
  echo "Remote SHA: $REMOTE_SHA"
  echo ""
  echo "This prevents safe task branch creation."
  echo ""
  echo "Actions:"
  echo "1. Abort this operation (optional)"
  echo "2. Update your release branch: git pull origin $RELEASE_BRANCH"
  echo "3. Retry: autopilot:pull $TASK_ID"
  exit 1
fi
```

### 5. Create Task Branch

Create branch from release branch with exact task ID:

```bash
TASK_ID=$1
RELEASE_BRANCH="${2:-release/main}"

# Check if branch already exists
if git rev-parse --verify "$TASK_ID" > /dev/null 2>&1; then
  echo "⚠️  Branch $TASK_ID already exists"
  echo ""
  echo "Checking if it has uncommitted changes..."

  if ! git diff-index --quiet "$TASK_ID" --; then
    echo ""
    echo "❌ HARD STOP: Task branch has uncommitted changes"
    echo ""
    echo "Branch: $TASK_ID"
    echo "Uncommitted files:"
    git diff-index --name-only "$TASK_ID"
    echo ""
    echo "Cannot proceed safely - would lose or corrupt changes."
    echo ""
    echo "Actions:"
    echo "1. Review changes: git diff"
    echo "2. Commit changes: git add <files> && git commit -m '...'"
    echo "3. Retry: autopilot:launch $TASK_ID"
    exit 1
  else
    echo "✅ Branch exists with no uncommitted changes"
    echo "   Resuming work on existing branch"
    git switch "$TASK_ID"
    exit 0
  fi
fi

# Create new branch from release branch
echo "Creating branch: $TASK_ID"
git switch -c "$TASK_ID" origin/"$RELEASE_BRANCH"

if [ $? -ne 0 ]; then
  echo "❌ ERROR: Failed to create branch $TASK_ID"
  exit 1
fi

echo "✅ Branch created: $TASK_ID"
git branch -v | grep "$TASK_ID"
```

### 6. Initialize Task Metadata

Save JIRA task details for reference:

```bash
# Extract and save key metadata
SUMMARY=$(jq -r '.summary' .autopilot/task.json)
DESCRIPTION=$(jq -r '.description' .autopilot/task.json)
KEY=$(jq -r '.key' .autopilot/task.json)

echo ""
echo "Task metadata:"
echo "  Key: $KEY"
echo "  Summary: $SUMMARY"
echo ""
```

### 7. Update State to Complete Pull

Mark pull stage as complete:

```bash
jq \
  --arg now "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  '.stage = "pull" | .timestamps.last_updated = $now' \
  .autopilot/state.json > .autopilot/state.json.tmp && \
  mv .autopilot/state.json.tmp .autopilot/state.json

echo "✅ State saved: .autopilot/state.json"
```

### 8. Report Success

Print clear next steps:

```bash
echo ""
echo "✅ Pull complete"
echo "   Task: $TASK_ID"
echo "   Summary: $SUMMARY"
echo "   Branch: $TASK_ID (created from origin/$RELEASE_BRANCH)"
echo "   State: .autopilot/state.json"
echo ""
echo "Next step: autopilot:plan $TASK_ID"
echo ""
```

## Error Recovery

### If Pull Fails

1. **State is saved** - You can retry safely
2. **Branch may be partially created** - Check with `git branch`
3. **Run pull again** - It will resume or recover

### Common Issues

**Issue:** "Task not found"
- **Fix:** Verify task ID in JIRA browser first
- **Retry:** `autopilot:pull <correct-id>`

**Issue:** "Release branch out of sync"
- **Fix:** `git pull origin release/main` then retry
- **Retry:** `autopilot:pull $TASK_ID`

**Issue:** "Branch already exists"
- **Fix:** Task already pulled; resuming work
- **Retry:** `autopilot:launch $TASK_ID` to continue

## Files Modified

**Created:**
- `.autopilot/state.json` - Execution state
- `.autopilot/task.json` - JIRA metadata

**Modified:**
- Git branch created: `$TASK_ID`

## Safety Rules Applied

✅ Release branch sync check (SAFETY-01)
✅ Task branch existence check (SAFETY-01)
✅ JIRA task validation (GIT-01)
✅ Atomic state initialization (STATE-01)

## See Also

- `.cursor/rules/git-safety.mdc` - Git safety enforcement
- `shared/schemas/state-schema.json` - State file format
- `shared/schemas/task-schema.json` - Task metadata format
