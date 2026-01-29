# Requirements: Autopilot

**Defined:** 2026-01-29
**Core Value:** Reliably automate Analytics Engineering tasks end-to-end, from JIRA task intake through PR creation, with safety guarantees that never break production or lose visibility into what happened.

## v1 Requirements

Requirements for initial release. Focus: Execution Engine, Git & PR Workflow, State & Resumability, CLI Commands.

### Core Execution Engine

- [ ] **EXEC-01**: Autopilot can pull JIRA task metadata and validate task structure
- [ ] **EXEC-02**: Autopilot classifies task complexity (L0–L3) based on dbt impact and Silver risk heuristics
- [ ] **EXEC-03**: Autopilot generates inline plans for L1 tasks and structured plans for L2+ tasks
- [ ] **EXEC-04**: Autopilot executes dbt model changes (creation, modification, SQL refactors) following team SQL style guide
- [ ] **EXEC-05**: Autopilot adds tests (schema, data, freshness) when needed, respecting existing patterns
- [ ] **EXEC-06**: Autopilot updates dbt docs and metadata when logic changes
- [ ] **EXEC-07**: Autopilot runs `dbt build` validation pre-PR with linting/formatting checks
- [ ] **EXEC-08**: Autopilot detects and reports impact (downstream models, size, risk) before changes

### Git & PR Workflow

- [ ] **GIT-01**: Autopilot creates task branch (TSK-123 pattern) and manages commits atomically
- [ ] **GIT-02**: Autopilot enforces explicit staging (no `git add .`) and atomic, reviewable commits
- [ ] **GIT-03**: Autopilot opens PRs with structured template (JIRA link, classification, impacted models, dbt results)
- [ ] **GIT-04**: Autopilot blocks merge (no auto-merge); only creates PR and requests human approval

### State & Resumability

- [ ] **STATE-01**: Autopilot persists execution state (.autopilot/state.json) for safe resumption
- [ ] **STATE-02**: Autopilot tracks all commits and "what was done" for debugging and handoff context
- [ ] **STATE-03**: Autopilot stops safely on errors; no silent failures or scope creep

### User Interface & Agents/Skills

- [ ] **UI-01**: Autopilot provides composable agents/skills/commands: `autopilot:pull`, `autopilot:plan`, `autopilot:execute-plan`, `autopilot:review`, `autopilot:pr`
- [ ] **UI-02**: Autopilot provides unified `autopilot:launch` command that runs full workflow (pull → plan → execute-plan → review → pr)
- [ ] **UI-03**: Autopilot supports phase-by-phase execution for L3 tasks via agent parameters
- [ ] **UI-04**: Autopilot supports flexible execution modes (dry-run, stop-after checkpoint, PR-only mode)

### Safety & Core Validation

- [ ] **SAFETY-01**: Autopilot enforces hard stops (release branch sync, task branch conflicts, classification failures)
- [ ] **SAFETY-02**: Autopilot enforces soft stops (task escalation, multi-phase checkpoints, ambiguous business logic)
- [ ] **SAFETY-03**: Autopilot respects Silver layer risk (escalates complexity for large, high-impact tables)
- [ ] **SAFETY-04**: Autopilot never runs `git push --force` or rewrites history
- [ ] **SAFETY-05**: Autopilot validates all changes (dbt build, tests, linting) before PR creation

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Distribution & Integration

- **DIST-01**: Autopilot distributes as a local Git repository users clone and install
- **DIST-02**: Autopilot integrates with JIRA via configured credentials (via CLI flags or MCP servers)
- **DIST-03**: Autopilot integrates with Git/GitHub via local client (via CLI flags or MCP servers)
- **DIST-04**: Autopilot integrates with dbt via configured project path and profile (via CLI flags or MCP servers)

### Advanced Safety & Observability

- **ADV-01**: Autopilot provides audit logs for all actions (commit tracking, validation results)
- **ADV-02**: Autopilot detects and prevents breaking changes (contract violations, critical model errors)
- **ADV-03**: Autopilot generates rollback strategies when needed
- **ADV-04**: Autopilot provides observability dashboard (logs, execution history)

### Multi-Team & Enterprise

- **ENT-01**: Autopilot supports multi-team orchestration (cross-squad task batching, shared governance)
- **ENT-02**: Autopilot provides admin controls and usage tracking
- **ENT-03**: Autopilot integrates with enterprise JIRA/GitHub instances

## Out of Scope

| Feature | Reason |
|---------|--------|
| Long-lived planning ceremonies | Task-driven, adaptive planning only; no multi-hour planning sessions |
| Autonomous production deploys | PR is the end; merge is human decision, not Autopilot's |
| Speculative refactors | No refactoring without explicit JIRA task |
| Cross-task batching | One task per PR, one branch per task |
| Web UI/dashboard | v1 is CLI-first; web dashboard is v2+ |
| Advanced AI planning | v1 uses heuristic classification (dbt graph, table stats); no ML models |
| Rollback automation | Rollback strategy documented in PR; human executes if needed |
| Custom SQL generation | User provides SQL/structure; Autopilot enhances/validates |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| EXEC-01 | Phase 1 | Pending |
| EXEC-02 | Phase 1 | Pending |
| EXEC-03 | Phase 2 | Pending |
| EXEC-04 | Phase 2 | Pending |
| EXEC-05 | Phase 2 | Pending |
| EXEC-06 | Phase 2 | Pending |
| EXEC-07 | Phase 2 | Pending |
| EXEC-08 | Phase 2 | Pending |
| GIT-01 | Phase 1 | Pending |
| GIT-02 | Phase 2 | Pending |
| GIT-03 | Phase 3 | Pending |
| GIT-04 | Phase 3 | Pending |
| STATE-01 | Phase 1 | Pending |
| STATE-02 | Phase 3 | Pending |
| STATE-03 | Phase 2 | Pending |
| UI-01 | Phase 3 | Pending |
| UI-02 | Phase 3 | Pending |
| UI-03 | Phase 3 | Pending |
| UI-04 | Phase 3 | Pending |
| SAFETY-01 | Phase 1 | Pending |
| SAFETY-02 | Phase 2 | Pending |
| SAFETY-03 | Phase 1 | Pending |
| SAFETY-04 | Phase 1 | Pending |
| SAFETY-05 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 25 total
- Mapped to phases: 0 (pending roadmap creation)
- Unmapped: 25 ⚠️

---
*Requirements defined: 2026-01-29*
*Last updated: 2026-01-29 after initial definition*
