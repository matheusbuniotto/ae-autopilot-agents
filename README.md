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

**Option 1: Clone Repository (Recommended)**

Clone this repository and copy the necessary folders into your dbt project root:

```bash
git clone https://github.com/matheusbuniotto/ae-autopilot-agents.git autopilot-source
cp -r autopilot-source/.cursor .
cp -r autopilot-source/.opencode .
cp -r autopilot-source/shared .
# Optional: Copy docs for reference
cp -r autopilot-source/docs .
rm -rf autopilot-source
```

**Option 2: AI-Assisted Install**

If you are starting from scratch or want an agent to set it up:
1. Open [AI_INSTALL_GUIDE.md](AI_INSTALL_GUIDE.md).
2. Copy the content.
3. Paste it into Cursor Agent or Gemini.
4. Follow the prompt to install.

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
autopilot plan
```

This will:
- Analyze task complexity (L0-L3)
- Generate a plan if needed
- Report risk assessment

4. **Execute the work:**

```bash
autopilot execute-plan
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

Autopilot maintains `.autopilot/state.json` for resumability. Stop at any point and resume later:

```bash
autopilot launch TSK-123  # Resumes from last stage
```

## Documentation

- **[00_project_overview.md](docs/00_project_overview.md)** - High-level system design and mental model
- **[01_task_classification.md](docs/01_task_classification.md)** - L0-L3 classification heuristics and signals
- **[02_autopilot_commands.md](docs/02_autopilot_commands.md)** - Command reference and execution modes
- **[03_failures_git_state.md](docs/03_failures_git_state.md)** - Failure modes, Git safety rules, state management

## Project Structure

```
.cursor/
├── agents/              # Cursor skill definitions
└── rules/               # Persistent behavior rules (Git safety, Core behavior)
.opencode/
└── command/             # OpenCode command definitions
shared/                  # Platform-agnostic logic
├── prompts/             # Heuristics and templates
└── schemas/             # JSON validation schemas
docs/                    # Reference documentation
```

## Configuration

### Release Branch
Default: `release/main`. Override when pulling:
```bash
autopilot pull TSK-123 release/analytics
```

### JIRA Integration
Autopilot uses JIRA MCP. Ensure you are authenticated with your JIRA instance.

## Contributing

Autopilot is designed for safe, composable execution. Contributions welcome!

1. Review design in `docs/00_project_overview.md`
2. Follow safety rules in `.cursor/rules/git-safety.mdc`
3. Test with manual verification
4. Submit PR for review

---

**Version:** 1.0.0
**Maintainers:** Analytics Engineering Team