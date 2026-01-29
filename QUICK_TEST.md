# Quick Testing Checklist (5 Minutes)

Use this for quick validation that Autopilot is working in your repo.

## Setup (1 minute)

```bash
# Clone/copy Autopilot to your analytics repo
cd ~/your-analytics-repo
cp -r ~/path/to/ae-autopilot/.cursor .cursor
cp -r ~/path/to/ae-autopilot/shared shared
mkdir -p .autopilot

# Verify structure
ls -la .cursor/agents/
```

## Test 1: Command Discovery (1 minute)

**In Cursor:**
1. Type `/` to open command palette
2. Type `autopilot` → See all 6 commands
3. Click on `/autopilot:pull` → Should see description

**Expected:** All 6 commands appear:
- /autopilot:pull
- /autopilot:plan
- /autopilot:execute-plan
- /autopilot:review
- /autopilot:pr
- /autopilot:launch

**If not appearing:** Restart Cursor completely

---

## Test 2: Git Setup Check (1 minute)

```bash
# Make sure you're ready
git branch -v                    # See all branches
git branch -r | grep release     # Verify release branch exists
git status                       # Should be clean
```

---

## Test 3: Run autopilot:pull (2 minutes)

```bash
# In Cursor, type:
/autopilot:pull TSK-TEST

# Verify it worked:
git branch -v                    # Should see TSK-TEST branch
cat .autopilot/state.json        # Should be valid JSON
git log --oneline -5             # Should show recent commits
```

**Expected output:**
```
✅ Pull complete
   Task: TSK-TEST
   Branch: TSK-TEST (created from origin/release/main)
   State: .autopilot/state.json

Next step: /autopilot:plan
```

**Success if:**
- ✅ Branch `TSK-TEST` created
- ✅ State file exists: `.autopilot/state.json`
- ✅ Branch is based on `origin/release/main`
- ✅ No Git errors

---

## Test 4: Verify State File

```bash
# Check state structure
cat .autopilot/state.json | jq .

# Should show:
{
  "task_id": "TSK-TEST",
  "branch": "TSK-TEST",
  "stage": "pull",
  "timestamps": { ... }
}
```

**Success if:**
- ✅ Valid JSON (no errors from jq)
- ✅ Has task_id, branch, stage, timestamps
- ✅ File is Git-ignored (not in `git status`)

---

## Test 5: Hard Stop Validation

```bash
# Make release branch outdated to test hard stop
git switch release/main
git reset --hard HEAD~1

# Try to run autopilot:pull again
/autopilot:pull TSK-TEST2

# Should see error:
# ❌ HARD STOP: Release branch is out of sync

# Fix it:
git pull origin release/main
/autopilot:pull TSK-TEST2   # Should work now
```

**Success if:**
- ✅ Hard stop detected outdated branch
- ✅ Clear error message shown
- ✅ Works after fixing branch

---

## ✅ All Tests Pass If:

- [ ] All 6 commands discoverable in Cursor
- [ ] `/autopilot:pull TSK-TEST` creates branch
- [ ] `.autopilot/state.json` created with correct structure
- [ ] State file is Git-ignored
- [ ] Hard stop blocks outdated release branch
- [ ] Clear error messages and next steps provided

---

## 🚀 Next Steps

If all tests pass:
1. Try a real JIRA task: `/autopilot:pull TSK-123`
2. Check state: `cat .autopilot/state.json`
3. See classification: `/autopilot:plan`
4. Run full workflow: `/autopilot:launch TSK-123`

If tests fail:
1. See TESTING_GUIDE.md for detailed troubleshooting
2. Check Cursor is fully restarted
3. Verify `.cursor/agents/` has all 6 `*.md` files
4. Verify YAML frontmatter syntax (spaces, quotes)

---

**Duration:** ~5 minutes for complete validation
**Status:** Ready to report results!
