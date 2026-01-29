---
description: "Validate changes before PR creation"
model: claude-opus-4-5
tools: ["Read", "Write", "Bash"]
---

# Autopilot Review - Validation & Quality Checks

## Purpose

Run comprehensive validation and quality checks before PR creation.

**Stage:** review
**Input:** Existing state from execute-plan stage
**Output:** Validation results, state updated, ready for PR stage

## Status

**Phase 3 - Execution & Validation (Planned)**

This skill will be implemented in Phase 3 to validate all work before PR creation:
- `dbt build` validation (models and tests)
- SQL formatting/linting checks
- Test coverage verification
- Documentation completeness
- Commit quality review
- Scope verification

## Core Responsibilities

### dbt Validation

1. Run `dbt build` on all affected models
   - Compile all models
   - Run all tests
   - Check for errors

2. Verify tests pass
   - All new tests green
   - All existing tests still passing
   - No broken dependencies

3. Check documentation
   - All models have descriptions
   - Columns are documented
   - Tests are documented

### SQL Quality

1. Run SQL linter (sqlfluff, sqlfmt, etc.)
   - Check formatting
   - Verify style guide compliance
   - No syntax errors

2. Manual inspection
   - Review SQL logic
   - Check for common issues
   - Verify performance

### Commit Review

1. Verify all commits
   - Clear, atomic commits
   - Good commit messages
   - No empty commits

2. Check for accidental changes
   - No unrelated files staged
   - No .gitignore files committed
   - No environment files leaking

### Scope Verification

1. Verify scope matches task
   - Only planned changes made
   - No speculative refactors
   - No scope creep

2. Check downstream impact
   - Expected number of models affected
   - No unexpected dependencies broken

## Validation Checklist

```
✅ dbt build passes (all models and tests)
✅ No broken tests (new or existing)
✅ SQL formatting valid (no linting errors)
✅ Documentation complete (all models/columns)
✅ Commits are atomic and clear
✅ No accidental files staged
✅ Scope matches task description
✅ No uncommitted changes remaining
```

## Output Format

After review completes:

```json
{
  "stage": "review",
  "validation": {
    "dbt_build": {
      "status": "passed",
      "models_checked": 3,
      "tests_passed": 15,
      "tests_failed": 0
    },
    "sql_linting": {
      "status": "passed",
      "issues": 0
    },
    "documentation": {
      "status": "passed",
      "models_documented": 3,
      "columns_documented": 12
    },
    "commits": {
      "status": "passed",
      "commit_count": 4,
      "all_atomic": true
    }
  }
}
```

## Validation Scripts

### dbt Build Validation

```bash
# Run full build on affected models
dbt build --select +affected_model+

# Run tests only
dbt test --select affected_model+

# Check for schema changes
dbt parse
# Compare manifest.json for breaking changes
```

### SQL Linting

```bash
# Example with sqlfluff
sqlfluff lint models/ --dialect dbt-postgres

# Example with sqlfmt (formatting)
sqlfmt models/*.sql --check
```

### Commit Inspection

```bash
# Show commits on branch
git log origin/release/main..HEAD --oneline

# Check for atomic commits (no large files)
git log origin/release/main..HEAD --numstat
```

## Hard Stops During Review

- dbt build fails unexpectedly
- Critical tests fail (logic error)
- SQL formatting fails
- Scope exceeds task description
- Uncommitted changes detected

## Soft Stops During Review

- Warning: Many models affected (verify intentional)
- Warning: Complex logic (recommend manual check)
- Warning: Breaking schema changes (verify intent)

## Next Steps

If review passes:

```bash
autopilot pr          # Create pull request
```

If review fails:

```bash
# Fix issues and retry
autopilot review
```

## References

- Execution details: `.cursor/agents/autopilot-execute-plan.md`
- Git operations: `shared/prompts/git-operations.md`
- Core behavior: `.cursor/rules/autopilot-core.mdc`

## See Also

- [Cursor skill](./autopilot-review.md) (this file)
- [OpenCode command](../../.opencode/command/autopilot-review.md)
- `docs/03_failures_git_state.md` - Error handling
- SAFETY-05 requirement: `docs/README.md`
