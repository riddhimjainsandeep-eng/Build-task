---
description: Execute a prompt file using the faster variant of the six-phase build procedure (experimental)
argument-hint: [task-name]
---

Execute the task `$1` using the **build-task-fast** skill (the experimental faster variant; `/build` still runs the regular one).

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

3. Read the build-task-fast skill and follow all six phases in order. Do not skip a
   phase and do not reorder them. The prompt file is the goal; the skill is the
   procedure.

4. Stop and wait for the user only when Phase 0 returns `blocked` or
   `needs a decision`, or when a better alternative should be proposed. A
   `feasible` verdict continues straight through.

5. Phase 3 runs in the background alongside Phase 2, per the skill. Then read
   its `phases/report-and-close.md`, print the user part of `04-REPORT.md` in
   chat, and run Phase 5 in full — documents, the rules file and its inventory,
   then `scripts/close-out.sh` for move, archive, the shared history, push, and
   deleting `RESUME.md` last.
