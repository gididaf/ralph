---
description: "Add guardrails (signs) to PROMPT.md based on observed failures"
argument-hint: "[description of the problem]"
---

# Ralph Signs

Help the user add "signs" (guardrails) to PROMPT.md based on observed behavior in Ralph loop iterations.

Signs are targeted instructions that correct specific failure patterns. They live in the `## Signs` section of PROMPT.md and are read by Claude on every iteration.

## Step 1: Gather Context

**Read the current PROMPT.md:**
Read the file PROMPT.md, focusing on the existing `## Signs` section.

**Read recent iteration logs:**
```bash
for f in $(ls -t .ralph/logs/iteration-*.log 2>/dev/null | head -3); do
  echo "=== $f ==="
  tail -50 "$f"
  echo ""
done
```

**Read fix_plan.md for context:**
Read fix_plan.md to see which tasks are done and which are stuck.

## Step 2: Understand the Problem

The user described this problem: $ARGUMENTS

If $ARGUMENTS is empty, ask the user:
- What behavior did you observe that needs correcting?
- Examples: "Claude keeps writing placeholder code", "Claude skips tests", "Claude modifies files it shouldn't"

## Step 3: Generate Signs

Based on the problem description and log evidence, generate 1-3 targeted SIGN entries. Each sign should be:

- **Specific**: Address the exact failure pattern observed
- **Actionable**: Tell Claude exactly what to do (or not do)
- **Emphatic**: Use clear, direct language (Ralph tradition uses strong wording)

**Format:**
```
SIGN: [Clear, direct instruction addressing the specific failure]
```

**Classic examples:**
- `SIGN: DO NOT write placeholder or stub implementations. Every function must have a real, complete implementation.`
- `SIGN: Before implementing anything, SEARCH the codebase for existing implementations. Do not duplicate code that already exists.`
- `SIGN: Always run tests after making changes. If tests fail, fix them before marking the task as done.`
- `SIGN: Do NOT modify files outside the scope of the current task. Stay focused.`
- `SIGN: When a test fails, read the error message carefully and fix the root cause. Do not delete or skip failing tests.`

## Step 4: Add Signs to PROMPT.md

Find the `## Signs` section in PROMPT.md and append the new signs. If no `## Signs` section exists, add one before the `## Completion` section.

## Step 5: Report

Tell the user:
- What signs were added and why
- The signs will take effect on the NEXT iteration (PROMPT.md is read fresh each time)
- If the problem persists after a few iterations, run `/ralph-signs` again to add stronger guardrails
