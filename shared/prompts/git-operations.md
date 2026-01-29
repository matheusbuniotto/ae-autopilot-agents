# Git Operations - Safe Defaults

This document provides reusable prompts and templates for safe Git operations in Autopilot.

## Safe Git Commands

### Fetch and Validate Release Branch

```bash
# Always fetch latest from origin
git fetch origin

# Verify release branch is up-to-date with remote
git rev-parse origin/release/main > /tmp/remote_sha.txt
git rev-parse release/main > /tmp/local_sha.txt

if ! diff /tmp/remote_sha.txt /tmp/local_sha.txt > /dev/null; then
  echo "ERROR: Release branch is out of sync with origin/release/main"
  echo "Local:  $(cat /tmp/local_sha.txt)"
  echo "Remote: $(cat /tmp/remote_sha.txt)"
  exit 1
fi
```

### Create Task Branch

```bash
# Always create from remote to ensure clean state
git switch -c TSK-123 origin/release/main
```

### Stage Files Explicitly

```bash
# GOOD - explicit staging
git add models/silver/orders.sql
git add models/silver/schema.yml

# Bad patterns to never use
# ❌ git add .
# ❌ git add -A
# ❌ git add -u
```

### Commit with Clear Message

```bash
git commit -m "Add freshness test to silver.orders

- Detects missing data on 24-hour lag
- Alerts analytics@company.com on failure
- Applies to all environments

Co-Authored-By: Autopilot <noreply@autopilot.com>"
```

### Detect and Prevent Dangerous Operations

```bash
# Check for dangerous patterns in command history
if grep -q "git add \." /tmp/autopilot_commands.log; then
  echo "ERROR: Detected 'git add .' usage"
  exit 1
fi

if grep -q "git push --force" /tmp/autopilot_commands.log; then
  echo "ERROR: Detected force-push attempt"
  exit 1
fi

if grep -q "git rebase -i\|git commit --amend" /tmp/autopilot_commands.log; then
  echo "ERROR: Detected history rewriting attempt"
  exit 1
fi
```

## Branch Naming

Task branch must follow pattern:

```
<JIRA_KEY>-<JIRA_ID>

Examples:
✅ TSK-123
✅ DAAENG-456
❌ feature/my-feature
❌ main
❌ TSK123 (no dash)
```

## Commit Tracking

After successful commit, capture metadata:

```bash
# Get commit SHA
SHA=$(git rev-parse HEAD | cut -c1-7)

# Get commit message
MESSAGE=$(git log -1 --pretty=%B)

# Add to state tracking
# (details in state management section)
```

## Pull Request Readiness

Before creating PR, verify:

```bash
# 1. No uncommitted changes
if ! git diff-index --quiet HEAD --; then
  echo "ERROR: Uncommitted changes detected"
  exit 1
fi

# 2. Commits are on task branch
COMMITS=$(git rev-list --count origin/release/main..HEAD)
if [ "$COMMITS" -eq 0 ]; then
  echo "ERROR: No commits on task branch"
  exit 1
fi

# 3. No merge conflicts from release branch
if ! git merge-base --is-ancestor HEAD origin/release/main; then
  echo "ERROR: Task branch has conflicts with release branch"
  exit 1
fi
```

## Error Messages (Clear & Actionable)

### Release Branch Out of Sync

```
❌ HARD STOP: Release branch is out of sync

Your local release/main is behind origin/release/main.
This prevents safe task branch creation.

Actions:
1. Abort the current operation: autopilot:pull --abort
2. Update your release branch: git pull origin release/main
3. Retry: autopilot:pull TSK-123

Learn more: docs/03_failures_git_state.md
```

### Task Branch Conflict

```
❌ HARD STOP: Task branch has uncommitted changes

Branch TSK-123 exists but has uncommitted changes.
Cannot proceed safely.

Actions:
1. Review uncommitted changes: git status
2. Stage and commit: git add <files> && git commit -m "..."
3. Retry: autopilot:launch TSK-123

Learn more: docs/03_failures_git_state.md
```

### Dangerous Operation Detected

```
❌ HARD STOP: Dangerous Git operation detected

The following forbidden operation was attempted: git add .

Autopilot enforces explicit staging only to prevent accidental changes.

Allowed patterns:
✅ git add models/silver/orders.sql
✅ git add models/silver/schema.yml

Forbidden patterns:
❌ git add .
❌ git add -A
❌ git add -u

Learn more: docs/03_failures_git_state.md
```
