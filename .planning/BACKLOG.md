# Autopilot — Backlog & Future Features

This document tracks features, improvements, and work deferred from v1.

## v2 Requirements

### Distribution & Integration

Autopilot's initial release assumes local setup and manual configuration. v2 will improve distribution and external system integration.

- **DIST-01**: Distribute Autopilot as installable package (Git repo, package manager, Cursor extension)
- **DIST-02**: JIRA integration via configured credentials (CLI flags, environment variables, MCP servers)
- **DIST-03**: GitHub integration via local git client (assumes gh CLI or GitHub MCP is available)
- **DIST-04**: dbt integration via profile path and project configuration
- **DIST-05**: Support for Cursor extensions and OpenCode plugins

### Advanced Safety & Observability

v2 will add structured observability and more sophisticated guardrails.

- **ADV-01**: Audit logs for all executed actions (commit tracking, validation results, user context)
- **ADV-02**: Contract violation detection (breaking changes to Gold models, metric definitions)
- **ADV-03**: Automated rollback strategy generation (git revert, backfill SQL, data fix scripts)
- **ADV-04**: Execution history and trend analysis (task success rate, average time, failure patterns)
- **ADV-05**: Slack/Teams notifications for PR approval requests and execution status

### Multi-Team & Enterprise

v2+ will support larger organizations with multiple squads/teams.

- **ENT-01**: Cross-squad task orchestration (batching, shared governance, approval workflows)
- **ENT-02**: Admin console for policy enforcement (code standards, model ownership, change approval rules)
- **ENT-03**: Enterprise JIRA/GitHub/GitLab integration (OAuth, enterprise instances, SSO)
- **ENT-04**: Usage analytics dashboard (execution trends, team velocity, cost tracking)
- **ENT-05**: Centralized configuration management (shared SQL style guides, dbt macros, policies)

### Advanced Task Handling

v2 will support more complex task types and workflows.

- **ADVANCED-01**: Support for cross-layer refactors (Bronze → Silver → Gold) with phased planning
- **ADVANCED-02**: Backfill task automation (data fixes, historical corrections with rollback)
- **ADVANCED-03**: Datamart/report creation workflows (beyond just dbt model changes)
- **ADVANCED-04**: Schema change detection and migration generation (new columns, deprecations)
- **ADVANCED-05**: Dependency conflict resolution (when changes conflict with other pending PRs)

### AI/ML Enhancements

Future versions may leverage more sophisticated AI capabilities.

- **AI-01**: Natural language task parsing (convert plain English to structured JIRA fields)
- **AI-02**: Automated testing strategy generation (suggest test cases based on model changes)
- **AI-03**: Code review automation (AI identifies potential issues before human review)
- **AI-04**: SQL optimization suggestions (performance improvements, indexing strategies)

## Known Limitations (v1)

These are not failures; they're design choices for v1:

1. **Manual Configuration** — JIRA, Git, dbt, and SQL linting must be configured outside Autopilot
2. **No Package Manager Distribution** — Install via Git clone; no pip/npm/brew packages
3. **No Web UI** — CLI-only; no dashboard for monitoring execution
4. **No Background Scheduler** — All execution is user-triggered, no daemon mode
5. **No Enterprise SSO** — JIRA and Git credentials passed via CLI or environment
6. **No Slack/Email Notifications** — PR approval requests are manual; no async notifications
7. **Limited AI Capabilities** — Task classification is heuristic-based, not ML-based
8. **No Rollback Automation** — Rollback strategy documented in PR; human executes
9. **No Cross-Team Governance** — v1 assumes small, autonomous squads on single repo
10. **No Cost Optimization** — No token usage tracking, no cost optimization for large tasks

## Technical Debt & Refactoring

Improvements to code quality and architecture, deferred for future phases:

- Consolidate state management (currently .autopilot/state.json; consider unifying with Git metadata)
- Add comprehensive logging framework (currently debug via stderr)
- Refactor classification logic into pluggable rules engine (vs hardcoded heuristics)
- Build abstract dbt client (vs direct filesystem/subprocess calls)
- Create AI agent abstraction (vs direct Claude API calls)

## Community & Ecosystem

Longer-term ambitions for Autopilot:

1. **Open Source Community** — Share learnings, accept community contributions
2. **dbt Ecosystem Integration** — Partner with dbt Cloud, dbt Labs for native integration
3. **Analytics Platform Ecosystem** — Support Sigma, Looker, Tableau workflows
4. **Training & Education** — Templates, playbooks, best practices guides for Analytics Engineering
5. **Industry Benchmarking** — Anonymous usage data to help teams optimize their AE workflows

---

*Backlog last updated: 2026-01-29*
*Subject to change as v1 launches and user feedback arrives*
