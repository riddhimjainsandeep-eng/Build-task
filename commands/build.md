---
description: Run a task with build-task, change its settings, or update this plugin
argument-hint: [task-name or task in words | settings [project] | --update]
---

`<plugin>` below is `${CLAUDE_PLUGIN_ROOT}` (empty → `~/.claude/skills/build-task`);
`bt` is `bash "<plugin>/scripts/bt"`.

## `/build --update` — update this plugin

Publish or fetch changes to this plugin instead of running a task. A git checkout of it
publishes or pulls; a marketplace install (no `.git`) fetches the latest from GitHub:

1. Run `bash "<plugin>/scripts/update.sh" --check`. Tell the user in plain English what it
   found.
2. If it would publish local changes, read `git diff` in the plugin folder, write a one-line
   summary, and run `update.sh --message "<summary>"`. If it would pull or fetch, run
   `update.sh --message pull`. If it reports FAILED, stop and explain; change nothing by hand.
3. Report the version now live. A git checkout: each project picks it up in a new session.
   A marketplace install: tell the user to restart Claude Code.
   **Never touch a project's own local copy of the skill.**

## `/build settings [project]` — change what runs produce

Settings change what the user gets and where it goes — **never how carefully work is
done**. Phase 0, the findings, `RISK.md`, Phase 2's check, Phase 3's review and every commit
are not settings and are never offered.

1. Scope: `$2` = `project` → this project only; otherwise global.
2. Show the current values: `bt settings`.
3. Ask with **one** AskUserQuestion call, current values marked "(current)":
   - **"What should each run produce?"** — `multiSelect: true`: Zip archive · Cost section
     · Report printed in chat. Ticked = on.
   - **"When should finished work be pushed?"** — Automatically, after the check and review
     both pass · Ask me first · Never (I push myself). Nothing is ever pushed unless both passed.
   - **"CLAUDE.md after each run?"** — Apply · Propose (I review). Proposals go into the
     report — never skipped.
   - **"Log each run to the shared history?"** — Yes · No.
4. Save with one call, e.g. `bt settings set global zip=false costSection=true
   printReport=true push=ask rulesFile=propose history=true` (`project` for project scope).
5. Print the saved settings in plain English, one line each.

## `/build <task>` — run a task

**First, check this project has been set up.** No `agent-runs/` folder and no
`.build-task-setup` marker → run the **build-setup** skill instead, and say so plainly.

**Open your first reply with these lines:**
- **Browser:** Phase 0 checks the running app in Claude in Chrome when there is one; the
  prompt's `browser:` line covers the rest. Not declared → decide and say which.
- **Model:** Phase 1 should run on Opus. If this session is not, say so and suggest
  `/model opus`.
- **Session:** if this session already holds other work, recommend a fresh one — every turn
  re-sends the whole conversation. A recommendation only; do not wait.

1. Read `build-task.config.json` for the folders; defaults `agent-runs/active` and
   `agent-runs/done`.
2. Find the prompt file: `<active>/*$1*/00-PROMPT.md`, then `agent-runs/upcoming/*$1*.md`.
   From `upcoming/`: create `<active>/YYYY-MM-DD_$1/` and move it in as `00-PROMPT.md`.
   Nothing matches → if the arguments read as a task description (a sentence, not a name),
   treat `$ARGUMENTS` as a typed task (the skill's *Task typed in chat*). Otherwise list
   `upcoming/` and `active/` and stop.
3. Read the **build-task** skill (`<plugin>/skills/build-task/SKILL.md`) and run all six
   phases. The prompt file is the goal; the skill is the procedure.
4. Stop and wait only when Phase 0 returns `blocked` or `needs a decision`, a better
   alternative should be proposed, a severe change needs a yes, two check or review rounds
   failed, or push is set to `ask`.
