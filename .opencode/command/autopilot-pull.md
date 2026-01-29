---
description: "Pull JIRA task and prepare Git branch"
arguments: "$TASK_ID [$RELEASE_BRANCH]"
---

# Autopilot Pull - JIRA Task Intake (OpenCode)

## Usage

```bash
autopilot pull TSK-123
autopilot pull TSK-123 release/main
autopilot pull DAAENG-456 release/analytics
```

## Purpose

Pull JIRA task metadata and prepare Git branch for safe execution.

**Stage:** pull
**Input:** JIRA task ID (e.g., TSK-123)
**Output:** Task branch created, state initialized, ready for plan stage

## Implementation

This is the OpenCode platform version of the autopilot:pull skill. The logic is identical to the Cursor version, with OpenCode-specific invocation handling.

### Environment Variables

- `$TASK_ID` - JIRA task identifier (required)
- `$RELEASE_BRANCH` - Git branch to create from (optional, default: release/main)

### Entry Point

```bash
#!/bin/bash

TASK_ID="${1:-}"
RELEASE_BRANCH="${2:-release/main}"

if [ -z "$TASK_ID" ]; then
  echo "Usage: autopilot pull <TASK_ID> [RELEASE_BRANCH]"
  echo ""
  echo "Examples:"
  echo "  autopilot pull TSK-123"
  echo "  autopilot pull TSK-123 release/main"
  exit 1
fi
```

### Core Logic (Same as Cursor Version)

See the Cursor version at `.cursor/agents/autopilot-pull.md` for the complete implementation.

The logic flow is:

1. Initialize state (or load existing)
2. Validate task ID format
3. Fetch JIRA task metadata
4. Fetch release branch and validate it's current
5. Create task branch
6. Initialize task metadata
7. Update state to complete pull
8. Report success

### OpenCode-Specific Handling

OpenCode commands use standard shell script conventions:

```bash
# Arguments are positional
TASK_ID=$1
RELEASE_BRANCH=${2:-release/main}

# Exit codes
exit 0  # Success
exit 1  # Error (soft stop)
exit 2  # Hard stop

# Output goes to stdout
echo "✅ Pull complete"

# Errors go to stderr
echo "❌ ERROR: ..." >&2
```

## Error Handling

All error patterns from the Cursor version apply:

### Hard Stops (exit 2)
- Invalid task ID format
- JIRA task cannot be fetched
- Release branch out of sync
- Task branch exists with changes

### Soft Stops (exit 1)
- (None for pull stage)

### Success (exit 0)
- State initialized
- Branch created
- Task metadata saved

## State Files

Same as Cursor version:

**Created:**
- `.autopilot/state.json` - Execution state
- `.autopilot/task.json` - JIRA metadata

**Modified:**
- Git branch created: `$TASK_ID`

## Safety Rules

Same as Cursor version:

✅ Release branch sync check (SAFETY-01)
✅ Task branch existence check (SAFETY-01)
✅ JIRA task validation (GIT-01)
✅ Atomic state initialization (STATE-01)

## Integration with Cursor

The OpenCode version of autopilot:pull performs identically to the Cursor version. Both use the same underlying logic:

- Same state schema
- Same error messages
- Same safety checks
- Same Git operations

This ensures consistent behavior across platforms.

## Next Steps

After pull completes:

```bash
autopilot plan TSK-123
```

## See Also

- Cursor version: `.cursor/agents/autopilot-pull.md`
- `docs/03_failures_git_state.md` - Failure modes and safety rules
- `.cursor/rules/git-safety.mdc` - Git safety enforcement
- `shared/schemas/state-schema.json` - State file format
