# Ralph

**An autonomous development loop for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).**

Ralph spawns fresh `claude -p` processes in a loop — each iteration gets a clean context window, reads the plan, picks ONE task, completes it, commits, and exits. Repeat until done.

You plan the work. Ralph does it. You go get coffee.

---

## How It Works

```
┌─────────────────────────────────────────────────┐
│                  /ralph-init                     │
│                                                  │
│  You describe the task (or hand it a PLAN.md)    │
│  Ralph asks deep questions to understand scope   │
│  Together you build a detailed fix_plan.md       │
└──────────────────────┬──────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│                  /ralph-run                      │
│                                                  │
│  Launches a tmux session running a bash loop     │
│  Each iteration:                                 │
│                                                  │
│    1. Spawns fresh  claude -p  (clean context)   │
│    2. Reads PROMPT.md + fix_plan.md              │
│    3. Picks first unchecked task                 │
│    4. Implements it fully                        │
│    5. Runs tests                                 │
│    6. Marks task done ✓                          │
│    7. Commits & exits                            │
│                                                  │
│  Repeats until all tasks are complete            │
└──────────────────────┬──────────────────────────┘
                       │
                       ▼
                   You have
                working code
                  with tests
                 and commits
```

## Why Fresh Context Each Iteration?

Most agent loops accumulate context until the window fills up and quality degrades. Ralph takes the opposite approach — **every iteration starts fresh**. No context bleed, no degradation, no confused state from 50 iterations ago.

Progress persists through **files on disk and git history**, not in-memory context. Each iteration reads the plan, sees what's done, picks the next task. Simple and reliable.

## Installation

```bash
git clone https://github.com/gididaf/ralph.git
cd ralph
bash install.sh
```

**Requirements:**
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- `tmux` — install with `brew install tmux` (macOS) or `apt install tmux` (Linux)
- `git` — Ralph commits after each completed task

## Quick Start

Open Claude Code in any project and run:

```
/ralph-init build user authentication with JWT, including signup, login, logout, and middleware
```

Ralph will:
1. **Explore** your project — structure, stack, patterns, conventions
2. **Ask questions** — scope, dependencies, testing expectations, edge cases
3. **Draft a plan** — phased task breakdown with verification criteria
4. **Verify assumptions** — check architecture, naming, ordering decisions with you
5. **Create the files** — `PROMPT.md`, `fix_plan.md`, `AGENT.md`

When the plan looks right:

```
/ralph-run
```

That's it. Ralph is now working in the background. Check on it anytime:

```
/ralph-status
```

## Commands

| Command | Description |
|---------|-------------|
| `/ralph-init [task or PLAN.md]` | Interactive planning session — builds the task plan |
| `/ralph-run [--model sonnet] [--max-iterations N]` | Launch the loop in a tmux session |
| `/ralph-status` | Check progress, tasks done, recent commits, logs |
| `/ralph-stop` | Graceful shutdown (finishes current iteration) |
| `/ralph-signs [problem]` | Add guardrails to PROMPT.md based on observed failures |

## Input: Text or Plan File

`/ralph-init` accepts either a text prompt or a plan file:

```bash
# Simple text prompt
/ralph-init migrate the database from MySQL to PostgreSQL

# Detailed plan file
/ralph-init PLAN.md
```

When given a file, Ralph reads it as your spec/plan, summarizes its understanding, then still asks deep follow-up questions to fill gaps. The file is a head start, not a shortcut — the interactive planning process stays fully intact.

## Safety Features

### Circuit Breaker
If Ralph makes no progress for 3 consecutive iterations (no new commits, no plan changes), the loop stops automatically. No runaway API bills.

### Stall Recovery
When stuck on a task, Ralph adds notes explaining what it tried and what failed. The next iteration sees those notes and tries a different approach.

### Signs (Guardrails)
Observed Ralph writing placeholder code? Skipping tests? Modifying files it shouldn't?

```
/ralph-signs Claude keeps writing stub implementations instead of real code
```

This analyzes recent logs and adds targeted guardrails to `PROMPT.md` that take effect on the next iteration.

### Lock File
Prevents accidentally running two Ralph loops on the same project.

### Max Iterations
Cap the run to control costs:

```
/ralph-run --max-iterations 20
```

## Using a Cheaper Model

Run Ralph with Sonnet for lower-cost iterations:

```
/ralph-run --model sonnet
```

Good for well-defined tasks where Opus-level reasoning isn't needed.

## Monitoring

**From Claude Code:**
```
/ralph-status
```

**From terminal:**
```bash
# Attach to the tmux session
tmux attach -t ralph-<project-name>

# Detach without stopping: Ctrl+B then D
```

**Live editing:** You can edit `PROMPT.md` and `fix_plan.md` while the loop runs — changes are picked up on the next iteration.

## Project Files

Ralph creates these files in your project root:

| File | Purpose |
|------|---------|
| `PROMPT.md` | Instructions read by Claude each iteration — project context, rules, signs |
| `fix_plan.md` | Task checklist — `[ ]` unchecked, `[x]` done |
| `AGENT.md` | Build/test/lint commands discovered during work |
| `.ralph/` | State, logs, lock file (gitignored) |

## Philosophy

Ralph is based on the [Ralph Wiggum coding technique](https://ghuntley.com/ralph/) by Geoffrey Huntley.

**Core principles:**
- **Iteration over perfection** — don't aim for perfect on the first try, let the loop refine
- **Fresh context over accumulated context** — clean slate each iteration prevents degradation
- **Files over memory** — progress persists on disk, not in a context window
- **Questions over assumptions** — the init phase asks relentlessly to build the right plan
- **Guardrails over hope** — when behavior drifts, add signs to correct it

## Uninstall

```bash
cd ralph
bash uninstall.sh
```

This removes the slash commands and loop script. Your project files (`PROMPT.md`, `fix_plan.md`, `.ralph/`) are left untouched.

## Credits

- Technique: [Geoffrey Huntley](https://ghuntley.com/ralph/)
- Implementation: Built with [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

## License

MIT
