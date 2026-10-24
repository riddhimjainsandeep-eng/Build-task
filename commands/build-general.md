---
description: Run any non-code task (research, analysis, decisions, plans, documents) through the six-phase procedure
argument-hint: [task-name | the task in your own words]
---

Execute the task with the **build-task-general** skill
(`${CLAUDE_PLUGIN_ROOT}/skills/build-task-general/SKILL.md`; if the variable is
empty, the plugin is at `~/.claude/skills/build-task`).

**Open your first reply with:** whether this session is on Opus (Phase 1 must
be — suggest `/model opus` if not), and, if the session already holds other
work, a recommendation to start the run in a fresh one. Do not wait.

1. No `agent-runs/` folder → create it as the skill's *Setup* says. No
   `build-setup` is needed.
2. Find the prompt: `agent-runs/active/*$1*/00-PROMPT.md`, then
   `agent-runs/upcoming/*$1*.md` (move it into
   `agent-runs/active/YYYY-MM-DD_$1/00-PROMPT.md`). No match and `$ARGUMENTS`
   reads as a task → write `00-PROMPT.md` from it, per *No prompt file*. No
   arguments → use the task the user gave in this conversation, the same way.
3. Run all six phases in order. The user's words are the goal; the skill is the
   procedure.
4. Stop and wait only when Phase 0 returns `blocked` or `needs a decision`, when
   a better approach should be proposed, or after two failed check or review
   rounds.
