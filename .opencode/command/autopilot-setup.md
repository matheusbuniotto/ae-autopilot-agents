---
description: "Interactive setup wizard for Autopilot"
arguments: "[--project-only|--quiet|--force]"
---

# Autopilot Setup (OpenCode)

## Usage

```bash
autopilot setup
autopilot setup --project-only
autopilot setup --quiet
autopilot setup --force
```

See Cursor version for full documentation: `.cursor/agents/autopilot-setup.md`

This command runs the same interactive setup as the bash `install.sh` script.

## What It Does

1. Checks prerequisites (Git, dbt)
2. Asks which IDE (Cursor, OpenCode, Both)
3. Asks installation scope (project-local, global)
4. Configures JIRA settings
5. Configures Git branches
6. Collects team information
7. Installs Autopilot files
8. Creates `.autopilot/config.json`
9. Verifies installation

## Output

Creates:
- `.autopilot/config.json` - Your configuration
- `.cursor/` or `~/.cursor/` - Cursor agents
- `.opencode/` or `~/.opencode/` - OpenCode commands
- `shared/` or `~/shared/` - Shared schemas/prompts
- Updated `.gitignore` with `.autopilot/` rules

## Next Steps

1. Restart OpenCode
2. Run: `autopilot pull TSK-TEST`
3. Verify: `cat .autopilot/state.json`
