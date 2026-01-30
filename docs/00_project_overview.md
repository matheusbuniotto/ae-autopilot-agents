No fluff, no over-engineering.

---

# Autopilot — Project Overview & References

## 1. Purpose

**Autopilot** is an automation system designed to reduce manual Analytics Engineering (AE) work in large dbt environments by safely executing repetitive, well-scoped tasks end-to-end.

It focuses on **doing the work**, not just suggesting it.

Target environment scale:

* ~2k Bronze tables
* ~1k Silver tables
* ~500 Gold tables

Autopilot integrates directly with:

* JIRA (task source of truth in most cases)
* Git (branches, commits, PRs)
* dbt (models, tests, docs, lineage)
* CI/CD (validation & safety)

---

## 2. Core Principles

### 2.1 Task-Driven, Not Plan-Driven

* JIRA tickets already define *intent*
* Planning is **adaptive**, not mandatory
* Simple tasks should not require complex plans

> Plan only when risk or ambiguity justifies it.
> Some times user will ask directly without a task-id, in this case, we need to use AskQuestionUser or similar tool to better understand needs / branchs and so on.

---

### 2.2 Automation With Guardrails

Autopilot must always provide:

* Full traceability
* Atomic commits and context saving
* Reversible changes
* Human approval before merge

No silent changes. No autonomous publishing.

---

### 2.3 PR Is the Primary Artifact

* Plans are optional
* Logs are internal
* **The Pull Request is the contract**

If it’s not visible in the PR, it didn’t happen. We will have a provided configured PR template to look at.

---

## 3. High-Level Workflow

**Canonical execution flow:**

```
JIRA Task (OR direct user input)
   ↓
Pull task context (or ask user for better context if needed)
   ↓
Sync release branch
   ↓
Create task branch (TSK-123)
   ↓
Understand complexity of work & Impact analysis & plan (if needed)
   ↓
Execute changes
   ↓
Validate (dbt + standards)
   ↓
Open PR (template-driven)
   ↓
Request approval of User
```

This flow is **default**, not optional.

---

## 4. Detailed Execution Flow

### 4.1 Pull JIRA Task (Always when recieve and ID-NUMBER, this will be a jira task)

Autopilot pulls:

* Task ID (e.g. `TSK-123`)
* Description
* Acceptance criteria
* Labels (bug, enhancement, refactor)
* Priority / SLA (if available)

This defines **scope and intent**.

---

### 4.2 Sync Release Branch

Before any work:

* Identify the configured release branch (e.g. `release/main`)
* Fetch latest changes
* Validate branch is up to date

If outdated → stop and sync.

---

### 4.3 Create Task Branch

Branch naming is **mandatory and deterministic**:

```bash
git switch -c TSK-123
```

Rules:

* One JIRA task → one branch (unless user say otherwise, but make sure to question why)
* No mixed concerns
* No reused branches

---

### 4.4 Impact Mapping & Planning (Conditional)

Autopilot evaluates task complexity:
**Check @01_task_classification.md for in depth detail on task classification.**

Planning is **lazy-loaded**, not upfront.

---

### 4.5 Execute the Task

Execution may include:

* dbt model creation or modification
--- always ask user if new tests or docs are needed) ---
* Tests (schema, data, freshness)
* Docs and metadata updates 
* Refactors (SQL quality, performance)

Autopilot must:

* Follow SQL style guide
* Follow the existent code base pattern
* Follow dbt best practices
* Make atomic commits where possible
* Save this context of what was done for easier references and context


---

### 4.6 Review & Validation

Before PR creation, Autopilot runs:

* `dbt build` (targeted selection)
* Tests relevant to the change
* Linting / formatting (if configured)
* Contract validation (if applicable)

Failures must be:

* Fixed automatically **or**
* Clearly reported and stopped

---

### 4.7 Open Pull Request

PRs are created using a **strict template**.

PR includes:

* Linked JIRA task
* Summary of changes
* Impacted models
* dbt results
* Confidence level
* Rollback notes (if relevant)

Example title:

```
Feat - TSK-123 – Adiciona novos campos de fatura na obt de pagamentos
```

---

### 4.8 Approval Before Merge

Autopilot **never merges automatically**.

It must:

* Assign reviewers 
* Request approval explicitly 
* Block merge until approval is granted

Publishing is a **human decision**.

* Never use git add . 
* Always prefer atomic, explicit commads 


---

## 5. What Autopilot Does *Not* Do

* No long-lived planning ceremonies
* No autonomous production deploys
* No speculative refactors without a task
* No cross-task batching

Autopilot optimizes **throughput + safety**, not autonomy at all costs.

---

## 6. References & Inspirations

Conceptual inspirations (adapted, not copied):

* *get-shit-done* — structured task execution mindset
* dbt best practices (models, tests, docs, lineage)
* Standard GitHub PR-based development flows
* Large-scale AE operational patterns
* All commits and PRs are in PT-BR, expect for things like text for Feat, Add, Fix, Bug

Autopilot intentionally avoids:

* Over-abstracted agent frameworks
* Multi-phase planning by default
* Tooling that conflicts with dbt conventions
* Over engineer
* Huge PRs 

---


