# Autopilot Roadmap

**Phases: 4** | **Requirements: 25** | **Coverage: 100%**

## Phase Overview

| Phase | Name | Goal | Requirements | Success Criteria Count |
|-------|------|------|--------------|----------------------|
| 1 | Foundation & Safety Infrastructure | Users can safely initialize Autopilot with state persistence and Git guardrails | STATE-01, GIT-01, SAFETY-01, SAFETY-03, SAFETY-04 | 5 |
| 2 | Task Intake & Classification | Users can pull JIRA tasks and understand execution risk before changes | EXEC-01, EXEC-02, EXEC-08 | 4 |
| 3 | Execution & Validation | Users can execute dbt changes, tests, and validation with atomic commits and error handling | EXEC-03, EXEC-04, EXEC-05, EXEC-06, EXEC-07, GIT-02, STATE-03, SAFETY-02, SAFETY-05 | 5 |
| 4 | PR Creation & Agent Interface | Users can invoke composable agents to create PRs and run full workflows | GIT-03, GIT-04, STATE-02, UI-01, UI-02, UI-03, UI-04 | 5 |

---

## Phase 1: Foundation & Safety Infrastructure

**Goal:** Users can safely initialize Autopilot with state persistence and Git guardrails

**Requirements:** STATE-01, GIT-01, SAFETY-01, SAFETY-03, SAFETY-04

**What Gets Built:**
- `.autopilot/state.json` persistence layer for execution state tracking
- Task branch creation logic (TSK-123 naming pattern)
- Hard stop enforcement (release branch sync check, conflict detection, classification gate)
- Silver layer risk escalation heuristics
- Git safety rules (no force-push, no history rewriting)

**Success Criteria:**
1. User runs Autopilot and `.autopilot/state.json` is created/updated with execution context
2. User initiates task and Autopilot creates branch with TSK-123 pattern from current release branch
3. User attempts to run Autopilot on release branch and receives hard stop error
4. User works on Silver layer model and Autopilot flags risk escalation in classification
5. Autopilot never executes `git push --force` or `git rebase --interactive` commands

**Acceptance:** Phase is complete when all 5 success criteria are met.

---

## Phase 2: Task Intake & Classification

**Goal:** Users can pull JIRA tasks and understand execution risk before changes

**Requirements:** EXEC-01, EXEC-02, EXEC-08

**What Gets Built:**
- JIRA task metadata pull and validation logic
- L0-L3 complexity classification engine (based on dbt graph analysis, table stats, Silver layer detection)
- Downstream impact detection (affected models, size estimation, risk scoring)
- Task structure validation (acceptance criteria, labels, assignee)

**Success Criteria:**
1. User provides JIRA task ID and Autopilot pulls metadata (title, description, acceptance criteria, labels)
2. User task impacts 1 Bronze model and Autopilot classifies as L1 (simple)
3. User task impacts 1 Silver model with 50+ downstream dependencies and Autopilot classifies as L3 (complex)
4. User task is classified and Autopilot outputs downstream impact report (affected models, estimated rows, risk level)

**Acceptance:** Phase is complete when all 4 success criteria are met.

---

## Phase 3: Execution & Validation

**Goal:** Users can execute dbt changes, tests, and validation with atomic commits and error handling

**Requirements:** EXEC-03, EXEC-04, EXEC-05, EXEC-06, EXEC-07, GIT-02, STATE-03, SAFETY-02, SAFETY-05

**What Gets Built:**
- Inline plan generation for L1 tasks
- Structured plan generation for L2+ tasks with phases
- dbt model execution (creation, modification, SQL refactors) following SQL style guide
- Test generation (schema, data, freshness tests) respecting existing patterns
- dbt docs and metadata updates on logic changes
- `dbt build` validation with linting/formatting checks
- Explicit staging (no `git add .`), atomic commits with clear messages
- Safe error handling (stops execution, preserves state, no silent failures)
- Soft stop enforcement (task escalation prompts, multi-phase checkpoints, ambiguous logic warnings)

**Success Criteria:**
1. User executes L1 task and Autopilot generates inline plan (single-phase, no sub-tasks)
2. User executes L2 task and Autopilot generates structured plan with phases and checkpoints
3. User task completes dbt model changes and Autopilot commits with explicit file staging (shows `git add path/to/file.sql`, not `git add .`)
4. User task completes and Autopilot runs `dbt build` validation, reporting success/failure with linting results
5. User task encounters error (SQL syntax, missing ref) and Autopilot stops safely, logs error in state.json, does not continue

**Acceptance:** Phase is complete when all 5 success criteria are met.

---

## Phase 4: PR Creation & Agent Interface

**Goal:** Users can invoke composable agents to create PRs and run full workflows

**Requirements:** GIT-03, GIT-04, STATE-02, UI-01, UI-02, UI-03, UI-04

**What Gets Built:**
- PR creation with structured template (JIRA link, classification, impacted models, dbt build results)
- Merge blocking (no auto-merge, human approval required)
- Commit tracking and "what was done" summary for debugging/handoff
- Composable agents/skills: `autopilot:pull`, `autopilot:plan`, `autopilot:execute-plan`, `autopilot:review`, `autopilot:pr`
- Unified `autopilot:launch` agent (full workflow: pull → plan → execute-plan → review → pr)
- Phase-by-phase execution for L3 tasks via agent parameters
- Flexible execution modes (dry-run, stop-after checkpoint, PR-only mode)

**Success Criteria:**
1. User runs `autopilot:pull` and JIRA metadata is fetched; then runs `autopilot:plan` and plan is generated; both agents work independently
2. User runs `autopilot:launch` and full workflow executes (pull → plan → execute → review → PR created)
3. User completes L3 task and Autopilot creates PR with structured template (JIRA link, L3 classification, list of impacted models, dbt build output)
4. User task completes and Autopilot blocks merge (PR description states "Human approval required, do not auto-merge")
5. User runs `autopilot:execute-plan --phase=2` on L3 task and Autopilot executes only phase 2, stops, preserves state

**Acceptance:** Phase is complete when all 5 success criteria are met.

---

## Requirement Coverage

Verify all 25 v1 requirements are mapped:

**Phase 1: Foundation & Safety Infrastructure (5 requirements)**
- [x] STATE-01: Autopilot persists execution state (.autopilot/state.json)
- [x] GIT-01: Autopilot creates task branch (TSK-123 pattern) and manages commits atomically
- [x] SAFETY-01: Autopilot enforces hard stops (release branch sync, task branch conflicts, classification failures)
- [x] SAFETY-03: Autopilot respects Silver layer risk (escalates complexity for large, high-impact tables)
- [x] SAFETY-04: Autopilot never runs `git push --force` or rewrites history

**Phase 2: Task Intake & Classification (3 requirements)**
- [x] EXEC-01: Autopilot can pull JIRA task metadata and validate task structure
- [x] EXEC-02: Autopilot classifies task complexity (L0–L3) based on dbt impact and Silver risk heuristics
- [x] EXEC-08: Autopilot detects and reports impact (downstream models, size, risk) before changes

**Phase 3: Execution & Validation (9 requirements)**
- [x] EXEC-03: Autopilot generates inline plans for L1 tasks and structured plans for L2+ tasks
- [x] EXEC-04: Autopilot executes dbt model changes (creation, modification, SQL refactors) following team SQL style guide
- [x] EXEC-05: Autopilot adds tests (schema, data, freshness) when needed, respecting existing patterns
- [x] EXEC-06: Autopilot updates dbt docs and metadata when logic changes
- [x] EXEC-07: Autopilot runs `dbt build` validation pre-PR with linting/formatting checks
- [x] GIT-02: Autopilot enforces explicit staging (no `git add .`) and atomic, reviewable commits
- [x] STATE-03: Autopilot stops safely on errors; no silent failures or scope creep
- [x] SAFETY-02: Autopilot enforces soft stops (task escalation, multi-phase checkpoints, ambiguous business logic)
- [x] SAFETY-05: Autopilot validates all changes (dbt build, tests, linting) before PR creation

**Phase 4: PR Creation & Agent Interface (8 requirements)**
- [x] GIT-03: Autopilot opens PRs with structured template (JIRA link, classification, impacted models, dbt results)
- [x] GIT-04: Autopilot blocks merge (no auto-merge); only creates PR and requests human approval
- [x] STATE-02: Autopilot tracks all commits and "what was done" for debugging and handoff context
- [x] UI-01: Autopilot provides composable agents/skills/commands: `autopilot:pull`, `autopilot:plan`, `autopilot:execute-plan`, `autopilot:review`, `autopilot:pr`
- [x] UI-02: Autopilot provides unified `autopilot:launch` command that runs full workflow (pull → plan → execute-plan → review → pr)
- [x] UI-03: Autopilot supports phase-by-phase execution for L3 tasks via agent parameters
- [x] UI-04: Autopilot supports flexible execution modes (dry-run, stop-after checkpoint, PR-only mode)

**Total: 25/25 ✓**

All EXEC requirements (8) mapped ✓
All GIT requirements (4) mapped ✓
All STATE requirements (3) mapped ✓
All UI requirements (4) mapped ✓
All SAFETY requirements (5) mapped ✓

---

*Roadmap created: 2026-01-29*
