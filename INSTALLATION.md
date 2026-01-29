# Autopilot Installation Guide

Complete guide to installing Autopilot in your analytics repository.

## Quick Install (2 Minutes)

```bash
# From ae-autopilot repository root
bash install.sh

# Follow interactive prompts:
# 1. Choose IDE (Cursor/OpenCode)
# 2. Choose scope (project or global)
# 3. Enter JIRA board details
# 4. Enter Git branch names
# 5. Confirm installation

# Verify installation
/autopilot:pull TSK-TEST
cat .autopilot/state.json
```

## Installation Methods

### Method 1: Bash Script (Recommended)

**Best for:** One-time setup, automated installs, CI/CD

```bash
cd your-analytics-repo

# Copy install script
curl -O https://raw.githubusercontent.com/your-org/ae-autopilot/main/install.sh
chmod +x install.sh

# Run interactive setup
bash install.sh

# Or use flags
bash install.sh --project-only      # Config only, no IDE setup
bash install.sh --quiet              # Use defaults, no prompts
bash install.sh --force              # Overwrite existing config
```

**What it does:**
1. Validates Git, dbt, repository structure
2. Prompts for IDE, scope, JIRA, Git settings
3. Copies Autopilot files to appropriate location
4. Creates `.autopilot/config.json`
5. Verifies installation
6. Shows next steps

### Method 2: Interactive Setup Command

**Best for:** In-IDE setup, quick configuration

**In Cursor:**
```bash
/autopilot:setup
```

**In OpenCode:**
```bash
autopilot setup
```

Same prompts and process as bash script, but integrated into your IDE.

### Method 3: Manual Installation

**Best for:** Custom setups, understanding what's installed

```bash
# 1. Copy agent and command files
cd your-analytics-repo
mkdir -p .cursor/agents .cursor/rules .opencode/command shared/{schemas,prompts}

# Copy from ae-autopilot repo
cp ae-autopilot/.cursor/agents/*.md .cursor/agents/
cp ae-autopilot/.cursor/rules/*.mdc .cursor/rules/
cp ae-autopilot/.opencode/command/*.md .opencode/command/
cp -r ae-autopilot/shared/* shared/

# 2. Create configuration directory
mkdir -p .autopilot

# 3. Create config.json (use template below)
cat > .autopilot/config.json << 'EOF'
{
  "version": "1.0.0-phase1",
  "installed_at": "2026-01-29T20:00:00Z",
  "ide": { "name": "cursor", "install_scope": "project" },
  "jira": { "board_name": "Analytics", "board_id": "DAAENG" },
  "git": { "main_branch": "main", "release_branch": "release/main" },
  "team": { "name": "Analytics Engineering", "analytics_lead": "you@company.com" }
}
EOF

# 4. Update .gitignore
echo ".autopilot/" >> .gitignore
echo "!.autopilot/.gitkeep" >> .gitignore
mkdir -p .autopilot
touch .autopilot/.gitkeep

# 5. Verify
ls -la .cursor/agents/
ls -la shared/schemas/
cat .autopilot/config.json | jq .

# 6. Restart IDE
```

## Installation Scope

### Project-Local Installation

**Files go in your repository:**

```
your-repo/
├── .cursor/agents/       ← Committed to Git
├── .cursor/rules/        ← Committed to Git
├── .opencode/command/    ← Committed to Git
├── shared/               ← Committed to Git
├── .autopilot/           ← Git-ignored
│   ├── config.json       ← Committed
│   ├── state.json        ← Git-ignored (runtime)
│   └── .gitkeep
└── .gitignore            ← Committed
```

**Advantages:**
- Works in any dbt repository
- All settings version-controlled
- Easy to share across team
- No global configuration needed

**Disadvantages:**
- Takes space in each repository
- Must install in every project

### Global Installation

**Files go in your home directory:**

```
$HOME/
├── .cursor/agents/       ← Shared across projects
├── .cursor/rules/        ← Shared across projects
├── .opencode/command/    ← Shared across projects
└── shared/               ← Shared across projects

your-repo/
├── .autopilot/
│   ├── config.json       ← Project-specific
│   └── state.json        ← Runtime state
└── .gitignore
```

**Advantages:**
- Install once, use everywhere
- Less duplication
- Easier updates

**Disadvantages:**
- Requires home directory write access
- Configuration still project-specific

## Prerequisites

Before installing, verify you have:

### Git

```bash
# Verify Git is installed and configured
git config user.name     # Should show your name
git config user.email    # Should show your email

# If not configured:
git config user.name "Your Name"
git config user.email "you@company.com"
```

### dbt CLI

```bash
# Verify dbt is installed
dbt --version

# If not installed:
pip install dbt-postgres  # or dbt-snowflake, dbt-bigquery

# Verify connection works
dbt debug
```

### Repository

```bash
# Must be in a Git repository
git status   # Should work, not "not a git repository"

# Should be a dbt project (has dbt_project.yml)
ls dbt_project.yml   # Should exist
```

### IDE

```bash
# Cursor
cursor --version

# Or OpenCode
# (depends on your platform)
```

## Configuration

After installation, Autopilot creates `.autopilot/config.json` with your settings:

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
    "mcp_configured": false
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

### Updating Configuration

Edit `.autopilot/config.json` directly:

```bash
# Edit in your editor
nano .autopilot/config.json

# Or use jq
jq '.jira.board_id = "NEWID"' .autopilot/config.json > /tmp/config.json
mv /tmp/config.json .autopilot/config.json
```

Or re-run setup:

```bash
bash install.sh
# Will ask if you want to overwrite existing config
```

## Post-Installation

### 1. Restart IDE

Fully quit and reopen your IDE for command discovery:

```bash
# Cursor: Fully quit (not just close window)
# Wait 5 seconds
# Reopen Cursor
```

### 2. Verify Commands Appear

**In Cursor:**
- Type: `/autopilot:`
- Should see 6 commands in autocomplete

**In OpenCode:**
- Type: `autopilot`
- Should see commands

### 3. Run Quick Test

```bash
# Test pull command
/autopilot:pull TSK-TEST

# Verify state file created
cat .autopilot/state.json

# Verify branch created
git branch -v | grep TSK-TEST

# Verify branch is Git-ignored
git status | grep .autopilot  # Should NOT appear
```

If all checks pass, installation is complete ✅

### 4. Read Documentation

- **README.md** - User guide
- **HOW_TO_USE.md** - Command reference
- **QUICK_TEST.md** - 5-minute validation
- **TESTING_GUIDE.md** - Comprehensive testing

## Troubleshooting Installation

### Problem: Commands Don't Appear

**Symptom:** Type `/autopilot:` but no commands show

**Fixes:**
1. Fully quit IDE (not just close window) and reopen
2. Verify files exist: `ls -la .cursor/agents/`
3. Check YAML syntax in skill files (should have `---` markers)
4. Try typing full path: `/autopilot:pull` (instead of just `/autopilot:`)

### Problem: State File Not Created

**Symptom:** `/autopilot:pull` runs but `.autopilot/state.json` not created

**Fixes:**
1. Check directory exists: `mkdir -p .autopilot`
2. Verify permissions: `ls -la .autopilot/` (should be writable)
3. Verify .gitignore isn't blocking: `git check-ignore .autopilot/state.json`
4. Try manual test: `echo '{}' > .autopilot/test.json` (should work)

### Problem: Git Branch Not Created

**Symptom:** `/autopilot:pull` runs but no Git branch created

**Fixes:**
1. Verify on clean working tree: `git status` (should be clean)
2. Verify release branch exists: `git branch -r | grep release`
3. Verify Git is working: `git pull origin release/main`
4. Check Git credentials: `git fetch` (should work without prompts)

### Problem: Config.json Syntax Error

**Symptom:** Invalid JSON error when loading config

**Fixes:**
1. Validate JSON: `jq empty .autopilot/config.json`
2. If invalid, re-run setup: `bash install.sh --force`
3. Or manually fix: `nano .autopilot/config.json` (check for missing commas, quotes)

### Problem: JIRA Configuration Issues

**Symptom:** JIRA task pull fails with authentication error

**Fixes:**
1. Verify JIRA MCP configured: Check JIRA setup documentation
2. Check board ID: `jq .jira.board_id .autopilot/config.json`
3. Update config if needed: `bash install.sh`
4. See Phase 2 documentation for JIRA integration

## Installation in CI/CD

### GitHub Actions Example

```yaml
name: Install Autopilot
on: [push]

jobs:
  install:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Autopilot
        run: |
          bash install.sh --quiet --force

      - name: Verify Installation
        run: |
          test -d .cursor/agents
          test -d .opencode/command
          test -f .autopilot/config.json
          jq empty .autopilot/config.json

      - name: Commit Configuration
        run: |
          git add .autopilot/config.json
          git commit -m "chore: add Autopilot configuration"
          git push
```

### Docker Example

```dockerfile
FROM python:3.11

# Install dependencies
RUN pip install dbt-postgres

# Copy repo
COPY . /workspace
WORKDIR /workspace

# Install Autopilot
RUN bash install.sh --quiet --force

# Run tests
RUN /autopilot:pull TSK-TEST
RUN cat .autopilot/state.json | jq .
```

## Uninstallation

If you need to remove Autopilot:

```bash
# Remove files (project-local)
rm -rf .cursor .opencode shared .autopilot

# Remove from .gitignore
sed -i '' '/.autopilot/d' .gitignore

# Or remove globally
rm -rf ~/.cursor ~/.opencode ~/shared

# Commit changes
git add .gitignore
git commit -m "chore: remove Autopilot"
```

## Multi-Project Installation

Install Autopilot in multiple projects:

```bash
# Project A
cd ~/repo-a
bash ~/ae-autopilot/install.sh

# Project B
cd ~/repo-b
bash ~/ae-autopilot/install.sh

# Each project has independent configuration
cat ~/repo-a/.autopilot/config.json
cat ~/repo-b/.autopilot/config.json
```

Each project maintains separate configuration, but can share global IDE files.

## Next Steps

After successful installation:

1. **Read QUICK_TEST.md** (5 minutes)
   - Basic validation of installation

2. **Try a Real Task**
   ```bash
   /autopilot:pull TSK-123
   /autopilot:plan
   /autopilot:launch TSK-123
   ```

3. **Review Configuration**
   ```bash
   cat .autopilot/config.json | jq .
   ```

4. **Troubleshoot if Needed**
   - See TESTING_GUIDE.md for comprehensive diagnostics

5. **Plan Phase 2**
   - Full classification engine
   - dbt integration
   - Workflow automation

## Getting Help

- **README.md** - Quick start
- **HOW_TO_USE.md** - Command reference
- **TESTING_GUIDE.md** - Troubleshooting
- **GitHub Issues** - Report problems

---

**Version:** 1.0.0-phase1
**Last Updated:** 2026-01-29
**Status:** Ready for production use
