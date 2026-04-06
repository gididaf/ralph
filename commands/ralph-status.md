---
description: "Check status of Ralph autonomous loop"
---

# Ralph Status

Check the current status of the Ralph autonomous loop for this project.

## Gather Information

Run ALL of these commands and collect the results:

**1. Read state file:**
```bash
cat .ralph/state.json 2>/dev/null || echo "NO_STATE"
```
If NO_STATE: tell the user "No Ralph loop has been run in this project. Use `/ralph-init` then `/ralph-run`." Stop here.

**2. Check if tmux session is active:**
```bash
tmux has-session -t "ralph-$(basename "$(pwd)")" 2>/dev/null && echo "ACTIVE" || echo "INACTIVE"
```

**3. Count tasks:**
```bash
echo "Done: $(grep -c '^\s*- \[x\]' fix_plan.md 2>/dev/null || echo 0)"
echo "Remaining: $(grep -c '^\s*- \[ \]' fix_plan.md 2>/dev/null || echo 0)"
```

**4. Last log excerpt:**
```bash
LATEST_LOG=$(ls -t .ralph/logs/iteration-*.log 2>/dev/null | head -1)
if [ -n "$LATEST_LOG" ]; then
  echo "=== Last 20 lines of $LATEST_LOG ==="
  tail -20 "$LATEST_LOG"
else
  echo "No logs yet"
fi
```

**5. Recent git activity:**
```bash
git log --oneline -5 2>/dev/null || echo "No git history"
```

## Report

Present a formatted status report using the collected information:

- **Status**: from state.json (running / stopped / completed_promise / completed_all_tasks / completed_max_iterations / circuit_breaker)
- **Iteration**: current iteration number
- **Tasks**: N completed / M total
- **Stall count**: N / 3 (circuit breaker threshold)
- **tmux session**: ACTIVE or INACTIVE
  - If ACTIVE: "Attach with: `tmux attach -t ralph-<name>`"
  - If INACTIVE but status is "running": "tmux session ended unexpectedly. The loop may have crashed. Check the latest log."
- **Started**: timestamp from state.json
- **Last activity**: last_iteration_at from state.json
- **Recent commits**: last 5 commits
- **Last log excerpt**: the tail of the latest iteration log

If the status is `circuit_breaker`, explain: "The loop stopped because no progress was detected for 3 consecutive iterations. Check the logs to understand why, then either fix the issue and `/ralph-run` again, or use `/ralph-signs` to add guardrails to PROMPT.md."
