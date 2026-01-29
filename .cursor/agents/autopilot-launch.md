---
description: "Orchestrator - run full workflow or resume from checkpoint"
model: claude-opus-4-5
tools: ["Read", "Write", "Bash"]
---

# Autopilot Launch - Orchestrator

## Purpose

Run the complete Autopilot workflow end-to-end (pull → plan → execute-plan → review → pr) or resume from a prior checkpoint.

**Stage:** orchestrator
**Input:** JIRA task ID, optional phase specification
**Output:** Full workflow completed or checkpoint reached with state saved

## Usage

```bash
# Run full workflow
autopilot launch TSK-123

# Resume from checkpoint (auto-detects from state)
autopilot launch TSK-123

# Dry-run mode (validate without executing)
autopilot launch TSK-123 --dry-run

# Execute only through specific stage
autopilot launch TSK-123 --until review

# Continue from current stage
autopilot launch TSK-123 --resume
```

## Workflow Flow

### First Time (New Task)

```
autopilot launch TSK-123

1. Pull (load task, create branch)
   ✅ Complete

2. Plan (classify, generate plan)
   ✅ Complete

3. Execute-Plan (do the work, create commits)
   ↯ Soft stop: Requires confirmation to proceed
   User confirms → Continue
   ✅ Complete

4. Review (validate before PR)
   ✅ Complete

5. PR (create pull request)
   ✅ Complete

Status: Ready for human review
```

### Resume (Existing Task)

```
autopilot launch TSK-123

State loaded: stage=execute-plan, phase=1 completed

1. Pull - SKIP (already done)
2. Plan - SKIP (already done)
3. Execute-Plan - RESUME at phase 2
   ✅ Complete

4. Review - RUN
   ✅ Complete

5. PR - RUN
   ✅ Complete

Status: Ready for human review
```

## Resumability Behavior

### Load State

```bash
# Check for existing state
if [ -f ".autopilot/state.json" ]; then
  TASK_ID=$(jq -r '.task_id' .autopilot/state.json)
  CURRENT_STAGE=$(jq -r '.stage' .autopilot/state.json)
  COMPLETED_PHASES=$(jq -r '.plan.completed_phases[]' .autopilot/state.json)
fi
```

### Stage Mapping

| Completed Stage | Resume Action |
|-----------------|---------------|
| (none) | Start at pull |
| pull | Jump to plan |
| plan | Jump to execute-plan |
| execute-plan | Resume at last phase |
| review | Jump to pr |
| pr | Offer cleanup or re-run |

### Multi-Phase Handling (L3 Tasks)

For L2+ tasks with multiple phases:

```
Soft stop at each phase boundary:
→ Phase 1 complete, phase 2 ready
  "Proceed to phase 2?" (yes/no/cancel)

If yes → Continue
If no → Stop and save state
If cancel → Abort all

On resume → Continue from stopped phase
```

## Core Orchestration Logic

```python
def launch_workflow(task_id, options={}):
    # 1. Load or initialize state
    state = load_state(task_id) or initialize_state(task_id)

    # 2. Determine entry point
    if state['stage'] == 'pull':
        start_stage = 'pull'
    elif state['stage'] == 'plan':
        start_stage = 'plan'
    elif state['stage'] == 'execute-plan':
        start_stage = 'execute-plan'
        start_phase = state['plan']['completed_phases'][-1] + 1
    elif state['stage'] == 'review':
        start_stage = 'review'
    elif state['stage'] == 'pr':
        start_stage = 'pr'

    # 3. Run stages in sequence
    for stage in ['pull', 'plan', 'execute-plan', 'review', 'pr']:
        if stage_number(stage) < stage_number(start_stage):
            continue  # Skip already completed

        result = run_stage(stage, state, options)

        if result['status'] == 'stop':
            save_state(state)  # Persist before exit
            print(result['message'])
            return 'stopped'

        if result['status'] == 'error':
            save_state(state)  # Persist before exit
            print(f"ERROR: {result['message']}")
            return 'failed'

        state = result['state']  # Update state

    # 4. Mark complete
    state['stage'] = 'pr'
    save_state(state)
    print("Workflow complete!")
    return 'success'
```

## Execution Options

### --dry-run
```bash
autopilot launch TSK-123 --dry-run

# Validate workflow without executing
# Shows what would happen
# No changes to Git or state
```

### --until <stage>
```bash
autopilot launch TSK-123 --until review

# Run through specified stage, then stop
# Useful for staged review before PR
```

### --resume
```bash
autopilot launch TSK-123 --resume

# Continue from last saved checkpoint
# Skips all completed stages
```

### --force-phase <n>
```bash
autopilot launch TSK-123 --force-phase 2

# Force resume from specific phase
# Use only if recovery needed
```

## Checkpoint System

### Automatic Checkpoints

State saved after each stage:
1. After pull: Branch created
2. After plan: Classification complete
3. After each phase: Commits created
4. After review: Validation complete
5. After PR: PR created

### Manual Checkpoints (Soft Stops)

Pause and request confirmation:
- Multi-phase at each boundary
- Classification escalation (L1 → L2)
- Ambiguous business logic
- High-risk changes

## Output During Execution

```
autopilot launch TSK-123

Step 1/5: Pull
  Loading JIRA task...
  Creating branch TSK-123...
  ✅ Complete

Step 2/5: Plan
  Analyzing task...
  Classification: L2
  Generating plan...
  ✅ Complete

Step 3/5: Execute-Plan
  Phase 1: schema_changes
    Creating files...
    Committing...
    ✅ Phase 1 complete

  Phase 2: refactor_logic
    ⏸️ Checkpoint - Continue to phase 2?

    [y/n/cancel] y

    Implementing changes...
    Running dbt build...
    Committing...
    ✅ Phase 2 complete

Step 4/5: Review
  Running dbt build...
  Checking SQL linting...
  Validating tests...
  ✅ Complete

Step 5/5: PR
  Pushing branch...
  Creating PR #456...
  ✅ Complete

Status: Ready for human review
PR: https://github.com/org/repo/pull/456

Next: Review and merge PR
```

## Error Recovery

If workflow stops or fails:

1. **State is saved** - Current progress preserved
2. **Precise error message** - Know exactly what failed
3. **Clear next steps** - How to fix and resume

Example error:

```
❌ ERROR: dbt build failed in phase 2

Models with errors:
  silver.orders - Column 'created_at' not found

Fix:
  1. Review error in VS Code
  2. Add missing column
  3. Stage and commit: git add ... && git commit -m "..."
  4. Retry: autopilot launch TSK-123

State saved: .autopilot/state.json
```

## Performance Optimization

### Skipped Stages

- Completed stages never re-execute
- Commits never re-created
- Plans never re-generated
- Classification cached in state

### Parallel Operations (Future)

Phase 1 uses sequential execution for safety.
Future phases may support parallel validation.

## Cleanup After Success

Optional (manual):

```bash
# After PR is merged:

# 1. Delete task branch (optional)
git branch -d TSK-123

# 2. Remove state file (optional)
rm .autopilot/state.json

# 3. Or keep for reference/debugging
```

## Mental Model

Think of `autopilot:launch` as a **smart resumable workflow engine**:

- **Deterministic** - Same input → same output
- **Safe** - Hard stops prevent issues
- **Transparent** - All context in state
- **Resumable** - Stop anywhere, continue later
- **Idempotent** - Never duplicate work

## References

- Core behavior: `.cursor/rules/autopilot-core.mdc`
- Stage definitions: `.cursor/agents/autopilot-*.md`
- State format: `shared/schemas/state-schema.json`

## See Also

- [Cursor skill](./autopilot-launch.md) (this file)
- [OpenCode command](../../.opencode/command/autopilot-launch.md)
- UI-02 requirement: `docs/README.md` (unified command)
- UI-03 requirement: `docs/README.md` (phase support)
- STATE-01 requirement: `docs/README.md` (state persistence)
