---
description: Run a task with build-task v2 (the default), change v2 settings, or update this plugin
argument-hint: [task-name | settings [project] | --update]
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

Otherwise — a task name, or `settings` — **`/build` runs v2.** Read
`${CLAUDE_PLUGIN_ROOT}/commands/build-v2.md` (if the variable is empty,
`~/.claude/skills/build-task/commands/build-v2.md`) and follow it exactly, with
the same arguments. The original v1 procedure is `/build-v1`.
