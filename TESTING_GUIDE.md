# Testing Guide - How to Test Autopilot Commands

This guide explains how to test Autopilot commands in a real repository.

## Prerequisites for Testing

Before testing, you need:

1. **A dbt project** (your analytics repository)
   - Must have `dbt_project.yml`
   - Must have `models/` directory structure
   - dbt CLI configured and working: `dbt debug` returns success

2. **Git setup**
   - Repository initialized with Git
   - Origin remote configured: `git remote -v`
   - Release branch exists: `git branch -r | grep release/main`

3. **JIRA access** (for `/autopilot:pull`)
   - JIRA MCP configured OR
   - Manual JIRA task ID to test (e.g., TSK-123)

4. **Cursor or OpenCode**
   - Cursor with Claude Code extensions enabled
   - Or OpenCode with command support

## Test Setup Steps

### Step 1: Clone Autopilot Repository

```bash
cd ~/Workspace
git clone https://github.com/your-org/ae-autopilot.git
cd ae-autopilot

# Verify structure
ls -la .cursor/agents/
ls -la .opencode/command/
ls -la shared/
```

### Step 2: Copy to Your Analytics Repo (Two Options)

#### Option A: Copy Autopilot into Your Repo (Easiest for Testing)

```bash
cd ~/your-analytics-repo

# Copy Autopilot structure
cp -r ~/Workspace/ae-autopilot/.cursor .cursor
cp -r ~/Workspace/ae-autopilot/.opencode .opencode
cp -r ~/Workspace/ae-autopilot/shared shared
mkdir -p .autopilot
cp ~/Workspace/ae-autopilot/.gitignore .gitignore

# Verify
ls -la .cursor/agents/
git status
```

#### Option B: Use as Separate Module (Advanced)

```bash
cd ~/your-analytics-repo

# Add as Git submodule
git submodule add https://github.com/your-org/ae-autopilot.git .autopilot-module

# Reference in commands (adjust paths in skills as needed)
```

### Step 3: Verify Cursor Recognizes Commands

**In Cursor:**
1. Open your analytics repo folder in Cursor
2. Type `/` to open command palette
3. Type `autopilot`
4. You should see:
   ```
   /autopilot:pull
   /autopilot:plan
   /autopilot:execute-plan
   /autopilot:review
   /autopilot:pr
   /autopilot:launch
   ```

**If commands don't appear:**
1. Restart Cursor (full quit and reopen)
2. Check `.cursor/agents/` exists with `*.md` files
3. Verify YAML frontmatter syntax: `---` on separate lines
4. Try typing `/autopilot:p` (partial match)

## Testing Scenarios

### Test 1: Basic State Management (`autopilot:pull`)

**Goal:** Verify state file creation and Git branch creation

**Steps:**

```bash
# 1. Start in analytics repo root
cd ~/your-analytics-repo

# 2. Ensure on release branch
git switch release/main
git pull origin release/main

# 3. Run autopilot:pull command
/autopilot:pull TSK-123
# OR: autopilot pull TSK-123 (OpenCode)

# 4. Verify state file was created
cat .autopilot/state.json
# Should show:
# {
#   "task_id": "TSK-123",
#   "branch": "TSK-123",
#   "stage": "pull",
#   "timestamps": { ... }
# }

# 5. Verify Git branch created
git branch -v
# Should show: TSK-123 branch

# 6. Verify branch is from correct base
git log --oneline | head -5
git log --oneline origin/release/main | head -5
# Should match (same commits)
```

**Expected Output:**
```
✅ Pull complete
   Task: TSK-123
   Branch: TSK-123 (created from origin/release/main)
   State: .autopilot/state.json

Next step: /autopilot:plan
```

**Success Criteria:**
- ✅ `.autopilot/state.json` exists and is valid JSON
- ✅ Git branch `TSK-123` created
- ✅ Branch is based on `origin/release/main`
- ✅ No uncommitted changes

---

### Test 2: Hard Stop - Release Branch Out of Sync

**Goal:** Verify hard stop when release branch is outdated

**Steps:**

```bash
# 1. Make release branch outdated
git switch release/main
git reset --hard HEAD~1
# (This simulates release/main being behind origin)

# 2. Try to run autopilot:pull
/autopilot:pull TSK-124

# 3. Expect hard stop error
```

**Expected Output:**
```
❌ HARD STOP: Release branch is out of sync

Your local release/main is behind origin/release/main.

Actions:
1. git pull origin release/main
2. /autopilot:pull TSK-124
```

**Success Criteria:**
- ✅ Command exits immediately (hard stop)
- ✅ Clear error message shown
- ✅ State file saved for recovery
- ✅ No branch created

**Recovery:**
```bash
git pull origin release/main
/autopilot:pull TSK-124
# Should work now
```

---

### Test 3: Hard Stop - Dangerous Git Operation

**Goal:** Verify hard stop detection for `git add .`

**Steps:**

```bash
# 1. Create some file changes
echo "test" > untracked.txt
echo "changes" >> models/silver/test_model.sql

# 2. Try to run autopilot:pull with unsafe staging
git add .  # This should be detected and blocked

/autopilot:pull TSK-125

# 3. Expect hard stop
```

**Expected Output:**
```
❌ HARD STOP: Dangerous Git operation detected

The following forbidden operation was attempted: git add .

Allowed patterns:
✅ git add models/silver/orders.sql
✅ git add models/silver/schema.yml

Forbidden patterns:
❌ git add .
```

**Success Criteria:**
- ✅ Command detects `git add .` usage
- ✅ Exits with error before proceeding
- ✅ Suggests correct usage pattern

---

### Test 4: State Resumability

**Goal:** Verify that state persists and commands can resume

**Steps:**

```bash
# 1. Start a workflow
/autopilot:pull TSK-126

# 2. Verify state
cat .autopilot/state.json
# Shows: "stage": "pull"

# 3. Simulate IDE restart by closing Cursor
# (In real testing, just close and reopen)

# 4. Run same command again
/autopilot:pull TSK-126

# 5. Verify it detects existing state
# Output: "Branch TSK-126 already exists"
# It should recognize the work is done

# 6. Run next stage
/autopilot:plan

# 7. Verify state updated
cat .autopilot/state.json
# Shows: "stage": "plan"
```

**Expected Behavior:**
- ✅ State file persists across invocations
- ✅ Commands recognize completed work
- ✅ No duplicate branches created
- ✅ Smooth transition between stages

---

### Test 5: Classification Framework (Phase 2 Prep)

**Goal:** Verify classification heuristics are available

**Steps:**

```bash
# 1. Review classification prompts
cat shared/prompts/classification.md

# 2. Review classification schema
cat shared/schemas/classification-schema.json | jq .

# 3. Verify L0-L3 levels defined
grep -E "^### L[0-3]" shared/prompts/classification.md

# 4. Check Silver layer escalation rules
grep -A 10 "Silver Layer Risk Escalation" shared/prompts/classification.md
```

**Expected:**
- ✅ L0-L3 definitions present
- ✅ Silver layer escalation rules documented
- ✅ Classification schema valid JSON
- ✅ Decision tree available

---

### Test 6: Git Safety Rules

**Goal:** Verify git-safety.mdc rules are enforced

**Steps:**

```bash
# 1. Review git safety rules
cat .cursor/rules/git-safety.mdc

# 2. Check hard stops defined
grep -E "^### [0-9]" .cursor/rules/git-safety.mdc

# 3. Verify branch naming validation
grep "pattern:" .cursor/rules/git-safety.mdc
# Should show: ^[A-Z]+-[0-9]+$

# 4. Check forbidden operations
grep -E "git (add \.|push --force|commit --amend)" .cursor/rules/git-safety.mdc
```

**Expected:**
- ✅ 5+ hard stop conditions defined
- ✅ Branch naming pattern enforced
- ✅ Dangerous operations blocked
- ✅ Clear error messages for each

---

### Test 7: Multi-Repo Testing

**Goal:** Test Autopilot in multiple repos to verify portability

**Steps:**

```bash
# Test in Repo A (dbt project)
cd ~/repo-a-analytics
cp -r ~/Workspace/ae-autopilot/.cursor .cursor
/autopilot:pull TSK-200

# Test in Repo B (another dbt project)
cd ~/repo-b-analytics
cp -r ~/Workspace/ae-autopilot/.cursor .cursor
/autopilot:pull TSK-201

# Verify both have separate state
cat ~/repo-a-analytics/.autopilot/state.json
cat ~/repo-b-analytics/.autopilot/state.json
# Each has its own state, no conflicts
```

**Expected:**
- ✅ Commands work in multiple repos
- ✅ No shared state conflicts
- ✅ Each repo has isolated `.autopilot/` state
- ✅ Git-ignored files don't interfere

## Manual Testing Checklist

Run through these checks:

### State Management
- [ ] State file created after `/autopilot:pull`
- [ ] State file is valid JSON
- [ ] State has required fields: task_id, branch, stage, timestamps
- [ ] State file is Git-ignored (not in git status)
- [ ] State persists across IDE restarts

### Git Operations
- [ ] Branch created with correct name (TSK-XXX format)
- [ ] Branch created from origin/release/main
- [ ] No uncommitted changes after pull
- [ ] Release branch sync check works
- [ ] Conflict detection works

### Error Handling
- [ ] Hard stops provide clear messages
- [ ] State saved before exits
- [ ] Recovery paths documented
- [ ] Errors include actionable next steps

### Command Discovery
- [ ] All 6 commands discoverable in Cursor (`/autopilot:`)
- [ ] Descriptions match purpose
- [ ] Commands work in both Cursor and OpenCode
- [ ] Autocomplete shows all commands

### Cross-Platform
- [ ] Works with Cursor in macOS
- [ ] Works with Cursor in Linux
- [ ] Works with Cursor in Windows (if applicable)
- [ ] Works with OpenCode (if available)

## Automated Testing (Advanced)

### Test Script for CI/CD

```bash
#!/bin/bash
# test-autopilot.sh

set -e

echo "Testing Autopilot Phase 1..."

# 1. Verify structure
echo "✓ Checking directory structure..."
test -d .cursor/agents || exit 1
test -d .opencode/command || exit 1
test -d shared/schemas || exit 1
test -d shared/prompts || exit 1

# 2. Verify YAML frontmatter
echo "✓ Checking YAML frontmatter..."
for file in .cursor/agents/*.md; do
  grep -q "^---$" "$file" || exit 1
  grep -q "^description:" "$file" || exit 1
  grep -q "^model:" "$file" || exit 1
  grep -q "^tools:" "$file" || exit 1
done

# 3. Validate JSON schemas
echo "✓ Validating JSON schemas..."
for file in shared/schemas/*.json; do
  jq empty "$file" || exit 1
done

# 4. Check required files
echo "✓ Checking required documentation..."
test -f README.md || exit 1
test -f HOW_TO_USE.md || exit 1
test -f COMMAND_STRUCTURE.md || exit 1

# 5. Test git safety rules
echo "✓ Checking git safety rules..."
grep -q "git add \." .cursor/rules/git-safety.mdc || exit 1
grep -q "git push --force" .cursor/rules/git-safety.mdc || exit 1

echo "✅ All tests passed!"
```

**Run it:**
```bash
bash test-autopilot.sh
```

## Testing in CI/CD Pipeline

Add to your `.github/workflows/test.yml`:

```yaml
name: Autopilot Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Test Autopilot structure
        run: |
          test -d .cursor/agents
          test -d .opencode/command
          test -d shared

      - name: Validate JSON schemas
        run: |
          for file in shared/schemas/*.json; do
            jq empty "$file" || exit 1
          done

      - name: Check YAML frontmatter
        run: |
          for file in .cursor/agents/*.md; do
            grep -q "^---$" "$file" || exit 1
          done
```

## Troubleshooting During Testing

### Problem: "Command not found" or not appearing in autocomplete

**Solutions:**
1. Restart Cursor completely (quit and reopen)
2. Verify `.cursor/agents/` directory exists
3. Check YAML frontmatter syntax: spaces after `description:`, quotes around value
4. Try typing full command path: `/autopilot:pull`

### Problem: State file not created

**Solutions:**
1. Check for permission errors: `ls -la .autopilot/`
2. Verify `.gitignore` allows writes: `git check-ignore .autopilot/` (should return nothing)
3. Check disk space: `df -h`
4. Try manual test: `echo '{}' > .autopilot/test.json` (should work)

### Problem: Git branch not created

**Solutions:**
1. Verify Git is working: `git status`
2. Check release branch exists: `git branch -r | grep release`
3. Verify you have local rights: `git branch -c release/main test-branch`
4. Check for merge conflicts: `git status` should be clean

### Problem: Commands work in Cursor but not OpenCode

**Solutions:**
1. Verify `.opencode/command/` files exist
2. Check OpenCode documentation for command discovery
3. May need to restart OpenCode
4. Check if OpenCode requires additional configuration

## Reporting Test Results

When reporting issues, include:

```markdown
## Test Report

**Environment:**
- IDE: Cursor / OpenCode
- OS: macOS / Linux / Windows
- Repository: [name]
- Branch: release/main

**Test Performed:**
- [ ] autopilot:pull
- [ ] State file creation
- [ ] Git branch creation
- [ ] Hard stop scenarios

**Results:**
[What happened]

**Expected:**
[What should happen]

**Error Message (if any):**
[Exact error]

**State File Content:**
[Output of cat .autopilot/state.json]

**Git Status:**
[Output of git status]
```

## Next Steps After Testing

Once Phase 1 testing is complete:

1. **Document any issues** found in GitHub issues
2. **Try Phase 2 work** - implement `/autopilot:plan`
3. **Test in production** - use with real JIRA tasks
4. **Gather feedback** - how can it be improved?
5. **Plan Phase 2** - classification engine

## Resources

- **README.md** - User guide
- **HOW_TO_USE.md** - Command reference
- **COMMAND_STRUCTURE.md** - Technical architecture
- **IMPLEMENTATION_SUMMARY.md** - Complete details
- **.cursor/agents/autopilot-pull.md** - Full implementation example

---

**Happy Testing! 🧪**

Report issues at: https://github.com/your-org/ae-autopilot/issues
