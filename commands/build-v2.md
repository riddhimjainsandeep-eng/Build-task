---
description: Run a task with build-task v2 (risk-scored, quality-first), or change its settings
argument-hint: [task-name | settings [project]]
---

## `/build-v2 settings` — change what runs produce

If `$1` is `settings`, do not run a task. Settings change what the user gets and
where it goes — **never how carefully work is done**. Phase 0, the findings,
`RISK.md`, Phase 2's real check, Phase 3's review and every commit are not
settings and are never offered.

1. Scope: `$2` = `project` → this project only; otherwise global (every project).
2. Show the current values:
   `bash "${CLAUDE_PLUGIN_ROOT}/skills/build-task-v2/scripts/settings.sh"`
   (if the variable is empty, the plugin is at `~/.claude/skills/build-task`).
3. Ask with **one** AskUserQuestion call, current values marked "(current)":
   - **"What should each run produce?"** — `multiSelect: true`: Zip archive ·
     Technical handoff · Cost section · Report printed in chat. Ticked = on.
   - **"When should finished work be pushed?"** — Automatically, after the check
     and review both pass · Ask me first · Never (I push myself). Say plainly that
     nothing is ever pushed unless both passed.
   - **"Maps and CLAUDE.md after each run?"** — Apply both · Maps apply,
     CLAUDE.md proposed · Propose both (I review). Say that proposals are
     written into the report — never skipped.
   - **"Log each run to the shared history?"** — Yes · No.
4. Save with one call, e.g.
   `settings.sh set global zip=false handoff=false costSection=true printReport=true push=ask maps=apply rulesFile=propose history=true`
   (`project` instead of `global` for project scope).
5. Print the saved settings in plain English, one line each.

## `/build-v2 <task>` — run a task

Execute the task `$1` using the **build-task-v2** skill (`/build` runs the same;
`/build-v1` runs the original procedure).

**First, check this project has been set up.** No `agent-runs/` folder and no
`.build-task-setup` marker → stop and run the **build-setup** skill instead. Say
so plainly rather than improvising a folder structure.

**Open your very first reply with these lines, before anything else:**

- **Browser:** Phase 0 always checks the running app itself in Claude in Chrome
  (when there is one). The prompt file's `browser:` declaration covers the rest —
  `yes` means a browser check late in Phase 2 and the report ends by suggesting
  `/compact`; `no` means no browser after Phase 0. Not declared → decide and say
  which.
- **Model:** Phase 1 must run on Opus. If this session is not on Opus, say so and
  suggest `/model opus` before starting.
- **Session:** if this session already holds other work, recommend starting the
  run in a fresh session — every turn re-sends the whole conversation, and in
  measured runs that was 100k–220k tokens per turn. A recommendation only; do
  not wait.

1. Read `build-task.config.json` for the folders; defaults `agent-runs/active`
   and `agent-runs/done`.
2. Find the prompt file: `agent-runs/active/*$1*/00-PROMPT.md`, then
   `agent-runs/upcoming/*$1*.md`. From `upcoming/`: create
   `agent-runs/active/YYYY-MM-DD_$1/` and move it in as `00-PROMPT.md`. Nothing
   matches → list `upcoming/` and `active/` and stop.
3. Read the build-task-v2 skill and run all six phases in order. The prompt file
   is the goal; the skill is the procedure.
4. Stop and wait for the user only when Phase 0 returns `blocked` or
   `needs a decision`, when a better alternative should be proposed, after two
   failed check or review rounds, or when push is set to `ask`.
