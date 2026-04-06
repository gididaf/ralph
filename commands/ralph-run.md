---
description: "Launch Ralph autonomous loop in tmux"
argument-hint: "[--max-iterations N] [--model MODEL]"
---

# Ralph Run

Launch the Ralph autonomous loop in a tmux session. Each iteration spawns a fresh `claude -p` process with clean context.

## Pre-flight Checks

Run ALL of these checks. Stop and report the FIRST failure.

**1. Check tmux is installed:**
```bash
which tmux
```
If not found: tell the user "tmux is required. Install with: `brew install tmux` (macOS) or `apt install tmux` (Linux)". Stop here.

**2. Check PROMPT.md exists:**
```bash
test -f PROMPT.md && echo "OK" || echo "MISSING"
```
If MISSING: tell the user "No PROMPT.md found. Run `/ralph-init` first to set up." Stop here.

**3. Check fix_plan.md exists:**
```bash
test -f fix_plan.md && echo "OK" || echo "MISSING"
```
If MISSING: tell the user "No fix_plan.md found. Run `/ralph-init` first to set up." Stop here.

**4. Check unchecked tasks exist:**
```bash
grep -c '^\s*- \[ \]' fix_plan.md || echo "0"
```
If 0: tell the user "No unchecked tasks in fix_plan.md. All tasks appear complete. Nothing to do." Stop here.

**5. Check no existing ralph loop is running:**
```bash
if [ -f .ralph/lock ]; then
  EXISTING_PID=$(cat .ralph/lock)
  if kill -0 "$EXISTING_PID" 2>/dev/null; then
    echo "RUNNING:$EXISTING_PID"
  else
    echo "STALE"
    rm -f .ralph/lock
  fi
else
  echo "NO_LOCK"
fi
```
If RUNNING: tell the user "Ralph is already running (PID N). Use `/ralph-status` to check progress or `/ralph-stop` to stop it." Stop here.

**6. Check this is a git repo:**
```bash
git rev-parse --is-inside-work-tree 2>/dev/null || echo "NOT_GIT"
```
If NOT_GIT: tell the user "This directory is not a git repository. Ralph requires git for progress tracking. Run `git init` first." Stop here.

## Launch

All checks passed. Now launch the loop.

**1. Create .ralph directory if needed:**
```bash
mkdir -p .ralph/logs
```

**2. Determine tmux session name:**
```bash
basename "$(pwd)"
```
Session name will be: `ralph-<basename>`

**3. Launch in tmux:**
```bash
tmux new-session -d -s "ralph-$(basename "$(pwd)")" "bash '$HOME/.claude/scripts/ralph-loop.sh' '$(pwd)' $ARGUMENTS; echo ''; echo '[ralph] Loop ended. Press Enter to close.'; read"
```

## Report to User

After successful launch, tell the user:

- Ralph loop started in tmux session `ralph-<name>`
- Number of unchecked tasks to process
- How to monitor:
  - Attach to tmux: `tmux attach -t ralph-<name>`
  - Check status: `/ralph-status`
  - Detach from tmux: press `Ctrl+B` then `D`
- How to stop:
  - Graceful: `/ralph-stop` (finishes current iteration)
  - Force: `tmux kill-session -t ralph-<name>`
- Reminder: You can edit PROMPT.md and fix_plan.md while the loop runs — changes are picked up on the next iteration
