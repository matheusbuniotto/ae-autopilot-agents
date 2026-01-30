Below is the **consolidated, clean version** of **Document 2**, merging:

* Task classification
* Decision tree
* Pseudocode
* Planning depth rules
* **Silver-layer complexity handling**
* Simplification principles

This is the **single source of truth** and can live as:

```
docs/01_task_classification.md
```

---

# Autopilot — Task Classification & Planning Levels

## 1. Purpose

Task classification exists to **right-size automation**.

Most Analytics Engineering tasks are small and well-defined.
Autopilot assumes tasks are **simple by default** and escalates **only when risk is detected**.

> Plan as much as needed — no more.

---

## 2. Inputs Used for Classification (Minimal & Objective)

Autopilot uses only signals that are:

* Cheap to compute
* Predictive at scale
* Non-subjective

### Required Inputs

* JIRA metadata (type, labels)
* Number of dbt models touched
* Layer(s) impacted (bronze / silver / gold)
* Downstream dependency count (dbt graph)
* Table size statistics
* SQL complexity heuristics
* dbt runtime results (if execution starts)

Nothing else is required.

---

## 3. Task Levels Overview

| Level | Name    | Typical Scope           | Planning          |
| ----- | ------- | ----------------------- | ----------------- |
| L0    | Trivial | Very low risk           | None              |
| L1    | Simple  | Small scoped change     | Inline            |
| L2    | Medium  | Multi-model or impact   | Single plan       |
| L3    | Complex | Cross-layer / migration | Milestone + plans |

---

## 4. Decision Tree (Source of Truth)

```
Start
 |
 |-- Does the task touch code?
 |        |
 |        └─ No → L0
 |
 |-- How many dbt models are touched?
 |        |
 |        ├─ 1–2 models
 |        |     |
 |        |     └─ Downstream impact?
 |        |           |
 |        |           ├─ No → L0
 |        |           └─ Yes → L1
 |        |
 |        └─ >2 models
 |              |
 |              └─ Single layer?
 |                     |
 |                     ├─ Yes → L2
 |                     └─ No → L3
 |
 |-- Runtime failures or expanded blast radius?
 |        |
 |        └─ Escalate one level
```

Classification can **only escalate automatically**, never downgrade.

---

## 5. Silver Layer: Explicit Risk Rules

### Why Silver Is Special

Silver models:

* Contain **business logic**
* Are **larger and more complex**
* Have **high downstream impact**
* Are frequent sources of metric errors

Autopilot treats **Silver changes as higher-risk by default**.

---

### Silver-Specific Risk Signals

When Silver is touched, Autopilot evaluates:

* Table size (row count / storage rank)
* Number of downstream references
* SQL file length (LOC)
* Join count

These signals are additive.

---

### Silver Heuristics

| Signal          | Threshold | Effect     |
| --------------- | --------- | ---------- |
| Layer = silver  | —         | Minimum L1 |
| Table size      | Top 20%   | +1 level   |
| Downstream refs | >5        | +1 level   |
| SQL length      | >300 LOC  | +1 level   |
| Join count      | >5        | +1 level   |

**Caps**

* Silver hotfix → max L1
* Docs-only → stays L0

---

## 6. Simplified Classification Table

| Condition                    | Result   |
| ---------------------------- | -------- |
| No code changes              | L0       |
| ≤2 models, no downstream     | L0       |
| ≤2 models, downstream exists | L1       |
| >2 models, single layer      | L2       |
| Cross-layer changes          | L3       |
| Silver touched               | ≥L1      |
| Silver + high risk signals   | Escalate |
| Unexpected runtime failures  | Escalate |

---

## 7. Classification Pseudocode

```python
def classify_task(jira, code_changes, dbt_graph, stats, runtime=None):
    models = code_changes.models
    layers = code_changes.layers()
    downstream = dbt_graph.downstream_count(models)

    # Base classification
    if len(models) == 0:
        level = "L0"
    elif len(models) <= 2 and downstream == 0:
        level = "L0"
    elif len(models) <= 2:
        level = "L1"
    elif len(layers) == 1:
        level = "L2"
    else:
        level = "L3"

    # Silver adjustments
    if "silver" in layers:
        level = max(level, "L1")

        for model in models:
            if model.layer == "silver":
                if stats.size_rank(model) >= 0.8:
                    level = escalate(level)
                if stats.downstream_refs(model) > 5:
                    level = escalate(level)
                if stats.sql_loc(model) > 300:
                    level = escalate(level)
                if stats.join_count(model) > 5:
                    level = escalate(level)

    # Hotfix rule
    if "hotfix" in jira.labels and level in ["L2", "L3"]:
        level = "L1"

    # Runtime escalation
    if runtime and runtime.unexpected_failures:
        level = escalate(level)

    return cap(level)


def escalate(level):
    order = ["L0", "L1", "L2", "L3"]
    return order[min(order.index(level) + 1, 3)]


def cap(level):
    return min(level, "L3")
```

---

## 8. Planning Depth Contract (Non-Negotiable)

| Level | Planning Required | Artifact            |
| ----- | ----------------- | ------------------- |
| L0    | None              | PR only             |
| L1    | Inline            | PR description      |
| L2    | Single plan       | `plan.yml`          |
| L3    | Milestone + plans | Multiple plan files |

If a task is L0 or L1 and requires heavy planning → **classification is wrong**.

---

## 9. What Autopilot Explicitly Does *Not* Do

To remain usable at scale, Autopilot does **not** require:

* Manual scoring
* Long upfront specs
* NLP-heavy JIRA interpretation
* Multi-plan phases for simple tasks
* Deep SQL parsing
* Persistent planning artifacts for L0/L1

---

## 10. Guarantees

Autopilot guarantees:

* Simple tasks stay simple
* Silver risk is respected
* Complexity is detected, not assumed
* Planning effort scales with impact
* Humans can always override

---

## 11. Mental Model (One Line)

> **Autopilot assumes the task is trivial until the data proves otherwise — especially in Silver.**

---

## 12. Next Document

**Document 3: Autopilot CLI & Commands**

Defines:

* CLI surface
* Behavior per task level
* Artifacts produced
* Human intervention points

If you want, next we can move straight into that or draft the **PR template**, which is the other trust-critical piece.
