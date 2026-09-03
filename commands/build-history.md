---
description: Look at the shared build history across all your projects
argument-hint: [search term, project name, or "summary"]
---

Show the user what the shared build history holds. This is the notebook every
project writes one line to at the end of each run.

Use the helper at `${CLAUDE_PLUGIN_ROOT}/skills/build-task/scripts/history.sh`:

- no argument → `history.sh` (the 20 most recent runs, all projects)
- `summary` → `history.sh --summary` (counts per project, verdicts, total cost)
- something that looks like `owner/name` → `history.sh --repo "$1"`
- anything else → `history.sh --search "$1"`

If it reports that the history is not set up, point the user at the plugin's
`SETUP.md` and stop — do not try to work around it.

Then **answer in plain English**, not as a raw dump. Summarise what is actually
interesting: what he has been building, where time and money went, and above all
any lesson or landmine from another project that bears on what he is doing now.
If nothing in the history is relevant, say that in one line rather than padding.

This is read-only. Never write, edit or delete a history entry from here.
