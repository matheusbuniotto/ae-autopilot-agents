---
description: "Interactive setup wizard for Autopilot (run once per repo)"
model: claude-haiku-4-5
tools: ["Read", "Write", "Bash"]
---

# Autopilot Setup - Interactive Onboarding

## Purpose

One-time setup wizard that configures Autopilot in your repository.

**When to use:** First time setting up Autopilot in a repository
**Input:** Interactive prompts for IDE choice, JIRA settings, Git config
**Output:** `.autopilot/config.json` with all settings, Autopilot files copied

## Interactive Setup Flow

### Step 1: Welcome & Prerequisites Check

```bash
echo "Checking prerequisites..."

# 1. Verify Git is configured
git config user.name > /dev/null || {
  echo "❌ Git user not configured"
  echo "Fix: git config user.name 'Your Name'"
  exit 1
}

# 2. Verify dbt CLI
dbt --version > /dev/null || {
  echo "❌ dbt CLI not installed"
  echo "Install from: https://docs.getdbt.com/docs/core/installation"
  exit 1
}

# 3. Verify repository structure
test -d .git || {
  echo "❌ Not a Git repository"
  echo "Fix: git init"
  exit 1
}

echo "✅ Prerequisites check passed"
```

### Step 2: IDE Selection

Interactive prompt (mimics `/gsd:new-project`):

```
Which IDE are you using?

  1) Cursor (Claude Code)
  2) OpenCode
  3) Both (install to both)

Enter choice (1-3): _
```

**Processing:**
- User selects IDE (cursor, opencode, or both)
- Selected IDEs will have agents/commands installed

### Step 3: Installation Scope

```
Where do you want to install Autopilot?

  1) Project-local  (in this repo at .cursor/, shared/)
  2) Global         (in ~/.cursor/, ~/.shared/)
  3) Let me choose  (select for each IDE)

Enter choice (1-3): _
```

**Options:**
- **Project-local:** Install in `.cursor/`, `.opencode/`, `shared/` directories (committed to repo)
- **Global:** Install in `~/.cursor/`, `~/.shared/` (shared across projects)
- **Custom:** Choose per IDE

### Step 4: JIRA Configuration

```
JIRA Configuration

These settings help Autopilot connect to your JIRA board.

JIRA Board Name (e.g., Analytics, AE): _
JIRA Board ID (e.g., DAAENG, TSK): _
```

**Validation:**
- Board ID must be uppercase alphanumeric (e.g., DAAENG, TSK, AE)
- Board name is free text
- Saved to `config.json` for later reference

### Step 5: Git Configuration

```
Git Configuration

Autopilot creates task branches from your release branch.

Main branch name (default: main): _
Release branch name (default: release/main): _
```

**Processing:**
- Main branch: where you develop (usually `main` or `master`)
- Release branch: where task branches are created from (usually `release/main`)
- Defaults work for most projects

### Step 6: Team Information

```
Team Information

Team name (e.g., Analytics Engineering, Data): _
Analytics lead email: _
```

**Purpose:**
- Team name: For context in communications
- Lead email: For notifications/escalations (future phases)

### Step 7: Summary & Confirmation

Shows all settings for review:

```
╔════════════════════════════════════════════════════════════╗
║                 Installation Summary                       ║
╚════════════════════════════════════════════════════════════╝

IDE:            cursor
Scope:          project
Target:         /Users/matheus/analytics-repo

JIRA Board:     Analytics Engineering (DAAENG)
Git Branches:   main → release/main
Team:           Analytics Engineering

Proceed with installation? (y/n): _
```

**User can:**
- Review all settings
- Cancel (n) and restart
- Proceed (y) with installation

## Installation Process

### What Gets Installed

If scope is **project-local**:

```
project-root/
├── .cursor/
│   ├── agents/          (6 skill files)
│   └── rules/           (2 rule files)
├── .opencode/
│   └── command/         (6 command files)
├── shared/
│   ├── schemas/         (3 JSON schemas)
│   └── prompts/         (2 prompt files)
├── .autopilot/
│   ├── config.json      (YOUR SETTINGS)
│   └── .gitkeep
└── .gitignore           (updated with .autopilot/)
```

If scope is **global**:

```
$HOME/
├── .cursor/
│   ├── agents/
│   └── rules/
├── .opencode/
│   └── command/
└── shared/
    ├── schemas/
    └── prompts/

project-root/
├── .autopilot/
│   ├── config.json      (YOUR SETTINGS)
│   └── .gitkeep
└── .gitignore           (updated with .autopilot/)
```

### Configuration File (.autopilot/config.json)

Created with all your settings:

```json
{
  "version": "1.0.0-phase1",
  "installed_at": "2026-01-29T20:00:00Z",
  "installed_by": "matheus",

  "ide": {
    "name": "cursor",
    "install_scope": "project"
  },

  "jira": {
    "board_name": "Analytics Engineering",
    "board_id": "DAAENG",
    "mcp_configured": false,
    "mcp_docs": "https://github.com/your-org/jira-mcp"
  },

  "git": {
    "main_branch": "main",
    "release_branch": "release/main"
  },

  "team": {
    "name": "Analytics Engineering",
    "analytics_lead": "you@company.com"
  },

  "features": {
    "state_persistence": true,
    "git_safety": true,
    "hard_stops": true,
    "resumability": true
  }
}
```

### Verification

After installation, verifies:

```bash
# Check IDE files installed
test -d .cursor/agents && echo "✅ Cursor agents"
test -d .opencode/command && echo "✅ OpenCode commands"

# Check shared files
test -d shared/schemas && echo "✅ Shared schemas"
test -d shared/prompts && echo "✅ Shared prompts"

# Check configuration
test -f .autopilot/config.json && echo "✅ Configuration created"

# Check .gitignore
grep -q ".autopilot/" .gitignore && echo "✅ .gitignore updated"
```

**Success** if all checks pass ✅

## Usage (After Setup)

### For Daily Use

After setup, use Autopilot commands normally:

```bash
/autopilot:pull TSK-123
/autopilot:plan
/autopilot:launch TSK-123
```

Configuration is loaded automatically from `.autopilot/config.json`

### Update Configuration

Edit `.autopilot/config.json` directly:

```json
{
  "jira": {
    "board_id": "DAAENG"  // Change if needed
  }
}
```

Or re-run setup:

```bash
bash install.sh
```

(Will prompt to confirm before overwriting)

## Advanced Options

### Using install.sh from Bash

The setup can also be run via `bash install.sh`:

```bash
# Full interactive setup
bash install.sh

# Skip IDE setup (config only)
bash install.sh --project-only

# Use defaults (non-interactive)
bash install.sh --quiet

# Overwrite existing config
bash install.sh --force
```

### Custom Installation Paths

For multi-IDE setups:

```
# Install to Cursor (project) + OpenCode (global)
Installation 1: Cursor → project-local
Installation 2: OpenCode → global
```

Both will use the same `.autopilot/config.json`

## Troubleshooting During Setup

### "Git user not configured"

```bash
git config user.name "Your Name"
git config user.email "you@company.com"
bash install.sh  # Try again
```

### "dbt CLI not found"

```bash
# Install dbt
pip install dbt-postgres  # or dbt-snowflake, dbt-bigquery

dbt --version  # Verify
bash install.sh  # Try again
```

### "Not a Git repository"

```bash
cd your-repo-root
git init
bash install.sh
```

### Cursor commands not appearing after setup

```bash
# 1. Fully quit Cursor (not just close window)
# 2. Wait 5 seconds
# 3. Reopen Cursor
# 4. Type /autopilot: to see commands
```

## What Happens Next

After setup completes:

### Immediate (1 minute)

1. Restart IDE (Cursor/OpenCode)
2. Type `/autopilot:` or `autopilot` to see commands
3. Verify all 6 commands appear

### Quick Test (5 minutes)

```bash
/autopilot:pull TSK-TEST
cat .autopilot/state.json    # Verify created
git branch -v                 # Verify branch created
```

### Full Verification (30 minutes)

See `QUICK_TEST.md` for 5-minute validation
See `TESTING_GUIDE.md` for comprehensive testing

## Configuration Reference

### .autopilot/config.json Fields

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `version` | string | Version installed | "1.0.0-phase1" |
| `installed_at` | ISO8601 | Installation timestamp | "2026-01-29T..." |
| `installed_by` | string | Git user who installed | "matheus" |
| `ide.name` | string | IDE type | "cursor" |
| `ide.install_scope` | string | Installation scope | "project" |
| `jira.board_name` | string | JIRA board name | "Analytics Engineering" |
| `jira.board_id` | string | JIRA board key | "DAAENG" |
| `git.main_branch` | string | Main development branch | "main" |
| `git.release_branch` | string | Release branch | "release/main" |
| `team.name` | string | Team name | "Analytics Engineering" |
| `team.analytics_lead` | string | Lead email | "lead@company.com" |

## Security Considerations

### What's in config.json

✅ **Safe to commit:**
- IDE preferences
- JIRA board ID
- Git branch names
- Team name

❌ **Never add to config.json:**
- Passwords/tokens (use environment variables)
- API keys (use environment variables)
- Private information

### .autopilot/state.json (Git-ignored)

Runtime state is **never committed** to Git:

```bash
# .gitignore includes
.autopilot/state.json
.autopilot/*.json  # Only config.json would be checked in
```

## See Also

- `install.sh` - Bash installation script
- `README.md` - User guide
- `QUICK_TEST.md` - 5-minute validation
- `.autopilot/config.json` - Your configuration file
