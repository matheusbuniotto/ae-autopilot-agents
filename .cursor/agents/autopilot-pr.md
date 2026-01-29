---
description: "Create Pull Request and request human review"
model: claude-opus-4-5
tools: ["Read", "Write", "Bash"]
---

# Autopilot PR - Pull Request Creation

## Purpose

Create Pull Request with comprehensive context for human review.

**Stage:** pr
**Input:** Existing state from review stage, classification, plan, commits
**Output:** PR created on GitHub/GitLab, state updated

## Status

**Phase 4 - PR Creation & Agent Interface (Planned)**

This skill will be implemented in Phase 4 to handle:
- PR creation via GitHub CLI or MCP
- PR title generation from task ID and summary
- PR body composition with classification, models, dbt results
- PR linking to JIRA task
- Requesting reviewers if configured
- Tracking PR number in state

## Core Responsibilities

### PR Title & Body

1. Generate title format: `[TASK-ID] Task Summary`
2. Compose body with:
   - JIRA task link
   - Task classification (L0-L3)
   - Risk assessment
   - Affected models
   - dbt build results
   - Commit summary
   - "What was done" summary

### PR Creation

1. Push branch to origin
2. Create PR via gh CLI or GitHub MCP
3. Set title and description
4. Request reviewers (if configured)
5. Save PR number and URL to state

### Safeguards

1. Verify branch is ready (no stale state)
2. Verify review passed
3. Verify all commits are present
4. Block if scope exceeded
5. Verify release branch not behind

## PR Template

```markdown
## What's this PR about?

[JIRA Task Link](https://jira.company.com/browse/TSK-123): Task summary here

## Classification

**Level:** L2 (Multi-model, Silver involved)
**Risk Score:** 65/100
**Requires Review:** Yes

## What was done

- Added freshness test to silver.orders (detects missing data)
- Updated documentation for silver.orders

## Affected Models

- `silver.orders` (MODIFIED - SQL + tests)
- `gold.revenue` (DOWNSTREAM - will auto-refresh)
- `reporting.dashboard` (DOWNSTREAM - will auto-refresh)

## Validation Results

✅ **dbt build:** Passed (3 models, 15 tests)
✅ **SQL linting:** Passed (0 issues)
✅ **Tests:** 5 new tests + 12 existing = all passing
✅ **Commits:** 4 atomic, reviewable commits

## Commits in this PR

- a1b2c3d: Add freshness test to silver.orders
- b2c3d4e: Update column documentation
- c3d4e5f: Add not_null test
- d4e5f6g: Update dbt docs

## Downstream Impact

These models will auto-refresh after merge:
- gold.revenue (5 min refresh)
- reporting.dashboard (15 min refresh)

## Rollback Plan

If issues arise:
1. Revert PR merge
2. Restore from prior dbt build
3. Rebuild gold and reporting layers (20 min total)

## Notes

No backfill required. Changes are additive (tests only).

---

*Created by Autopilot on 2026-01-29*
```

## Implementation Details

### PR Body Sections

1. **Header** - Task link and summary
2. **Classification** - L0-L3 level and risk
3. **What was done** - Bullet list of changes
4. **Affected models** - Table of modified/downstream models
5. **Validation** - Test results, linting results
6. **Commits** - List of commit SHAs and messages
7. **Downstream impact** - Models that will refresh
8. **Rollback plan** - If things go wrong
9. **Notes** - Any special considerations

### GitHub CLI Usage

```bash
# Create PR
gh pr create \
  --title "[TSK-123] Add validation tests to silver.orders" \
  --body "$(cat pr_body.md)" \
  --base release/main \
  --head TSK-123

# Get PR number
PR_NUMBER=$(gh pr list --head TSK-123 --json number -q '.[0].number')

# Save to state
jq --arg num "$PR_NUMBER" '.pr_number = $num' .autopilot/state.json
```

### Output Example

```
✅ PR created: #456
   Title: [TSK-123] Add validation tests to silver.orders
   URL: https://github.com/org/repo/pull/456
   Branch: TSK-123 → release/main

   Classification: L2
   Affected models: 1 (silver.orders)
   Tests: 5 new + 12 existing

   Status: awaiting human review

   Next: Submit PR for review and wait for approval
```

## Safeguards

### Pre-PR Checks

- [ ] Review passed (validation complete)
- [ ] All commits present in branch
- [ ] Branch is ahead of release/main
- [ ] Release branch is current (no stale base)
- [ ] No uncommitted changes
- [ ] PR scope matches task description

### Block If

- dbt build failed
- SQL linting failed
- Scope creep detected
- Classification missing
- Commits not tracked

## Hard Stops

- Cannot push branch to origin
- Cannot create PR (GitHub API error)
- Branch protection rules prevent PR
- Merge conflicts with release branch

## Soft Stops

- Large number of files changed (warn, allow)
- Complex changes (recommend manual review)
- Breaking schema changes (request confirmation)

## After PR Creation

1. State updated with PR number and URL
2. Branch is pushed to origin
3. PR is created and open for review
4. Awaiting human approval
5. No auto-merge (human decision only)

## Next Steps

User manually:
1. Review PR on GitHub
2. Approve PR if changes look good
3. Merge PR (GitHub UI)
4. Delete task branch (optional)
5. Cleanup state (optional after merge)

## References

- State format: `shared/schemas/state-schema.json`
- Core behavior: `.cursor/rules/autopilot-core.mdc`
- PR best practices: `docs/03_failures_git_state.md`

## See Also

- [Cursor skill](./autopilot-pr.md) (this file)
- [OpenCode command](../../.opencode/command/autopilot-pr.md)
- GIT-03 requirement: `docs/README.md`
- GIT-04 requirement: `docs/README.md` (no auto-merge)
