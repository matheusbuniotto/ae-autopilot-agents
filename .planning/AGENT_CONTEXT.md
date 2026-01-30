# AE Autopilot - Agent Context Anchor ⚓️

**Last Updated:** 2026-01-29
**System:** Darwin (macOS)
**Repository Type:** dbt/SQL Monorepo

## 1. Project Identity
**AE Autopilot** is a stateless, file-driven orchestration layer for Analytics Engineers.
It is **NOT** a standalone CLI. It works by injecting **Skills** and **Context** into Cursor/OpenCode agents.

**Goal:** Automate repetitive AE tasks (Task -> Branch -> Plan -> Code -> PR).
**Target:** 2k+ Bronze/Silver/Gold models.

## 2. Architecture: "Context as Code"
The system relies on three layers:
1.  **Shared Intelligence (`shared/`)**:
    *   Prompts, Schemas, and Logic independent of the tool (Cursor vs OpenCode).
2.  **Platform Adapters**:
    *   `.cursor/rules/` & `.cursor/agents/`: Wrappers for Cursor.
    *   `.opencode/command/`: Wrappers for OpenCode.
3.  **State File (`.autopilot/state.json`)**:
    *   The "Brain". Persists context between command invocations.
    *   **Rule**: Always read this first. Always write to it before exiting.

## 3. Critical Paths
| Directory | Purpose |
| :--- | :--- |
| `.planning/` | Project management (STATE.md, ROADMAP.md). |
| `.autopilot/` | Runtime state (ignored by git). |
| `shared/prompts/` | Core logic (System Prompt, Git Rules, Classification). |
| `shared/schemas/` | JSON validation for State and Tasks. |
| `.cursor/rules/` | Cursor-specific context rules (.mdc). |
| `docs/` | Authoritative documentation (Overview, Workflows). |

## 4. Current Status (2026-01-29)
**Phase 1-4 are COMPLETE.**
*   ✅ Foundation & Safety
*   ✅ Task Intake & Classification
*   ✅ Execution & Validation
*   ✅ PR Creation & Orchestration

## 5. Core Mandates (DO NOT VIOLATE)
1.  **Git Safety**:
    *   NEVER `git add .`
    *   NEVER `git push --force`
    *   ALWAYS sync `release/main` before branching.
    *   Branch name must be `TSK-NNN`.
2.  **State Persistence**:
    *   If `state.json` exists, resume from it.
    *   If it conflicts with user input, ask for clarification.
3.  **No "Magic"**:
    *   Do not invent code styles. Follow the repo's existing SQL patterns.
    *   Do not merge PRs automatically.

## 6. Command Reference
| Command | Action | State Transition |
| :--- | :--- | :--- |
| `/pull TSK-123` | Fetch JIRA, Create Branch | `-> OPEN` |
| `/plan` | Analyze Complexity, Write Plan | `OPEN -> PLANNED` |
| `/execute-plan` | Write SQL/YAML | `PLANNED -> IN_PROGRESS` |
| `/review` | dbt build, Lint | `IN_PROGRESS -> VALIDATED` |
| `/pr` | Commit, Push, Open PR | `VALIDATED -> PR_READY` |
| `/launch` | Full Orchestration | `ALL STAGES` |

---
**Use this document to re-orient yourself if context is lost.**