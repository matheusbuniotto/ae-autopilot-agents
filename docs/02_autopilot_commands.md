Got it — this is a **cleaner, more Unix-like design**.
We keep **explicit, composable commands**, and `launch` becomes a **thin orchestrator**, not magic.

Below is the **consolidated single document**, rewritten to reflect:

* Canonical commands: `pull`, `plan`, `execute-plan`, `review`, `pr`
* **Classification happens automatically inside `plan`**
* `execute-plan` supports **phases**
* `launch` = wrapper, nothing more

This should live as:

```
docs/02_autopilot_commands.md
```

---

# Autopilot — Commands & Golden Path

## 1. Philosophy

Autopilot follows a **composable CLI design**:

* Each command does **one clear thing**
* Commands can be run independently
* `launch` simply **wraps the full flow**
* No hidden behavior

This keeps the system:

* Debuggable
* Trustworthy
* Friendly to senior AEs

---

## 2. Canonical Workflow

The **explicit workflow** is:

```
pull → plan → execute-plan → review → pr
```

The **default workflow** is:

```
autopilot launch TSK-123
```

Both paths are first-class.

---

## 3. Command Overview

| Command        | Responsibility                          |
| -------------- | --------------------------------------- |
| `pull`         | Pull JIRA task & prepare Git branch     |
| `plan`         | Classify task + generate plan if needed |
| `execute-plan` | Execute work (supports phases)          |
| `review`       | Run validations & quality checks        |
| `pr`           | Open Pull Request                       |
| `launch`       | Wraps all steps above                   |

---

## 4. `autopilot pull`

### Purpose

Initialize work from a JIRA task.

### Usage

```bash
autopilot pull TSK-123
```

### Behavior

* Fetch JIRA task metadata
* Validate task exists
* Fetch and sync release branch
* Create task branch:

```bash
git switch -c TSK-123
```

### Artifacts

```
.autopilot/task.json
```

---

## 5. `autopilot plan`

### Purpose

Classify the task and decide planning depth.

> **Classification always happens here.**

### Usage

```bash
autopilot plan
```

### Behavior

* Inspect git diff (if any)
* Analyze dbt graph
* Apply Silver-specific rules
* Assign task level: `L0–L3`

### Planning Outcome

| Level | Result                           |
| ----- | -------------------------------- |
| L0    | No plan generated                |
| L1    | Inline plan (stored in metadata) |
| L2    | `plan.yml` generated             |
| L3    | Milestone + multiple plans       |

### Artifacts

```
.autopilot/classification.json
plan.yml            # only for L2/L3
```

If no plan is needed, `plan.yml` **must not exist**.

---

## 6. `autopilot execute-plan`

### Purpose

Execute the work defined by the plan (or inline steps).

### Usage

```bash
autopilot execute-plan
```

### Phase Support (L3 / Complex Tasks)

For multi-phase execution:

```bash
autopilot execute-plan --phase=1
autopilot execute-plan --phase=2
```

or:

```bash
autopilot execute-plan --all
```

### Behavior by Level

* **L0**

  * Apply changes
  * No structured execution
* **L1**

  * Execute inline steps
  * Scoped dbt build
* **L2**

  * Execute `plan.yml` sequentially
* **L3**

  * Execute phase-by-phase
  * Manual confirmation between phases

Execution always:

* Stops on ambiguity
* Logs all actions
* Never expands scope silently

---

## 7. `autopilot review`

### Purpose

Validate correctness and enforce standards **before PR**.

### Usage

```bash
autopilot review
```

### Checks Performed

* dbt build/test (scoped by impact)
* SQL style guide
* Required tests present
* Docs updated if logic changed
* Contracts respected (if applicable)

### Rules

* Review failures **block PR**
* No auto-fixing beyond safe cases
* Output is human-readable

---

## 8. `autopilot pr`

### Purpose

Create the Pull Request using gh cli or github mcp.

### Usage

```bash
autopilot pr
```

### Behavior

* Generate PR title:

```
Fix - TSK-123 – <summary>
```

* Populate PR template
* Attach:
  * JIRA link
  * Classification level
  * Impacted models
  * dbt results
* Request approval to before making the PR public for the team

DANGER: Autopilot never merges, we stop at PR.

---

## 9. `autopilot launch` (Wrapper Command)

### Purpose

Run the **entire canonical workflow** safely.

### Usage

```bash
autopilot launch TSK-123
```

### What It Does (Exactly)

Internally, `launch` runs:

```bash
autopilot pull TSK-123
autopilot plan
autopilot execute-plan
autopilot review
autopilot pr
```

Nothing more. Nothing less.

### Optional Flags

```bash
--dry-run
--stop-after=plan
--no-pr
```

---

## 10. Guarantees

Running `launch` guarantees:

* One task → one branch → one PR
* Planning only when needed
* Silver risk is respected
* Validation before PR
* Human approval before PR push or drastic changes.

---

## 11. Mental Model (For the Team)

* **Use `launch` by default**
* **Use individual commands when debugging or customizing**
* **If something feels heavy, classification is probably wrong**

---

## 12. What Autopilot Explicitly Does *Not* Do

* No auto-merge
* No background schedulers
* No silent fixes
* No speculative refactors
* No forced planning for simple tasks -- just a simple plan like a one liner.

---
