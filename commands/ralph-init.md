---
description: "Initialize Ralph autonomous loop for this project"
argument-hint: "[task description]"
---

# Ralph Init

You are setting up the Ralph autonomous loop for this project. Ralph is a bash loop that spawns fresh `claude -p` processes per iteration. Each iteration gets a clean context window, reads the plan files, picks ONE task, completes it, commits, and exits.

Your job is to create three files: `PROMPT.md`, `fix_plan.md`, and `AGENT.md`. But you MUST NOT rush to create them. This is a deep interactive planning session. You will go through multiple phases of exploration, questioning, and refinement BEFORE writing any files.

---

## Phase 1: Deep Project Exploration

Thoroughly explore the project to understand it. Use Glob, Grep, and Read extensively.

1. Read project config files: README.md, CLAUDE.md, package.json, Cargo.toml, pyproject.toml, go.mod, Makefile, docker-compose.yml — whatever exists
2. Use Glob to map the project structure (key directories, source layout, test layout)
3. Identify: language, framework, build system, test framework, linter, CI/CD
4. Read key source files to understand architecture, patterns, and conventions
5. Check existing tests to understand testing patterns and coverage
6. Look at recent git history to understand current development activity

Take notes on everything you learn. You will need this context for the planning phase.

---

## Phase 2: Understand the Task

**First, determine if $ARGUMENTS is a file path or a text prompt:**

1. Check if $ARGUMENTS matches an existing file (e.g., `PLAN.md`, `spec.md`, `task.md`):
   ```bash
   test -f "$ARGUMENTS_FILE" && echo "FILE_EXISTS" || echo "NOT_A_FILE"
   ```
   (where $ARGUMENTS_FILE is the first word of $ARGUMENTS, resolved relative to the project root)

2. **If it's a file**: Read the file contents. This is the user's plan/spec. Present a brief summary of what you understood from the file, then proceed to the follow-up questions below. The file provides context but does NOT replace the interactive planning process.

3. **If it's text**: The user wants Ralph to work on: $ARGUMENTS

4. **If $ARGUMENTS is empty or vague**: use AskUserQuestion to ask:
   - What should Ralph work on? (feature, refactor, bug fix, migration, etc.)
   - Is there a specific issue, PR, spec, or design doc?
   - Any constraints or requirements?

**Whether the input was a file, text, or empty — always use AskUserQuestion to dig deeper.** A plan file gives you a head start, but there are always gaps, ambiguities, and implicit assumptions to surface. Ask follow-up questions about:
- **Scope**: What's in scope and what's explicitly OUT of scope?
- **Dependencies**: Are there external dependencies, APIs, or services involved?
- **Testing expectations**: What level of testing is expected? (unit, integration, e2e)
- **Existing code**: Should this build on existing patterns, or is a new approach acceptable?
- **Breaking changes**: Are breaking changes acceptable? What about backwards compatibility?
- **Priority**: If this is too large for one Ralph run, what's the highest-priority subset?

Ask questions in batches of 2-4 using AskUserQuestion. Continue asking follow-ups until you have a clear, complete picture. Do NOT move to the next phase until you fully understand what needs to be built.

---

## Phase 3: Draft the Plan

Based on your exploration and the user's answers, draft a preliminary task breakdown. Think about:

1. **Phases**: Group related work into logical phases (e.g., "Setup", "Core Implementation", "Testing", "Polish")
2. **Task atomicity**: Each task must be completable in ONE `claude -p` iteration. If a task feels too large, split it.
3. **Task ordering**: Dependencies must come first. Never put "write tests for X" before "implement X".
4. **Verification**: Every task needs clear success criteria (test passes, file exists, endpoint responds, etc.)
5. **Self-contained descriptions**: Each task description must be detailed enough for someone with NO prior context to execute. Remember: each iteration has fresh context.

---

## Phase 4: Identify Assumptions & Verify

CRITICAL PHASE. Before finalizing anything, identify ALL assumptions you made during planning.

For each assumption, use AskUserQuestion to verify with the user. Common assumptions to check:

- **Architecture assumptions**: "I'm assuming we should put the new module in src/services/ following the existing pattern. Is that correct?"
- **Technology choices**: "I'm planning to use X library for Y. Do you have a preference?"
- **Scope assumptions**: "I'm including/excluding Z in the plan. Is that aligned with what you want?"
- **Testing assumptions**: "I'm planning unit tests for each component. Do you also want integration tests?"
- **Order assumptions**: "I'm doing X before Y because of dependency Z. Does that make sense?"
- **Naming assumptions**: "I'm using the naming convention XYZ based on existing code. Any preferences?"
- **Edge cases**: "Should the implementation handle [specific edge case], or is that out of scope?"

Ask these in batches using AskUserQuestion. If any answer changes your plan, update accordingly and check for cascading impacts.

---

## Phase 5: Present & Refine the Plan

Present the COMPLETE task breakdown to the user in your response. Show:
- All phases and tasks (with `- [ ]` checkboxes)
- Verification criteria for each task
- Total task count
- Estimated complexity per phase

Then use AskUserQuestion to ask:
- "Does this plan look right? Any tasks to add, remove, or reorder?"
- "Are the task descriptions detailed enough, or should I expand any?"
- "Are there any risks or edge cases I'm missing?"

Iterate on the plan based on feedback. Keep presenting and refining until the user is satisfied. Only proceed when the user explicitly approves.

---

## Phase 6: Create the Files

NOW create the files. Not before.

### fix_plan.md

Create `fix_plan.md` in the project root with the approved task checklist.

**Format:**
```markdown
# Fix Plan

## Phase 1: [Phase Name]

- [ ] Task 1: [Specific, actionable description]
  - Verify: [How to confirm this is done]
- [ ] Task 2: [Specific, actionable description]
  - Verify: [How to confirm this is done]

## Phase 2: [Phase Name]

- [ ] Task 3: ...
```

### PROMPT.md

Create `PROMPT.md` in the project root. Fill in the Project Context section with everything you learned about the project. Include project-specific signs based on patterns you observed.

```markdown
# Ralph Loop Instructions

## Project Context

[Describe: project name, purpose, tech stack, key directories, important files, architectural patterns, conventions.
Be thorough — this is the ONLY context each iteration gets about the project.]

## Your Role

You are an autonomous development agent running in a loop. Each iteration you receive FRESH CONTEXT — you have no memory of previous iterations. Your work persists only through files on disk and git history.

## Instructions

1. Read `fix_plan.md` to see all tasks and their status
2. Find the FIRST unchecked task (`- [ ]`)
3. Read `AGENT.md` for build/test/lint commands
4. Complete that task thoroughly:
   - Read relevant existing code before making changes
   - Write production-quality code (no placeholders, no stubs)
   - Follow existing code patterns and conventions
   - Run tests if applicable
   - Verify your change works
5. Mark the task as done: change `- [ ]` to `- [x]` in fix_plan.md
6. If you learned new build/test commands, update AGENT.md
7. Stage and commit ALL changes with a descriptive commit message
8. If ALL tasks in fix_plan.md are now `[x]`, output exactly:
   <promise>DONE</promise>

## Rules

- Complete ONE task per iteration. Do not start the next task.
- Do NOT mark a task `[x]` unless it is genuinely complete and verified.
- Do NOT skip tasks — work on them in order.
- Do NOT write placeholder or stub implementations. Implement fully.
- Before implementing something, SEARCH the codebase for existing code. Do not duplicate.
- Run tests after making changes. Do not skip testing.
- Do not modify files unrelated to the current task.

## Self-Correction

- If stuck on a task: add a note under it in fix_plan.md explaining what you tried and what went wrong. Leave it unchecked. The next iteration will see your notes and try a different approach.
- If you discover a bug or issue not in the plan: add it as a new `- [ ]` task at the end of fix_plan.md.
- If you cannot find an unchecked task: all tasks may be done. Verify by reading fix_plan.md carefully. If all are `[x]`, output `<promise>DONE</promise>`.

## Signs

[Project-specific signs based on observed patterns. Add more with /ralph-signs.]

## Completion

When ALL tasks are marked `[x]` and you have verified the work, output exactly:
<promise>DONE</promise>

This signals the loop to stop. Do NOT output this unless every task is genuinely complete.
```

### AGENT.md

Create `AGENT.md` in the project root with build/test/lint commands you discovered:

```markdown
# Agent Knowledge

## Build
[command to build the project, or "N/A"]

## Test
[command to run tests, or "N/A"]

## Lint
[command to lint, or "N/A"]

## Notes
[Any project-specific notes that would help future iterations:
- important file locations
- gotchas
- required environment variables
- database setup
- etc.]
```

### .ralph/ Directory

1. Create the directory: `mkdir -p .ralph/logs`
2. Add to .gitignore (if not already there):
   - Check if `.gitignore` exists and if `.ralph/` is already in it
   - If not, append `.ralph/` to `.gitignore`

---

## Phase 7: Final Report

Tell the user:
- How many tasks were created in fix_plan.md (by phase)
- Summary of what Ralph will work on
- Any signs that were pre-populated in PROMPT.md
- Next steps:
  - **Review**: Read `fix_plan.md` and `PROMPT.md` — edit anything you want to adjust
  - **Start**: Run `/ralph-run` to launch the loop
  - **Cheaper**: Run `/ralph-run --model sonnet` for cheaper iterations
  - **Limited**: Run `/ralph-run --max-iterations 10` to cap iterations
  - **Monitor**: Use `/ralph-status` or `tmux attach -t ralph-<name>`
  - **Stop**: Use `/ralph-stop` for graceful shutdown
