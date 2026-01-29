---
description: "Execute work plan with phase support"
model: claude-opus-4-5
tools: ["Read", "Write", "Bash"]
---

# Autopilot Execute Plan - Work Execution

## Purpose

Execute the work plan, supporting single-phase (L0-L1) and multi-phase (L2+) execution with checkpoints.

**Stage:** execute-plan
**Input:** Existing state from plan stage, classification, and plan details
**Output:** Commits created, tests added, state updated with completion

## Status

**Phase 3 - Execution & Validation (Planned)**

This skill will be implemented in Phase 3 to handle:
- dbt model changes (creation, modification, SQL refactors)
- Test creation (schema, data, freshness)
- Documentation updates
- dbt build validation
- Atomic commits with explicit staging
- Multi-phase execution with checkpoints
- Safe error handling and recovery

## Core Responsibilities

### Phase Execution

- Load plan from state
- Execute each phase in order
- After each phase: commit changes, run validation
- Request confirmation at checkpoints (soft stops)
- Skip already-completed phases on resume

### Work Execution

- Implement JIRA task requirements
- Follow team SQL style guide
- Create comprehensive tests
- Update dbt documentation
- Validate with `dbt build`

### Commit Management

- Stage files explicitly (no `git add .`)
- Create atomic commits with clear messages
- Track commits in state for resumability
- Never squash or rewrite history

### Validation

- Run `dbt build` after each phase
- Check SQL formatting/linting
- Verify tests pass
- Detect downstream impacts

## Planned Implementation Order

### Single Phase Execution (L0/L1)

1. Load state and classification
2. Verify prerequisites met
3. Execute inline plan
4. Create files/changes
5. Commit changes
6. Run `dbt build`
7. Update state with completion

### Multi-Phase Execution (L2/L3)

1. Load state and structured plan
2. For each phase:
   a. Execute phase tasks
   b. Commit changes
   c. Run `dbt build` for affected models
   d. Update state with phase completion
   e. Soft stop for confirmation if not final phase
3. After final phase: continue to review

## Key Patterns

### dbt SQL Changes

```bash
# Modify model SQL
# Update schema.yml with new columns/tests
# Commit changes atomically
git add models/silver/orders.sql models/silver/schema.yml
git commit -m "Add freshness test to silver.orders"
```

### Test Creation

```bash
# Add tests to schema.yml
# Common test patterns:
#  - not_null
#  - unique
#  - relationships
#  - freshness
#  - custom tests
```

### Validation

```bash
# After changes
dbt build --select affected_model+
dbt test --select affected_model+
dbt docs generate
```

## Error Handling

### Hard Stops

- dbt build failure (outside expected scope)
- SQL linting failure
- Test failure (logic error)
- Rollback needed

### Soft Stops

- Multi-phase checkpoint
- Ambiguous business logic
- Manual intervention required
- Confirmation needed

## Output Format

After execution, state includes:

```json
{
  "stage": "execute-plan",
  "plan": {
    "completed_phases": ["phase_1", "phase_2"],
    "current_phase": "phase_3"
  },
  "commits": [
    {
      "sha": "a1b2c3d",
      "message": "Add freshness test to silver.orders",
      "stage": "execute-plan",
      "timestamp": "2026-01-29T10:45:00Z"
    }
  ]
}
```

## Next Steps After Execution

After execute-plan completes:

```bash
autopilot review        # Validate before PR
autopilot pr            # Create pull request
```

## References

- Core behavior: `.cursor/rules/autopilot-core.mdc`
- Git operations: `shared/prompts/git-operations.md`
- dbt patterns: `docs/02_autopilot_commands.md`

## See Also

- [Cursor skill](./autopilot-execute-plan.md) (this file)
- [OpenCode command](../../.opencode/command/autopilot-execute-plan.md)
- `.cursor/rules/git-safety.mdc` - Git safety enforcement
- `docs/03_failures_git_state.md` - Error handling and recovery
