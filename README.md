# build-task

A six-phase procedure for changing a codebase, packaged as a Claude Code plugin
so it works the same way in every project — plus a first-run setup that builds a
project's documentation scaffolding, and a shared history that lets one project
learn from what happened in another.

**Upgrading from 1.x? Read [UPGRADE-TO-2.md](UPGRADE-TO-2.md).** It has a box to paste into Claude Code.

**New here? Read [SETUP.md](SETUP.md).** It is written to be followed without
knowing any code.

**Want to see how it works rather than read about it?**
**[The flowcharts](docs/flowcharts/)** — six diagrams, each with the reasoning
behind it and the alternative that was rejected.

## Why it exists

It was built for someone who is not a developer and cannot verify code by reading it
(each project's `user.md` says who the work is for). So the procedure has to produce evidence that stands on its own: what the agent
believed *before* it started, what an external system actually answered, and what
an independent reader — who never saw the reasoning — thought of the result.

That is the whole design. Everything else follows from it.

## What you get

| Command | What it does |
|---|---|
| `/build-task:build-setup` | First run in a project. Creates the folders and documents, checks `CLAUDE.md` against the real code, writes the maps, asks you what it could not work out. Once per project. |
| `/build-task:build <task>` | Runs a task through all six phases. The task can be a prompt-file name or a sentence. |
| `/build-task:build settings` | Choose what runs produce (zip, cost section, report in chat, push, CLAUDE.md, history). Add `project` for this project only. |
| `/build-task:build --update` | Publishes your edits to this plugin (version bump, commit, push), or pulls the latest on another machine. Never touches a project's own copy of the skill. |
| `/build-task:build-general <task>` | The same six phases for anything that isn't a code change — research, decisions, plans, documents, images. No setup needed. Runs by itself when you give such a task in chat. |
| `/build-task:build-history` | Looks at what has happened across all your projects. |

## 2.0.0 — what changed

- **One build-task.** v1, v2 and fast are gone; `/build-v1`, `/build-v2` and `/build-fast` are
  removed — use `/build`. A run started under v2 can still be resumed.
- **Project index.** Each project gets `docs/index/cards/` (committed — teammates share it
  through git) and a machine-built `docs/index/index.json` (git-ignored, rebuilt by itself
  whenever the code changes). Runs search it instead of reading whole maps and files. It
  starts in *watch mode* and is only trusted after 5 right answers in a row.
- **One command, `bt`**, does every mechanical step (task folder, checks, resume file,
  backups, close-out). Needs **Python 3** (standard library only).
- **The plan may change** — minor changes are announced, severe ones are asked about in
  plain words, and Phase 2/3 are never skipped without the user's yes. **AFK mode** backs
  up before severe restorable steps and lists them for undo.
- **Reports are written in chat** (and saved); the technical handoff file is gone.
- **Setup asks who the work is for** instead of copying one person's profile.

## The six phases

| Phase | What it is for |
|---|---|
| **0 — Explore** | An `opus` subagent finds the code through the project index, reads what it needs and writes down what it believes, with a citation for every claim, before anything is edited. Also reads the shared history in case another project hit this already. |
| **1 — Implement** | Write the code. Opens by naming which findings it is building against. Commits, does not push. |
| **2 — Prove** | Run something **external** — a build, a real query, a screenshot — and record the actual output. Not a summary of it. |
| **3 — Review** | A fresh subagent (`sonnet`, or `opus` when the risk is high) sees only the goal, the diff and the relevant cards, never the reasoning. Does it achieve the goal? Did it add anything nobody asked for? |
| **4 — Report** | In chat, in plain language for the person in `user.md`; saved to the task folder. |
| **5 — Close out** | Update the touched index cards, pay the rules-file budget, archive, log to the shared history, push — all mechanical steps by `bt`. |

Nothing reaches anything live until Phases 2, 3 and 4 have passed.

## Two ideas worth knowing

**Documents drift; code does not lie.** Every claim in a project's `CLAUDE.md` is
marked verified, false, or unverified in `docs/CLAUDE-RULES.md`. A phase may not
rely on an unverified claim without checking that one claim first. Setup does the
structural pass; every task after it verifies what it actually touches. Full
verification, paid for progressively rather than all at once.

**The shared history cannot be rewritten.** The table has an insert policy and a
select policy and no update or delete policy, so a past entry physically cannot be
edited — not by you, not by a session that thinks it knows better. An instruction
is a hope; a missing policy is a wall.

## Layout

```
.claude-plugin/     plugin.json, marketplace.json
skills/
  build-task/         the six-phase procedure — SKILL.md, phases/, reference.md
  build-task-general/ the same phases for work that isn't a code change
  build-setup/        first-run project setup, and the file templates it copies
scripts/              bt (the single command), btlib/, the shared bash scripts, tests/
commands/             /build, /build-general and /build-history
hooks/              context-size warning, and saving your setup answers
db/schema.sql       the shared history table — run once, in Supabase
```

`SKILL.md` is charged on every turn of every phase, so it holds rules only.
Reasoning, evidence and worked examples live in `reference.md`, which is read once
and only when needed.
