# Autopilot — Analytics Engineer AI Companion

## What This Is

Autopilot is an AI companion system (agents, commands, skills, plugins) for Cursor/Claude that automates repetitive Analytics Engineering tasks. It takes JIRA tickets, executes the work end-to-end (dbt model changes, tests, docs), and opens PR-ready changes — eliminating manual drudgery for Analytics Engineer teams working on large dbt codebases (~2k Bronze, ~1k Silver, ~500 Gold tables).

Users install it locally in their notebook, run commands in Cursor IDE or OpenCode, and Autopilot handles the task execution with full safety guardrails.

## Core Value

Reliably automate Analytics Engineering tasks end-to-end, from JIRA task intake through PR creation, with safety guarantees that never break production or lose visibility into what happened.

## Requirements

### Validated

(None yet — ship to validate)

### Active

#### Core Execution Engine
- [ ] **EXEC-01**: Autopilot can pull JIRA task metadata and validate task structure
- [ ] **EXEC-02**: Autopilot classifies task complexity (L0–L3) based on dbt impact and Silver risk heuristics
- [ ] **EXEC-03**: Autopilot generates inline plans for L1 tasks and structured plans for L2+ tasks
- [ ] **EXEC-04**: Autopilot executes dbt model changes (creation, modification, SQL refactors) following team SQL style guide
- [ ] **EXEC-05**: Autopilot adds tests (schema, data, freshness) when needed, respecting existing patterns
- [ ] **EXEC-06**: Autopilot updates dbt docs and metadata when logic changes
- [ ] **EXEC-07**: Autopilot runs `dbt build` validation pre-PR with linting/formatting checks
- [ ] **EXEC-08**: Autopilot detects and reports impact (downstream models, size, risk) before changes

#### Git & PR Workflow
- [ ] **GIT-01**: Autopilot creates task branch (TSK-123 pattern) and manages commits atomically
- [ ] **GIT-02**: Autopilot enforces explicit staging (no `git add .`) and atomic, reviewable commits
- [ ] **GIT-03**: Autopilot opens PRs with structured template (JIRA link, classification, impacted models, dbt results)
- [ ] **GIT-04**: Autopilot blocks merge (no auto-merge); only creates PR and requests human approval

#### State & Resumability
- [ ] **STATE-01**: Autopilot persists execution state (.autopilot/state.json) for safe resumption
- [ ] **STATE-02**: Autopilot tracks all commits and "what was done" for debugging and handoff context
- [ ] **STATE-03**: Autopilot stops safely on errors; no silent failures or scope creep

#### Distribution & Integration
- [ ] **DIST-01**: Autopilot distributes as a local Git repository users clone and install
- [ ] **DIST-02**: Autopilot integrates with JIRA via configured credentials (outside v1 scope, but hookable)
- [ ] **DIST-03**: Autopilot integrates with Git/GitHub via local client (outside v1, but hookable)
- [ ] **DIST-04**: Autopilot integrates with dbt via configured project path and profile (outside v1, but hookable)

#### User Interface & Commands
- [ ] **CLI-01**: Autopilot provides composable commands: `pull`, `plan`, `execute-plan`, `review`, `pr`
- [ ] **CLI-02**: Autopilot provides unified `launch` command that runs full workflow (pull → plan → execute-plan → review → pr)
- [ ] **CLI-03**: Autopilot supports phase-by-phase execution for L3 tasks with `execute-plan --phase=N`
- [ ] **CLI-04**: Autopilot supports `--dry-run`, `--stop-after`, `--no-pr` flags for flexibility

#### Safety & Validation
- [ ] **SAFETY-01**: Autopilot enforces hard stops (release branch sync, task branch conflicts, classification failures)
- [ ] **SAFETY-02**: Autopilot enforces soft stops (task escalation, multi-phase checkpoints, ambiguous business logic)
- [ ] **SAFETY-03**: Autopilot respects Silver layer risk (escalates complexity for large, high-impact tables)
- [ ] **SAFETY-04**: Autopilot never runs `git push --force` or rewrites history
- [ ] **SAFETY-05**: Autopilot validates all changes (dbt build, tests, linting) before PR creation

### Out of Scope

- **Long-lived planning ceremonies** — Task-driven, adaptive planning only; no multi-hour planning sessions
- **Autonomous production deploys** — PR is the end; merge is human decision, not Autopilot's
- **Speculative refactors** — No refactoring without explicit JIRA task
- **Cross-task batching** — One task per PR, one branch per task
- **Direct JIRA/Git/dbt integration** — Configured outside Autopilot via CLI flags or MCP servers in v1
- **Multi-team orchestration** — v1 targets individual AEs or small squads; enterprise coordination is v2+
- **Web UI/dashboard** — v1 is CLI-first; web dashboard is v2+
- **Advanced AI planning** — v1 uses heuristic classification (dbt graph, table stats); no ML models
- **Rollback automation** — Rollback strategy documented in PR; human executes if needed
- **Custom SQL generation from natural language** — User provides SQL/structure; Autopilot enhances/validates

## Context

### Team Setup
- 3 squads (4–6 people each) working on single dbt repository
- Structured JIRA with clear acceptance criteria and labels
- Git workflow with PR templates and CI/CD validation
- dbt project with tests, docs, established patterns, and SQL style guide
- All infrastructure in place; Autopilot fills the execution gap

### Design Principles
- **Task-driven, not plan-driven** — JIRA defines intent; planning adapts to risk, not rigid phases
- **Safety with guardrails** — Full traceability, atomic commits, reversible changes, human approval before merge
- **PR is the contract** — If it's not in the PR, it didn't happen; all context flows through GitHub
- **No silent changes** — Every action is visible, loggable, debuggable

### Known Patterns to Respect
- dbt best practices (models, tests, docs, lineage)
- SQL style guide enforced by linting (if configured)
- Layer semantics: Bronze (raw), Silver (business logic), Gold (reporting)
- Silver models get special risk treatment (higher complexity ceiling, downstream impact assessment)
- Team comfort with explicit Git (no auto-merge, no force-push philosophy)

### Inspirations (Adapted, Not Copied)
- *get-shit-done* — structured task execution mindset
- Standard GitHub PR-based development workflows
- Large-scale Analytics Engineering operational patterns
- Note: All commits/PRs in Portuguese (PT-BR), except feature/fix prefixes (English)

## Constraints

- **Language**: Works within Cursor/Claude context window limits; must support session persistence for large tasks
- **Offline-first**: No external API dependencies except configured JIRA/Git/dbt (provided outside Autopilot)
- **Distribution**: Local Git repository; users clone and install; no package manager dependency
- **Git safety**: No force-push, no history rewriting, no `git add .`; explicit staging only
- **dbt environment**: Assumes dbt project with profiles.yml, project.yml; user provides path on first run
- **Team size**: v1 targets up to 18–24 concurrent users (3 squads); no enterprise sync needed yet

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Task-driven, not always planned | Most AE tasks are simple; planning overhead kills throughput | — Pending |
| Classification via heuristics (L0–L3) | Rule-based classification is fast, predictable, debuggable; avoids ML overhead | — Pending |
| Silver layer risk escalation | Silver models contain business logic; errors propagate; explicit risk assessment needed | — Pending |
| PR is primary artifact, not plans | PRs are where code review happens; plans are internal; PRs must contain all context | — Pending |
| No auto-merge, no silent execution | Team trust requires human approval; Autopilot stops at PR, not publish | — Pending |
| CLI commands, not web UI | Integrates with existing dev workflow (Cursor IDE); CLI is modal-agnostic | — Pending |
| Local distribution, not SaaS | Keeps data local, respects team autonomy, no infrastructure overhead | — Pending |

---

*Last updated: 2026-01-29 after initialization*
