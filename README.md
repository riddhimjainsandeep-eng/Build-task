# build-task

A six-phase procedure for changing a codebase, packaged as a Claude Code plugin
so it works the same way in every project — plus a first-run setup that builds a
project's documentation scaffolding, and a shared history that lets one project
learn from what happened in another.

**New here? Read [SETUP.md](SETUP.md).** It is written to be followed without
knowing any code.

**Want to see how it works rather than read about it?**
**[The flowcharts](docs/flowcharts/)** — six diagrams, each with the reasoning
behind it and the alternative that was rejected.

## Why it exists

The person using this is not a developer and cannot verify code by reading it.
So the procedure has to produce evidence that stands on its own: what the agent
believed *before* it started, what an external system actually answered, and what
an independent reader — who never saw the reasoning — thought of the result.

That is the whole design. Everything else follows from it.

## What you get

| Command | What it does |
|---|---|
| `/build-task:build-setup` | First run in a project. Creates the folders and documents, checks `CLAUDE.md` against the real code, writes the maps, asks you what it could not work out. Once per project. |
| `/build-task:build <task>` | Runs a task through all six phases, using v2 (the default). Same as `build-v2`. |
| `/build-task:build-v1 <task>` | Runs a task with the original v1 procedure. |
| `/build-task:build-history` | Looks at what has happened across all your projects. |
| `/build-task:build --update` | Publishes your edits to this plugin (version bump, commit, push), or pulls the latest on another machine. Never touches a project's own copy of the skill. |
| `/build-task:build-v2 <task>` | **v2, the default** — same six phases, risk-scored and quality-first. See `skills/build-task-v2/reference.md` for every difference. |
| `/build-task:build-v2 settings` | Choose what v2 runs produce (zip, handoff, cost section, push, maps, history). Add `project` for this project only. |
| `/build-task:build-fast <task>` | Experimental — v1's procedure with waste removed (Phase 2 and 3 together, one-call close-out). |

## The six phases

| Phase | What it is for |
|---|---|
| **0 — Explore** | An `opus` subagent reads the code and writes down what it believes, with a citation for every claim, before anything is edited. Also reads the shared history in case another project hit this already. |
| **1 — Implement** | Write the code. Opens by naming which findings it is building against. Commits, does not push. |
| **2 — Prove** | Run something **external** — a build, a real query, a screenshot — and record the actual output. Not a summary of it. |
| **3 — Review** | A fresh `sonnet` subagent sees only the goal and the diff, never the reasoning. Does it achieve the goal? Did it add anything nobody asked for? |
| **4 — Report** | One document in plain English for the user, one dense one for the next session. The system decides whether the task was small enough to merge them, and says so. |
| **5 — Close out** | Update the maps, pay the rules-file budget, archive, log to the shared history, push. |

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
  build-task/       the six-phase procedure — SKILL.md, reference.md, scripts/
  build-setup/      first-run project setup, and the file templates it copies
commands/           the /build-task:build and /build-task:build-history entry points
hooks/              context-size warning, and saving your setup answers
db/schema.sql       the shared history table — run once, in Supabase
```

`SKILL.md` is charged on every turn of every phase, so it holds rules only.
Reasoning, evidence and worked examples live in `reference.md`, which is read once
and only when needed.
