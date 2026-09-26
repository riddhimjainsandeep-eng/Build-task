---
description: Execute a prompt file using the full six-phase build procedure
argument-hint: [task-name | --update]
---

**If `$1` is `--update`, do not run a task.** Publish or fetch changes to this
plugin instead. A git checkout of it publishes or pulls; a marketplace install
(no `.git`) fetches the latest version from GitHub:

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/update.sh" --check` (if the variable
   is empty, the plugin lives at `~/.claude/skills/build-task`). Tell the user in
   plain English what it found.
2. If it would publish local changes, read `git diff` in the plugin folder, write
   a one-line summary of what changed, and run
   `update.sh --message "<summary>"`. If it would pull or fetch, run
   `update.sh --message pull`. If it reports FAILED, stop and explain; change
   nothing by hand.
3. Report the version now live. A git checkout: each project picks it up in a
   new session. A marketplace install: tell the user to restart Claude Code.
   **Never touch a project's own local copy of the skill.**

Otherwise, execute the task `$1` using the **build-task** skill.

**First, check this project has been set up.** If there is no `agent-runs/`
folder and no `.build-task-setup` marker, stop and run the **build-setup** skill
instead — this project has never been initialised. Say so plainly rather than
improvising a folder structure.

**Open your very first reply with these two lines, before anything else:**

- **Browser:** read the prompt file's `browser:` declaration and state it — `yes`
  means a browser tool will be used late in Phase 2 and the report will tell the
  user to `/compact`; `no` means no browser tool is called at any point in the
  run. If the prompt file does not declare one, decide and say which.
- **Session:** if this session already holds an unrelated task, remind the user
  that `/clear` before starting is worth more than any other saving — most usage
  comes from turns above 150k context. A reminder only; do not wait for it.

1. Read `build-task.config.json` if present for the task folder locations;
   otherwise default to `agent-runs/active` and `agent-runs/done`.

2. Locate the prompt file, in this order:
   - `agent-runs/active/*$1*/00-PROMPT.md`
   - `agent-runs/upcoming/*$1*.md`

   If it is in `upcoming/`, create `agent-runs/active/YYYY-MM-DD_$1/` using
   today's date, move the prompt file in as `00-PROMPT.md`, and work there.
   If nothing matches `$1`, list what is in `upcoming/` and `active/` and stop.

3. Read the build-task skill and follow all six phases in order. Do not skip a
   phase and do not reorder them. The prompt file is the goal; the skill is the
   procedure.

4. Stop and wait for the user only when Phase 0 returns `blocked` or
   `needs a decision`, or when a better alternative should be proposed. A
   `feasible` verdict continues straight through.

5. Print `04-REPORT.md` in chat, then run Phase 5 in full — documents, the rules
   file and its inventory, move to `done/`, archive, **log the run to the shared
   history**, push, and delete `RESUME.md` last.
