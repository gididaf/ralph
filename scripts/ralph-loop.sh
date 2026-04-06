#!/bin/bash
set -euo pipefail

# =============================================================================
# ralph-loop.sh — Core Ralph loop: spawns fresh claude -p per iteration
# =============================================================================

# --- Argument parsing ---
PROJECT_DIR=""
MAX_ITERATIONS=0  # 0 = unlimited
MODEL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-iterations)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --model)
      MODEL="$2"
      shift 2
      ;;
    *)
      if [[ -z "$PROJECT_DIR" ]]; then
        PROJECT_DIR="$1"
      else
        echo "[ralph] ERROR: Unknown argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$PROJECT_DIR" ]]; then
  echo "[ralph] ERROR: Project directory required." >&2
  echo "Usage: ralph-loop.sh <project-dir> [--max-iterations N] [--model MODEL]" >&2
  exit 1
fi

# --- Validation ---
if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "[ralph] ERROR: Directory not found: $PROJECT_DIR" >&2
  exit 1
fi

if [[ ! -f "$PROJECT_DIR/PROMPT.md" ]]; then
  echo "[ralph] ERROR: PROMPT.md not found in $PROJECT_DIR. Run /ralph-init first." >&2
  exit 1
fi

if [[ ! -f "$PROJECT_DIR/fix_plan.md" ]]; then
  echo "[ralph] ERROR: fix_plan.md not found in $PROJECT_DIR. Run /ralph-init first." >&2
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "[ralph] ERROR: 'claude' command not found on PATH." >&2
  exit 1
fi

cd "$PROJECT_DIR"

# --- State directory ---
RALPH_DIR="$PROJECT_DIR/.ralph"
mkdir -p "$RALPH_DIR/logs"

# --- Lock file (prevent double-run) ---
LOCK_FILE="$RALPH_DIR/lock"
if [[ -f "$LOCK_FILE" ]]; then
  EXISTING_PID=$(cat "$LOCK_FILE")
  if kill -0 "$EXISTING_PID" 2>/dev/null; then
    echo "[ralph] ERROR: Ralph loop already running (PID $EXISTING_PID)" >&2
    exit 1
  else
    echo "[ralph] WARNING: Stale lock file (PID $EXISTING_PID no longer running). Cleaning up."
    rm -f "$LOCK_FILE"
  fi
fi
echo $$ > "$LOCK_FILE"

cleanup() {
  rm -f "$LOCK_FILE"
}
trap cleanup EXIT

# --- State management ---
ITERATION=0
STALL_COUNT=0
MAX_STALL=3
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
FINAL_STATUS="unknown"

write_state() {
  local status="$1"
  FINAL_STATUS="$status"
  cat > "$RALPH_DIR/state.json" <<STATEEOF
{
  "iteration": $ITERATION,
  "max_iterations": $MAX_ITERATIONS,
  "status": "$status",
  "started_at": "$STARTED_AT",
  "last_iteration_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "pid": $$,
  "stall_count": $STALL_COUNT,
  "project_dir": "$PROJECT_DIR"
}
STATEEOF
}

write_state "running"

echo "[ralph] ========================================"
echo "[ralph] Ralph Loop Started"
echo "[ralph] Project: $PROJECT_DIR"
echo "[ralph] Max iterations: $([ "$MAX_ITERATIONS" -gt 0 ] && echo "$MAX_ITERATIONS" || echo "unlimited")"
echo "[ralph] Model: $([ -n "$MODEL" ] && echo "$MODEL" || echo "default")"
echo "[ralph] PID: $$"
echo "[ralph] Started: $STARTED_AT"
echo "[ralph] ========================================"

# --- Main loop ---
while true; do
  # Check for stop signal
  if [[ -f "$RALPH_DIR/stop" ]]; then
    echo "[ralph] Stop signal detected. Shutting down gracefully."
    rm -f "$RALPH_DIR/stop"
    write_state "stopped"
    break
  fi

  # Check max iterations
  if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
    echo "[ralph] Max iterations ($MAX_ITERATIONS) reached."
    write_state "completed_max_iterations"
    break
  fi

  # Count remaining tasks
  REMAINING_TASKS=$(grep -c '^\s*- \[ \]' "$PROJECT_DIR/fix_plan.md" 2>/dev/null || echo "0")

  if [[ "$REMAINING_TASKS" -eq 0 ]]; then
    echo "[ralph] All tasks in fix_plan.md are complete!"
    write_state "completed_all_tasks"
    break
  fi

  ITERATION=$((ITERATION + 1))
  LOG_FILE="$RALPH_DIR/logs/iteration-${ITERATION}.log"

  echo ""
  echo "[ralph] === Iteration $ITERATION ===" | tee "$LOG_FILE"
  echo "[ralph] $(date)" | tee -a "$LOG_FILE"
  echo "[ralph] Remaining tasks: $REMAINING_TASKS" | tee -a "$LOG_FILE"

  # Snapshot git state before iteration (for circuit breaker)
  GIT_HASH_BEFORE=$(git rev-parse HEAD 2>/dev/null || echo "none")

  # Read prompt and plan fresh each iteration
  PROMPT_CONTENT=$(cat "$PROJECT_DIR/PROMPT.md")
  FIX_PLAN_CONTENT=$(cat "$PROJECT_DIR/fix_plan.md")

  # Also include AGENT.md if it exists
  AGENT_CONTENT=""
  if [[ -f "$PROJECT_DIR/AGENT.md" ]]; then
    AGENT_CONTENT="
---

## Agent Knowledge

$(cat "$PROJECT_DIR/AGENT.md")
"
  fi

  # Compose the full prompt
  FULL_PROMPT="${PROMPT_CONTENT}
${AGENT_CONTENT}
---

## Current Fix Plan

${FIX_PLAN_CONTENT}

---

## Iteration Info

This is iteration ${ITERATION}. There are ${REMAINING_TASKS} unchecked tasks remaining.

Pick the NEXT unchecked task (marked with \`- [ ]\`), complete it, then:
1. Mark it as done (\`- [x]\`) in fix_plan.md
2. If you learned new build/test commands, update AGENT.md
3. Commit ALL your changes with a descriptive message
4. If ALL tasks are now complete, output exactly: <promise>DONE</promise>
5. Exit cleanly — do not start the next task"

  # Build claude command
  CLAUDE_CMD=(claude -p --dangerously-skip-permissions)
  if [[ -n "$MODEL" ]]; then
    CLAUDE_CMD+=(--model "$MODEL")
  fi

  # Execute claude -p
  echo "[ralph] Launching claude -p..." | tee -a "$LOG_FILE"

  set +e
  OUTPUT=$(echo "$FULL_PROMPT" | "${CLAUDE_CMD[@]}" 2>&1)
  CLAUDE_EXIT=$?
  set -e

  echo "$OUTPUT" >> "$LOG_FILE"

  # Handle claude crash
  if [[ $CLAUDE_EXIT -ne 0 ]]; then
    echo "[ralph] WARNING: claude exited with code $CLAUDE_EXIT" | tee -a "$LOG_FILE"
    STALL_COUNT=$((STALL_COUNT + 1))
    write_state "running"

    if [[ $STALL_COUNT -ge $MAX_STALL ]]; then
      echo "[ralph] CIRCUIT BREAKER: $MAX_STALL consecutive failures. Stopping." | tee -a "$LOG_FILE"
      write_state "circuit_breaker"
      break
    fi

    echo "[ralph] Retrying after failure ($STALL_COUNT/$MAX_STALL)..." | tee -a "$LOG_FILE"
    sleep 5
    continue
  fi

  # Check for completion promise
  if echo "$OUTPUT" | grep -q '<promise>DONE</promise>'; then
    echo "[ralph] Completion promise detected! All tasks done." | tee -a "$LOG_FILE"
    write_state "completed_promise"
    break
  fi

  # Circuit breaker: check for progress
  GIT_HASH_AFTER=$(git rev-parse HEAD 2>/dev/null || echo "none")
  FIX_PLAN_CHANGED=$(git diff --name-only fix_plan.md 2>/dev/null | wc -l | tr -d ' ')

  if [[ "$GIT_HASH_BEFORE" == "$GIT_HASH_AFTER" ]] && [[ "$FIX_PLAN_CHANGED" -eq 0 ]]; then
    STALL_COUNT=$((STALL_COUNT + 1))
    echo "[ralph] WARNING: No progress detected (stall $STALL_COUNT/$MAX_STALL)" | tee -a "$LOG_FILE"

    if [[ $STALL_COUNT -ge $MAX_STALL ]]; then
      echo "[ralph] CIRCUIT BREAKER: No progress for $MAX_STALL iterations. Stopping." | tee -a "$LOG_FILE"
      write_state "circuit_breaker"
      break
    fi
  else
    STALL_COUNT=0
    echo "[ralph] Progress detected. Stall counter reset." | tee -a "$LOG_FILE"
  fi

  write_state "running"

  # Brief pause between iterations
  sleep 2
done

echo ""
echo "[ralph] ========================================"
echo "[ralph] Loop finished after $ITERATION iterations."
echo "[ralph] Final status: $FINAL_STATUS"

# Count completed tasks
DONE_TASKS=$(grep -c '^\s*- \[x\]' "$PROJECT_DIR/fix_plan.md" 2>/dev/null || true)
DONE_TASKS=${DONE_TASKS:-0}
PENDING_TASKS=$(grep -c '^\s*- \[ \]' "$PROJECT_DIR/fix_plan.md" 2>/dev/null || true)
PENDING_TASKS=${PENDING_TASKS:-0}
TOTAL_TASKS=$((DONE_TASKS + PENDING_TASKS))
echo "[ralph] Tasks completed: $DONE_TASKS / $TOTAL_TASKS"
echo "[ralph] Logs: $RALPH_DIR/logs/"
echo "[ralph] ========================================"
