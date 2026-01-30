Below is the **fully updated and consolidated document**, including:

1. **Failure modes & safe stops**
2. **Git rules (hard constraints)**
3. **GitHub / PR best practices**
4. **State file with commit tracking & “what was done”**
5. **Command reference snippets (safe defaults)**

This replaces the previous version entirely.

Save as:

```
docs/03_failures_git_state.md
```

---

# Autopilot — Failure Modes, Git & GitHub Practices, and State Management

## 1. Purpose

This document defines **operational guardrails** for Autopilot.

Its goals are:

* Prevent unsafe automation
* Keep Git history clean and reviewable
* Ensure work is resumable
* Preserve human trust

Autopilot is designed to **stop safely** rather than push forward blindly.

---

## 2. Failure Modes & Safe Stops

Stopping is **expected behavior**.

### 2.1 Hard Stops (Immediate Exit)

Autopilot **must stop immediately** when any of the following occurs:

* Release branch is outdated
* JIRA task cannot be fetched or parsed
* Task branch already exists and has uncommitted changes
* Task classification cannot be determined
* Silver model change escalates but no plan exists
* dbt execution fails outside expected scope
* Git conflicts detected
* Required manual confirmation is missing

**Behavior**

* Exit with non-zero status
* Print a clear, actionable message
* Persist state to disk

---

### 2.2 Soft Stops (Human Input Required)

Autopilot pauses and waits for input when:

* Task escalates (L1 → L2 or L2 → L3)
* Multi-phase execution reaches a checkpoint
* Backfill or destructive change is detected
* Business logic is ambiguous
* Rollback strategy is unclear

**Behavior**

* Print next required action
* Persist state
* Do not proceed automatically

---

### 2.3 Non-Failures (Normal Outcomes)

These are **not errors**:

* No plan generated (L0/L1)
* No dbt run required (docs/tests only)
* PR blocked waiting for review
* Manual override requested

---

## 3. Git Usage Rules (Non-Negotiable)

Autopilot enforces **boring Git** on purpose.

### 3.1 Branching Rules

* **One JIRA task → one branch**
* Branch name **must equal task ID**

```bash
git switch -c TSK-123
```

Forbidden:

* Reusing branches
* Multiple tasks per branch
* Long-lived task branches

---

### 3.2 Staging Rules (Very Important)

❌ **Never use:**

```bash
git add .
git add -A
```

✅ **Always stage explicitly:**

```bash
git add models/silver/orders.sql
git add models/silver/schema.yml
```

Reason:

* Prevents accidental changes
* Keeps commits reviewable
* Avoids leaking unrelated files

Autopilot will **block execution** if `git add .` is detected in history.

---

### 3.3 Commit Rules

* Commits must be **atomic**
* Prefer multiple small commits
* Commit messages must be descriptive

✅ Good:

```
Add freshness test to silver.orders
Refactor join logic in silver.orders
Update docs for gold.revenue
```

❌ Bad:

```
fix stuff
wip
changes
```

Autopilot never squashes automatically.

---

### 3.4 History Safety Rules

❌ Never allowed:

```bash
git push --force
git push --force-with-lease
git commit --amend
```

❌ No automatic rebases
❌ No history rewriting

If the release branch moves:

* Autopilot stops
* Human resolves rebase or merge manually

---

## 4. GitHub (PR) Best Practices

### 4.1 Pull Requests Are the Contract

The PR is:

* The **primary artifact**
* The **only place reviewers look**
* The **handoff boundary**

If it’s not in the PR, it didn’t happen.

---

### 4.2 PR Scope Rules

* One task per PR
* No mixed concerns
* No drive-by refactors

Autopilot will refuse PR creation if:

* Too many unrelated files are touched
* Changes exceed expected scope for the task level

---

### 4.3 Approval Rules

* Autopilot **never merges**
* At least one human approval is required
* CI must be green

---

## 5. Autopilot State File (Resumability & Memory)

Autopilot maintains **explicit state** to allow safe resumption.

### 5.1 Location

```
.autopilot/state.json
```

Properties:

* Git-ignored
* Machine-written
* Human-readable
* Append-only where possible

---

### 5.2 What the State File Stores

* Current task & branch
* Current stage (`pull`, `plan`, `execute-plan`, `review`, `pr`)
* Classification level
* Plan & phase progress
* Commit history (references only)
* High-level summary of work done
* Stop reason (if any)

---

### 5.3 Full State File Example

```json
{
  "task_id": "TSK-123",
  "branch": "TSK-123",
  "stage": "execute-plan",
  "classification": "L2",

  "plan": {
    "exists": true,
    "phases": ["phase_1", "phase_2"],
    "completed_phases": ["phase_1"]
  },

  "commits": [
    {
      "sha": "a1b2c3d",
      "message": "Add freshness test to silver.orders",
      "stage": "execute-plan",
      "timestamp": "2026-01-28T10:45:00Z"
    },
    {
      "sha": "d4e5f6g",
      "message": "Refactor join logic in silver.orders",
      "stage": "execute-plan",
      "timestamp": "2026-01-28T11:02:00Z"
    }
  ],

  "summary": {
    "what_was_done": [
      "Added freshness and not_null tests to silver.orders",
      "Refactored join logic to reduce row duplication"
    ]
  },

  "execution": {
    "last_command": "execute-plan --phase=1",
    "status": "stopped",
    "reason": "awaiting human confirmation for phase 2"
  },

  "timestamps": {
    "started_at": "2026-01-28T10:32:00Z",
    "last_updated": "2026-01-28T11:05:00Z"
  }
}
```

---

### 5.4 Commit Tracking Rules

* Only commit **references** are stored (SHA + message)
* No diffs, no file lists, no stats
* Commits are appended after successful `git commit`
* Used for:

  * Resume logic
  * PR summary
  * Handoff context

Git remains the source of truth.

---

## 6. Resuming Work Safely

When state exists:

```bash
autopilot launch TSK-123
```

Autopilot will:

* Load state
* Detect completed stages
* Skip completed phases
* Never repeat commits
* Never overwrite local changes

---

## 7. Cleanup Rules

* State file is removed **only after PR merge**
* Manual deletion is allowed
* No background cleanup

---

## 8. Design Guarantees

Autopilot guarantees:

* No irreversible Git actions
* No silent failures
* No hidden context
* No loss of work history
* No surprise behavior

---

## 9. Mental Model (For Humans)

* **Git is boring on purpose**
* **Stops are safe**
* **State is memory, not truth**
* **PRs are the contract**
* **Humans stay in control**

---

## 10. What This Unlocks

With this document in place, you now have:

* Safe automation boundaries
* Predictable Git behavior
* Resumable execution
* Reviewer confidence

At this point, the system is **ready to be implemented**.

---
