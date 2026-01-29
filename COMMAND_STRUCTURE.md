# Autopilot Command Structure (Like `/gsd:`)

This document explains how Autopilot commands are structured and auto-discovered by Cursor/Claude Code and OpenCode.

## Auto-Discovery Mechanism

### Cursor / Claude Code

**How it works:**
1. Cursor scans `.cursor/agents/` for `*.md` files
2. Reads YAML frontmatter (the `---` section at top)
3. Extracts `description` field
4. Auto-creates commands with pattern `/autopilot:*`

**File → Command Mapping:**
```
.cursor/agents/autopilot-pull.md         → /autopilot:pull
.cursor/agents/autopilot-plan.md         → /autopilot:plan
.cursor/agents/autopilot-execute-plan.md → /autopilot:execute-plan
.cursor/agents/autopilot-review.md       → /autopilot:review
.cursor/agents/autopilot-pr.md           → /autopilot:pr
.cursor/agents/autopilot-launch.md       → /autopilot:launch
```

### OpenCode

**How it works:**
1. OpenCode scans `.opencode/command/` for `*.md` files
2. Reads YAML frontmatter for metadata
3. Auto-creates commands with pattern `autopilot *`

**File → Command Mapping:**
```
.opencode/command/autopilot-pull.md         → autopilot pull
.opencode/command/autopilot-plan.md         → autopilot plan
.opencode/command/autopilot-execute-plan.md → autopilot execute-plan
.opencode/command/autopilot-review.md       → autopilot review
.opencode/command/autopilot-pr.md           → autopilot pr
.opencode/command/autopilot-launch.md       → autopilot launch
```

## Skill File Structure

Each skill is a **self-contained agent definition** with this structure:

### YAML Frontmatter (Required)

```yaml
---
description: "Brief purpose (shown in UI)"
model: claude-opus-4-5
tools: ["Read", "Write", "Bash"]
---
```

**Fields:**
- `description` - Command purpose (max ~80 chars, shown in autocomplete)
- `model` - Claude model to use (currently claude-opus-4-5)
- `tools` - Allowed tools for this agent (safety boundary)

### Markdown Body (Execution Guide)

The rest of the file is a detailed guide that Claude follows to execute the command:

```markdown
# Title - Clear Purpose

## Purpose
[What this stage does]
[When to use it]
[Expected input/output]

## Execution Flow

### 1. [First step]
[Bash code block with exact commands]
[Error handling]

### 2. [Second step]
[More execution details]

...

## Error Recovery
[How to handle failures]

## Files Modified
[What gets created/changed]

## Safety Rules Applied
[Which rules from .cursor/rules/ are enforced]
```

## Rules (Global Constraints)

Rules in `.cursor/rules/` apply to ALL skills:

### `git-safety.mdc`
```
Enforces:
✅ Never git add .
✅ Never git push --force
✅ Never git commit --amend
✅ Always explicit file staging
✅ Hard stop on conflicts, outdated branch, dangerous operations
```

### `autopilot-core.mdc`
```
Defines:
✅ State machine stages (pull → plan → execute-plan → review → pr)
✅ Resumability logic (skip completed stages)
✅ State persistence (atomic writes)
✅ Checkpoint system (soft stops for human input)
✅ Error recovery patterns
```

These rules are **always active** - Claude respects them when executing skills.

## State Schema (Validation)

State is validated against `shared/schemas/state-schema.json`:

```json
{
  "task_id": "TSK-123",           // Required
  "branch": "TSK-123",             // Required
  "stage": "pull",                 // Required, enum
  "classification": "L2",          // Optional, enum L0-L3
  "plan": {
    "exists": true,
    "phases": [],
    "completed_phases": []
  },
  "commits": [],                   // Array of commit refs
  "timestamps": {
    "started_at": "ISO8601",      // Required
    "last_updated": "ISO8601"
  }
}
```

**Validation:** State is checked before resuming, ensuring no corruption.

## Complete File Organization

```
ae-autopilot/
├── .cursor/
│   ├── agents/
│   │   ├── autopilot-pull.md              [317 lines - IMPLEMENTED]
│   │   ├── autopilot-plan.md              [Phase 2]
│   │   ├── autopilot-execute-plan.md      [Phase 3]
│   │   ├── autopilot-review.md            [Phase 3]
│   │   ├── autopilot-pr.md                [Phase 4]
│   │   └── autopilot-launch.md            [Phase 4]
│   └── rules/
│       ├── git-safety.mdc                 [324 lines]
│       └── autopilot-core.mdc             [368 lines]
│
├── .opencode/
│   └── command/
│       ├── autopilot-pull.md              [Full impl]
│       ├── autopilot-plan.md              [Phase 2]
│       ├── autopilot-execute-plan.md      [Phase 3]
│       ├── autopilot-review.md            [Phase 3]
│       ├── autopilot-pr.md                [Phase 4]
│       └── autopilot-launch.md            [Phase 4]
│
├── shared/
│   ├── prompts/
│   │   ├── classification.md              [252 lines]
│   │   └── git-operations.md              [185 lines]
│   └── schemas/
│       ├── state-schema.json              [125 lines]
│       ├── task-schema.json               [95 lines]
│       └── classification-schema.json     [120 lines]
│
├── .autopilot/                            [Runtime state]
│   ├── state.json                         [Created at runtime]
│   ├── task.json                          [Created at runtime]
│   └── classification.json                [Created at runtime]
│
└── Documentation
    ├── README.md                          [User guide]
    ├── HOW_TO_USE.md                      [Command reference]
    ├── COMMAND_STRUCTURE.md               [This file]
    ├── IMPLEMENTATION_SUMMARY.md          [Technical details]
    └── PHASE_1_COMPLETE.md                [Quick reference]
```

## How Commands Are Invoked

### Cursor Workflow

```
User types: /autopilot:pull TSK-123
                    ↓
         Cursor detects command
                    ↓
    Loads .cursor/agents/autopilot-pull.md
                    ↓
    Reads YAML frontmatter:
      - description
      - model: claude-opus-4-5
      - tools: ["Read", "Write", "Bash"]
                    ↓
    Claude Opus 4.5 loads:
      1. Skill file (Markdown body)
      2. Global rules (.cursor/rules/*.mdc)
      3. Shared prompts (shared/prompts/*.md)
                    ↓
    Claude executes:
      1. Validate JIRA task ID format
      2. Fetch JIRA task metadata
      3. Create Git branch
      4. Initialize state file
      5. Persist .autopilot/state.json
                    ↓
    Output displayed to user
    State saved for resumability
```

### OpenCode Workflow

```
User types: autopilot pull TSK-123
                    ↓
    OpenCode detects command
                    ↓
    Loads .opencode/command/autopilot-pull.md
                    ↓
    Parses arguments: $TASK_ID="TSK-123"
                    ↓
    Executes command following Cursor version
    (Same logic, platform-specific invocation)
```

## Resumability Example

### Day 1: Start work
```bash
/autopilot:launch TSK-123

Executes:
  1. pull      ✅
  2. plan      ✅
  3. execute-plan (phase 1)  ✅
  ⏸️  Soft stop: Phase 2 checkpoint
```

State saved:
```json
{
  "stage": "execute-plan",
  "plan": { "completed_phases": ["phase_1"] }
}
```

### Day 2: Resume work
```bash
/autopilot:launch TSK-123

Claude detects:
  1. state.json exists
  2. stage = execute-plan
  3. completed_phases = ["phase_1"]

Executes:
  1. pull      ⏭️  SKIP (already done)
  2. plan      ⏭️  SKIP (already done)
  3. execute-plan  → Resume at phase 2
  4. review    ✅
  5. pr        ✅

Never duplicates work!
```

## Command Arguments

### Cursor Style
```bash
/autopilot:pull TSK-123                   # Positional
/autopilot:execute-plan --phase=2         # Named flags
/autopilot:launch TSK-123 --dry-run       # Multiple args
```

### OpenCode Style
```bash
autopilot pull TSK-123                    # Positional
autopilot execute-plan --phase=2          # Named flags
autopilot launch TSK-123 --dry-run        # Multiple args
```

Arguments are parsed and passed to the skill via environment or parameters.

## Adding a New Command

To add a new Autopilot command (e.g., `autopilot:debug`):

1. **Create Cursor skill:**
   ```bash
   touch .cursor/agents/autopilot-debug.md
   ```

2. **Add frontmatter:**
   ```yaml
   ---
   description: "Debug task execution and state"
   model: claude-opus-4-5
   tools: ["Read", "Write", "Bash"]
   ---
   ```

3. **Write execution guide** in Markdown

4. **Mirror for OpenCode:**
   ```bash
   touch .opencode/command/autopilot-debug.md
   ```

5. **Restart IDE** to discover new command

6. **Test:**
   ```bash
   /autopilot:debug
   ```

That's it! Auto-discovery takes care of the rest.

## Validation & Quality

### Schema Validation
All state files validated against `shared/schemas/state-schema.json`:
```bash
jq empty .autopilot/state.json  # Ensures valid JSON
# Plus schema validation by Claude before writes
```

### Rule Enforcement
Global rules apply to all skills:
- Git safety rules prevent dangerous operations
- Core behavior rules enforce state transitions
- Soft stops require human confirmation

### Error Messages
All errors include:
```
❌ ERROR_TYPE: Short message

Details: What went wrong
Reason: Why it matters
Actions: How to fix
State: Saved for resumability
```

## Discovery & Debugging

### List Available Commands
```bash
# Cursor will show these in autocomplete after /autopilot:
/autopilot:
  pull
  plan
  execute-plan
  review
  pr
  launch
```

### Check Command is Valid
```bash
# Verify skill file exists and has valid frontmatter
ls -la .cursor/agents/autopilot-pull.md
head -10 .cursor/agents/autopilot-pull.md
# Should show YAML frontmatter with --- delimiters
```

### Restart IDE
If commands don't appear:
1. Restart Cursor / Claude Code
2. Or kill and relaunch the IDE
3. Run command again

## Architecture Summary

| Component | Purpose | Location |
|-----------|---------|----------|
| Skills | Command logic | `.cursor/agents/`, `.opencode/command/` |
| Rules | Global constraints | `.cursor/rules/` |
| Schemas | State validation | `shared/schemas/` |
| Prompts | Decision frameworks | `shared/prompts/` |
| State | Execution context | `.autopilot/` (Git-ignored) |
| Docs | User guides | Root and `docs/` |

---

**This is Phase 1 - Foundation Complete**

All 6 commands are defined and ready to use in Cursor/OpenCode.

See `HOW_TO_USE.md` for command reference and examples.
