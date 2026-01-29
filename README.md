# Autopilot - Analytics Engineering Task Automation

Autopilot is a multi-platform agent/skill system for [Cursor](https://cursor.com) and [OpenCode](https://www.opencode.dev) that automates Analytics Engineering tasks end-to-end: from JIRA task intake through pull request creation.

**Goal:** Reliably automate Analytics Engineering work while maintaining safety guarantees that never break production or lose visibility into what happened.

## Quick Start

### Prerequisites

- Cursor or OpenCode IDE
- Git with GitHub/GitLab configured
- dbt CLI installed and configured
- JIRA CLI/MCP available (pre-configured by your team)

### Installation

Clone this repository:

```bash
git clone https://github.com/your-org/ae-autopilot.git
cd ae-autopilot
```

Verify your setup:

```bash
# Check dbt
dbt --version

# Check git
git config --list | grep user

# Check JIRA access (if using MCP)
# This varies by configuration
```

### Your First Task

1. **Open a task in JIRA** - Find a task ID (e.g., `TSK-123`)

2. **In Cursor/OpenCode, run:**

```bash
autopilot pull TSK-123
```

This will:
- Fetch task metadata from JIRA
- Verify your release branch is current
- Create a task branch named `TSK-123`
- Initialize state for resumability

3. **Continue with classification:**

```bash
autopilot plan TSK-123
```

This will:
- Analyze task complexity (L0-L3)
- Generate a plan if needed
- Report risk assessment

4. **Execute the work:**

```bash
autopilot execute-plan TSK-123
```

Or run everything in sequence:

```bash
autopilot launch TSK-123
```

## Features

### 6 Composable Commands

- **`autopilot pull`** - Load JIRA task and create branch
- **`autopilot plan`** - Classify task and generate plan
- **`autopilot execute-plan`** - Perform the work (supports phases for L3 tasks)
- **`autopilot review`** - Validate changes before PR
- **`autopilot pr`** - Create Pull Request
- **`autopilot launch`** - Run full workflow in sequence

### Safety Guarantees

**Hard Stops (Immediate Exit):**
- ✅ Release branch out of sync → Cannot create task branch
- ✅ JIRA task not found → Cannot proceed
- ✅ Git conflicts detected → Requires manual resolution
- ✅ Task classification fails → Cannot plan work
- ✅ `git add .` attempted → Prevents accidental changes

**Soft Stops (Require Confirmation):**
- ⏸️ Task escalates (L1 → L2) → Await human confirmation
- ⏸️ Multi-phase checkpoint → Request phase confirmation
- ⏸️ Ambiguous business logic → Request clarification

### State Persistence

Autopilot maintains `.autopilot/state.json` for resumability:

```json
{
  "task_id": "TSK-123",
  "branch": "TSK-123",
  "stage": "execute-plan",
  "classification": "L2",
  "commits": [
    {
      "sha": "a1b2c3d",
      "message": "Add freshness test to silver.orders",
      "timestamp": "2026-01-29T10:45:00Z"
    }
  ]
}
```

Stop at any point and resume later:

```bash
autopilot launch TSK-123  # Resumes from last stage
```

### Task Classification (L0-L3)

Autopilot intelligently classifies work:

- **L0** - Documentation only, no code changes
- **L1** - Single model, low risk, inline plan
- **L2** - Multi-model or Silver-specific, structured plan
- **L3** - High risk, complex, phased execution

Silver layer tables trigger risk escalation based on:
- Table size (row count)
- Downstream dependencies
- Join complexity
- Backfill requirements

## Workflow Example

### Scenario: Fix Orders Table

1. **JIRA task:** TSK-123 - "Add validation tests to silver.orders"

2. **Pull task:**

```bash
$ autopilot pull TSK-123

✅ Pull complete
   Task: TSK-123
   Summary: Add validation tests to silver.orders
   Branch: TSK-123 (created from origin/release/main)

   Next step: autopilot plan TSK-123
```

3. **Plan work:**

```bash
$ autopilot plan TSK-123

✅ Plan complete
   Classification: L1 (Single model, low risk)
   Affected models: silver.orders
   Risk score: 25/100

   Inline plan:
   - Add not_null test on order_id
   - Add unique test on order_id
   - Run dbt build to validate

   Next: autopilot execute-plan
```

4. **Execute:**

```bash
$ autopilot execute-plan TSK-123

✅ Phase 1 complete
   - Added not_null test to silver.orders schema.yml
   - Added unique test to silver.orders schema.yml
   - Ran: dbt build --select silver.orders+

   Commits:
   - a1b2c3d: Add validation tests to silver.orders

   Next: autopilot review
```

5. **Review & validate:**

```bash
$ autopilot review TSK-123

✅ Review complete
   dbt build: ✅ (2 new tests, all pass)
   SQL linting: ✅ (no issues)
   Changes: ✅ (atomic, reviewable)

   Next: autopilot pr
```

6. **Create PR:**

```bash
$ autopilot pr TSK-123

✅ PR created: #456
   Title: [TSK-123] Add validation tests to silver.orders
   URL: https://github.com/org/repo/pull/456

   → Submit for review
   → Merge manually once approved
```

## Project Structure

```
ae-autopilot/
├── .cursor/
│   ├── agents/              # Cursor skill definitions
│   │   ├── autopilot-pull.md
│   │   ├── autopilot-plan.md
│   │   ├── autopilot-execute-plan.md
│   │   ├── autopilot-review.md
│   │   ├── autopilot-pr.md
│   │   └── autopilot-launch.md
│   └── rules/               # Persistent behavior rules
│       ├── git-safety.mdc
│       └── autopilot-core.mdc
├── .opencode/
│   └── command/             # OpenCode command definitions
│       ├── autopilot-pull.md
│       ├── autopilot-plan.md
│       ├── autopilot-execute-plan.md
│       ├── autopilot-review.md
│       ├── autopilot-pr.md
│       └── autopilot-launch.md
├── .autopilot/              # Runtime state (Git-ignored)
│   ├── state.json           # Execution state
│   ├── task.json            # JIRA metadata
│   └── classification.json  # Classification results
├── shared/                  # Platform-agnostic logic
│   ├── prompts/
│   │   ├── classification.md
│   │   └── git-operations.md
│   └── schemas/
│       ├── state-schema.json
│       ├── task-schema.json
│       └── classification-schema.json
├── docs/
│   ├── 00_project_overview.md
│   ├── 01_task_classification.md
│   ├── 02_autopilot_commands.md
│   ├── 03_failures_git_state.md
│   └── references_repos.md
├── .gitignore
├── README.md
└── ROADMAP.md
```

## Documentation

### Core Documentation

- **[00_project_overview.md](docs/00_project_overview.md)** - High-level system design and mental model
- **[01_task_classification.md](docs/01_task_classification.md)** - L0-L3 classification heuristics and signals
- **[02_autopilot_commands.md](docs/02_autopilot_commands.md)** - Command reference and execution modes
- **[03_failures_git_state.md](docs/03_failures_git_state.md)** - Failure modes, Git safety rules, state management

### Implementation

- **[.cursor/rules/git-safety.mdc](.cursor/rules/git-safety.mdc)** - Git safety enforcement rules
- **[.cursor/rules/autopilot-core.mdc](.cursor/rules/autopilot-core.mdc)** - Core execution engine behavior
- **[shared/prompts/classification.md](shared/prompts/classification.md)** - Classification decision tree and heuristics
- **[shared/prompts/git-operations.md](shared/prompts/git-operations.md)** - Safe Git command templates

### Schemas

- **[shared/schemas/state-schema.json](shared/schemas/state-schema.json)** - State file format and validation
- **[shared/schemas/task-schema.json](shared/schemas/task-schema.json)** - JIRA task metadata format
- **[shared/schemas/classification-schema.json](shared/schemas/classification-schema.json)** - Classification output format

## Safety Rules (Non-Negotiable)

### Git Operations

✅ **ALLOWED:**
```bash
git add models/silver/orders.sql      # Explicit staging
git commit -m "Add test to orders"    # Atomic commits
git push origin TSK-123               # Standard push
```

❌ **FORBIDDEN:**
```bash
git add .                             # Never! Accidental changes
git add -A                            # Never! Sneaky staging
git push --force                      # Never! History rewriting
git commit --amend                    # Never! Changes history
```

### Branch Naming

✅ **VALID:**
```
TSK-123           # JIRA format
DAAENG-456        # Multi-letter project
```

❌ **INVALID:**
```
feature/my-feature     # Too generic
TSK123                 # Missing dash
main                   # Reserved
```

### Decision Authority

- **Autopilot decides:** Task classification, plan generation, Git safety
- **Human decides:** PR merge, multi-phase checkpoints, business logic clarification
- **Never automatic:** PR merge, force-push, history rewriting

## Troubleshooting

### Release Branch Out of Sync

```
❌ HARD STOP: Release branch is out of sync
```

**Fix:**
```bash
git pull origin release/main
autopilot pull TSK-123
```

### Task Not Found in JIRA

```
❌ HARD STOP: Cannot fetch JIRA task
```

**Fix:**
1. Verify task exists: https://jira.company.com/browse/TSK-123
2. Check JIRA credentials
3. Retry: `autopilot pull TSK-123`

### Git Conflicts

```
❌ HARD STOP: Git conflicts detected
```

**Fix:**
```bash
git status
# Resolve conflicts manually in editor
git add <files>
git commit
autopilot launch TSK-123
```

### State File Corruption

```
❌ State file is invalid
```

**Fix:**
```bash
# Remove corrupted state and retry
rm .autopilot/state.json
autopilot pull TSK-123
```

## Configuration

### Release Branch

Default: `release/main`

Override when pulling:
```bash
autopilot pull TSK-123 release/analytics
```

### dbt Project Path

Autopilot expects dbt to be pre-configured in your environment.

Verify:
```bash
dbt debug
```

### JIRA Integration

Autopilot uses JIRA MCP (pre-configured by your team).

Verify:
```bash
# Varies by configuration
```

## Roadmap

### Phase 1 ✅ (Current)
- Foundation & Safety Infrastructure
- State persistence
- Task intake (autopilot:pull)
- Git safety enforcement

### Phase 2 (Next)
- Task Intake & Classification
- Full L0-L3 classification engine
- Downstream impact detection
- Plan generation

### Phase 3
- Execution & Validation
- dbt model changes and tests
- Atomic commits
- Review & validation

### Phase 4
- PR Creation & Agent Interface
- PR template with JIRA link
- Orchestrator command (autopilot:launch)
- Phase-by-phase execution

## Support

### Getting Help

- Check documentation in `docs/`
- Review error messages (they're detailed)
- See `docs/03_failures_git_state.md` for failure modes

### Reporting Issues

- Report bugs: https://github.com/your-org/ae-autopilot/issues
- Discuss features: GitHub discussions

### Contributing

Autopilot is designed for safe, composable execution. Contributions welcome!

1. Review design in `docs/00_project_overview.md`
2. Follow safety rules in `.cursor/rules/git-safety.mdc`
3. Test with manual verification
4. Submit PR for review

## License

[Add your license here]

---

**Version:** Phase 1 (Foundation & Safety Infrastructure)
**Last Updated:** 2026-01-29
**Maintainers:** Analytics Engineering Team
