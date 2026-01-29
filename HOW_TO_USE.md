# How to Use Autopilot Commands (Like `/gsd:`)

## Command Syntax

Autopilot commands work just like GSD commands with `/autopilot:` prefix in Cursor and Claude Code.

### Cursor / Claude Code

Use the `/` prefix syntax:

```bash
/autopilot:pull TSK-123
/autopilot:plan
/autopilot:execute-plan --phase=1
/autopilot:review
/autopilot:pr
/autopilot:launch TSK-123
```

### OpenCode

Use the command syntax:

```bash
autopilot pull TSK-123
autopilot plan
autopilot execute-plan --phase=1
autopilot review
autopilot pr
autopilot launch TSK-123
```

## Command Discovery

When you type `/autopilot:` in Cursor, the IDE automatically discovers and lists available commands:

1. Cursor scans `.cursor/agents/` directory
2. Finds all `*.md` files with YAML frontmatter
3. Extracts `description` from frontmatter
4. Shows available commands in autocomplete

Example:
```
/autopilot:
  ├─ /autopilot:pull     Pull JIRA task and prepare Git branch
  ├─ /autopilot:plan     Classify task and generate plan if needed
  ├─ /autopilot:execute-plan  Execute work plan with phase support
  ├─ /autopilot:review   Validate changes before PR creation
  ├─ /autopilot:pr       Create Pull Request and request human review
  └─ /autopilot:launch   Orchestrator - run full workflow or resume
```

## 6 Core Commands

### 1. `/autopilot:pull TSK-123`

**Purpose:** Load JIRA task and create task branch

**What it does:**
- Fetches JIRA task metadata
- Validates task ID format (TSK-123, DAAENG-456, etc.)
- Syncs and validates release branch is current
- Creates task branch: `git switch -c TSK-123 origin/release/main`
- Initializes `.autopilot/state.json` and `.autopilot/task.json`
- Enforces hard stops: release sync, conflicts, format validation

**Example:**
```bash
/autopilot:pull TSK-123
# or with custom release branch:
/autopilot:pull TSK-123 release/analytics
```

**Output:**
```
✅ Pull complete
   Task: TSK-123
   Summary: Add validation tests to silver.orders
   Branch: TSK-123 (created from origin/release/main)
   State: .autopilot/state.json

Next step: /autopilot:plan
```

### 2. `/autopilot:plan`

**Purpose:** Classify task complexity (L0-L3) and generate plan

**What it does:**
- Analyzes JIRA task description
- Detects affected dbt models
- Classifies complexity: L0 (docs), L1 (single), L2 (multi), L3 (high-risk)
- Escalates if Silver layer involved
- Generates structured plan for L2+ tasks
- Emits soft stop triggers if ambiguous

**Requirements (from prior stages):**
- `.autopilot/state.json` must exist (from pull)
- State must show stage=pull completed

**Output:**
```
✅ Plan complete
   Classification: L2 (Multi-model, Silver involved)
   Affected models: silver.orders, gold.revenue
   Risk score: 65/100
   Requires plan: yes

   Plan phases:
   1. schema_changes - Add columns, update types
   2. refactor_logic - Update JOIN logic
   3. validation - Run tests, check row counts

Next: /autopilot:execute-plan
```

### 3. `/autopilot:execute-plan [--phase=N]`

**Purpose:** Execute the work plan with phase support

**What it does:**
- Loads plan from state
- Executes each phase in order
- Creates/modifies dbt models and tests
- Commits changes atomically (explicit staging, no `git add .`)
- Runs `dbt build` validation after each phase
- Soft stops at checkpoints for confirmation on L2+ tasks

**Optional arguments:**
```bash
/autopilot:execute-plan         # Execute all phases
/autopilot:execute-plan --phase=1  # Execute phase 1 only
/autopilot:execute-plan --resume   # Resume from stopped phase
```

**Output:**
```
✅ Phase 1 complete: schema_changes
   Commits:
   - a1b2c3d: Add created_at column to silver.orders
   - b2c3d4e: Update column documentation

   dbt validation: ✅ passed (2 models, 8 tests)

   Next: /autopilot:execute-plan --phase=2
```

### 4. `/autopilot:review`

**Purpose:** Validate all changes before PR creation

**What it does:**
- Runs `dbt build` on all affected models
- Checks SQL formatting/linting
- Verifies test coverage (new and existing)
- Validates documentation completeness
- Confirms commits are atomic and clear
- Detects scope creep

**Output:**
```
✅ Review complete
   dbt build: ✅ (3 models, 15 tests)
   SQL linting: ✅ (0 issues)
   Tests: ✅ (5 new, 12 existing)
   Commits: ✅ (4 atomic commits)

Ready for: /autopilot:pr
```

### 5. `/autopilot:pr`

**Purpose:** Create Pull Request

**What it does:**
- Pushes branch to origin
- Creates PR via GitHub CLI/MCP
- Sets title: `[TSK-123] Task summary`
- Includes in PR body:
  - JIRA task link
  - Classification (L0-L3)
  - Risk score
  - Affected models
  - dbt validation results
  - Commit summary
  - Rollback plan

**Output:**
```
✅ PR created: #456
   Title: [TSK-123] Add validation tests to silver.orders
   URL: https://github.com/org/repo/pull/456

   Status: awaiting human review

Next: Submit for review and wait for approval
```

**Important:** Autopilot never merges. Human approval required.

### 6. `/autopilot:launch TSK-123`

**Purpose:** Run complete workflow in sequence (or resume)

**What it does:**
- Runs: pull → plan → execute-plan → review → pr
- Auto-detects from state if resuming
- Skips completed stages
- Handles multi-phase checkpoints with user confirmation
- Saves state after each stage
- Supports resumability

**Examples:**
```bash
/autopilot:launch TSK-123          # Full workflow (new task)
/autopilot:launch TSK-123          # Resume (auto-detects state)
/autopilot:launch TSK-123 --dry-run    # Validate without executing
/autopilot:launch TSK-123 --until review  # Stop after review
```

**Output:**
```
Step 1/5: Pull
  ✅ Complete

Step 2/5: Plan
  Classification: L2
  ✅ Complete

Step 3/5: Execute-Plan
  Phase 1: schema_changes
    ✅ Complete
  Phase 2: refactor_logic
    ⏸️ Checkpoint - Continue? [y/n] y
    ✅ Complete

Step 4/5: Review
  ✅ Complete

Step 5/5: PR
  ✅ Complete

Status: Ready for human review
PR: https://github.com/org/repo/pull/456
```

## State Management (Behind the Scenes)

Autopilot maintains `.autopilot/state.json` to enable resumability:

```json
{
  "task_id": "TSK-123",
  "branch": "TSK-123",
  "stage": "execute-plan",
  "classification": "L2",
  "plan": {
    "completed_phases": ["phase_1"]
  },
  "commits": [
    {
      "sha": "a1b2c3d",
      "message": "Add created_at column to silver.orders",
      "timestamp": "2026-01-29T10:45:00Z"
    }
  ]
}
```

**Why state matters:**
- On next `/autopilot:launch TSK-123`, it skips pull, plan, and phase 1
- Resumes from phase 2
- Never duplicates work
- Enables safe recovery from errors

## Error Handling

All errors follow a clear pattern:

```
❌ ERROR_TYPE: Short description

Details:
Longer explanation of what went wrong

Actions:
1. Fix the issue
2. Stage/commit if needed
3. Retry: /autopilot:launch TSK-123

State saved: .autopilot/state.json (for resumability)
```

**Examples of hard stops:**
- ❌ Release branch is out of sync → Cannot create safe task branch
- ❌ Git conflicts detected → Manual resolution required
- ❌ dbt build failed → Logic error needs fixing

**Examples of soft stops:**
- ⏸️ Task escalates L1 → L2 → Await human confirmation
- ⏸️ Multi-phase checkpoint → Await user to proceed

## Typical Workflow

### Scenario: Add tests to silver.orders

```bash
# Step 1: Pull task
/autopilot:pull TSK-123

# Step 2: See what we're classifying as
/autopilot:plan
# Output: L1 (single model, low risk)

# Step 3: Do the work
/autopilot:execute-plan
# Creates tests, commits

# Step 4: Validate
/autopilot:review
# All checks pass

# Step 5: Create PR
/autopilot:pr
# PR #456 created

# Step 6: Human approves and merges on GitHub
# (Autopilot never merges)
```

Or as a single command:
```bash
/autopilot:launch TSK-123
# Runs all 5 stages automatically
```

### Scenario: Resume multi-phase work

```bash
# Day 1: Start work
/autopilot:launch TSK-123
# Executes pull, plan, phase 1
# Soft stop at phase 2 checkpoint

# Day 2: Continue where you left off
/autopilot:launch TSK-123
# Detects state, skips pull/plan/phase 1
# Asks about phase 2
# Continues to completion
```

## Safety Rules (Built In)

✅ **Hard stops prevent:**
- Outdated release branch
- Task branch conflicts
- Dangerous Git operations (`git add .`, `git push --force`)
- Invalid task IDs
- Missing JIRA metadata

✅ **Soft stops require confirmation for:**
- Task complexity escalation
- Multi-phase checkpoints
- Ambiguous business logic

✅ **Atomic operations:**
- All commits are reviewable and reversible
- State saved before every exit
- No squashing, no history rewriting
- Clear commit messages

## Troubleshooting

### "Command not recognized"
**Issue:** `/autopilot:pull` not appearing in autocomplete

**Fix:**
1. Verify files exist: `ls -la .cursor/agents/`
2. Check YAML frontmatter is valid (use `---`)
3. Restart Cursor/Claude Code
4. Check syntax: `---` on separate lines

### "Release branch out of sync"
**Fix:**
```bash
git pull origin release/main
/autopilot:pull TSK-123
```

### "State file corrupted"
**Fix:**
```bash
rm .autopilot/state.json
/autopilot:pull TSK-123  # Reinitialize
```

### "Want to abandon current task"
**Fix:**
```bash
# Delete state and branch (if not pushed)
rm -rf .autopilot/
git switch release/main
git branch -D TSK-123
```

## Reference

- **Main guide:** README.md
- **Technical details:** IMPLEMENTATION_SUMMARY.md
- **Git safety rules:** `.cursor/rules/git-safety.mdc`
- **Core behavior:** `.cursor/rules/autopilot-core.mdc`
- **Classification heuristics:** `shared/prompts/classification.md`

## Next Steps

1. Try it: `/autopilot:pull TSK-123`
2. Check state: `cat .autopilot/state.json`
3. See classification: `/autopilot:plan`
4. Run full workflow: `/autopilot:launch TSK-123`

---

**Version:** Phase 1 (Foundation & Safety)
**Status:** Ready to use
**All 6 commands available for Cursor and OpenCode**
