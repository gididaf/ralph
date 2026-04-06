---
description: "Stop the Ralph autonomous loop gracefully"
---

# Ralph Stop

Gracefully stop the Ralph autonomous loop. The current iteration will finish before the loop exits.

## Check if Running

```bash
if [ -f .ralph/lock ]; then
  EXISTING_PID=$(cat .ralph/lock)
  if kill -0 "$EXISTING_PID" 2>/dev/null; then
    echo "RUNNING:$EXISTING_PID"
  else
    echo "NOT_RUNNING_STALE"
  fi
else
  echo "NOT_RUNNING"
fi
```

If NOT_RUNNING or NOT_RUNNING_STALE: tell the user "No Ralph loop is currently running in this project." Stop here. If stale, clean up: `rm -f .ralph/lock`

## Send Stop Signal

```bash
touch .ralph/stop
```

## Report

Tell the user:
- "Stop signal sent. Ralph will finish its current iteration and then exit."
- "The current `claude -p` invocation will complete its work before stopping."
- "Use `/ralph-status` to confirm it stopped."
- "To force-kill immediately (aborts current iteration): `tmux kill-session -t ralph-$(basename "$(pwd)")`"
