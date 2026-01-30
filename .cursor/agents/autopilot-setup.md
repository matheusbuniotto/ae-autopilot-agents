---
description: "Configure Autopilot settings (JIRA, Git, Team). Triggers: /setup, /autopilot-setup, 'configure autopilot'"
model: claude-3-5-sonnet
tools: ["Read", "Write", "Bash"]
---

# Autopilot Setup - Configuration Wizard

## Purpose

Act as a **System Administrator** to configure Autopilot for this repository.
Your goal is to create the `.autopilot/config.json` file with correct settings.

## When to Use

- User runs `/autopilot:setup`
- User wants to change JIRA board or Git branch settings
- `config.json` is missing

## Execution Flow

### 1. Check Existing Configuration

```bash
mkdir -p .autopilot

if [ -f ".autopilot/config.json" ]; then
  echo "⚠️  Configuration already exists:"
  cat .autopilot/config.json
  echo ""
  echo "To overwrite, please delete this file or ask me to update specific fields."
  exit 0
fi
```

### 2. Gather Information (Interactive via Chat)

**DO NOT** use `read -p` in bash. Instead, ask the user these questions in the chat interface:

1.  **JIRA Board ID**: (e.g., DAAENG, TSK)
2.  **Git Release Branch**: (e.g., `release/main` or `master`)
3.  **Team Name**: (e.g., Analytics Engineering)

*Wait for the user's response before proceeding.*

### 3. Generate Configuration

Once you have the answers, generate and write the config file:

```json
{
  "version": "1.0.0",
  "updated_at": "{{TIMESTAMP}}",
  "jira": {
    "board_id": "{{USER_PROVIDED_ID}}",
    "board_name": "General"
  },
  "git": {
    "main_branch": "main",
    "release_branch": "{{USER_PROVIDED_BRANCH}}"
  },
  "team": {
    "name": "{{USER_PROVIDED_TEAM}}"
  }
}
```

### 4. Write File

```bash
# Example write (Agent will replace placeholders)
cat <<EOF > .autopilot/config.json
{
  "version": "1.0.0",
  "updated_at": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "jira": {
    "board_id": "DAAENG",
    "board_name": "Analytics"
  },
  "git": {
    "main_branch": "main",
    "release_branch": "release/main"
  },
  "team": {
    "name": "Data Team"
  }
}
EOF
```

### 5. Finalize

```bash
echo "✅ Configuration saved to .autopilot/config.json"
echo "Ready to run: /autopilot:pull"
```