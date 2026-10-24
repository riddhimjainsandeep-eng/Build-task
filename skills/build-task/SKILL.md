---
name: build-task
description: Mandatory six-phase procedure for any change to a codebase — risk-scored, quality-first, and lean (a project index finds the code; one script does the mechanical work). Use whenever the user asks to execute a prompt file, run a task from agent-runs/, fix a bug, add a feature, or otherwise modify code — including a task typed straight into chat with no prompt file — even if they don't name this skill, and for /build. Tasks whose main output is not a code change use build-task-general.
---

# Build Task — six phases, lean

**Read `user.md` at the repo root once at the start and write everything user-facing
for the person it describes** — how much code they read, how reports should sound.

## The rule above every other rule

**Quality is never traded for cost.** A saving is allowed only when it removes waste —
repeated reading, paperwork, mechanical steps done by hand, files nobody reads. It never
removes a check. Phase 0's understanding, Phase 2's pre-committed check and Phase 3's
independent review always happen unless the user agrees otherwise (see *Changing the plan*).

**`bt`** below means `bash "${CLAUDE_PLUGIN_ROOT}/scripts/bt"` (empty variable →
`~/.claude/skills/build-task/scripts/bt`), run from the project root. It does every
mechanical step; never do those by hand. Phases 2–3 are in `phases/prove-and-review.md`,
Phases 4–5 in `phases/report-and-close.md`, the risk rubric in `phases/risk.md`; read each
when you reach it. Rationale is in `reference.md`.

**No `agent-runs/` folder and no `.build-task-setup` marker → run the `build-setup` skill
first, then come back.**

## Configuration

Read `build-task.config.json` (repo root) once. Defaults: `taskFolder: agent-runs/active`,
`doneFolder: agent-runs/done`, `rulesFile: CLAUDE.md`, `buildCommand`/`testCommand` null
(infer, then ask once), `liveFiles: []`. User settings (`bt settings`) decide what the user
gets and where it goes, never how carefully work is done. `liveFiles` run outside this
working tree, so an uncommitted edit to one is already live behaviour — edit each in one
coherent pass.

## The task folder

`<taskFolder>/YYYY-MM-DD_task-name/`: `00-PROMPT.md`, `01-FINDINGS.md`, `RISK.md`,
`CHECKLIST.md`, `02-CHECK.md` (+ `02-CHECK-output.log`), `03-REVIEW.md`, `04-REPORT.md`,
`plan-changes.jsonl`, `backups/` (if any), `RESUME.md` (deleted by Phase 5).

**Task typed in chat, no prompt file:** pipe the user's message, copied exactly — typos,
slang and every message in order — into `bt new-task <short-kebab-name>`. It creates the
folder, `00-PROMPT.md` with **Your words** filled and `RESUME.md`. Then fill **How I read
it** (Goal · Now · Done looks like · Not in this task · Assumed · Could also mean) and add
`browser: yes | no` under the title if clear. Your words are the goal; the reading is an
interpretation and loses where they disagree. A *Could also mean* that changes what gets
built scores Goal clarity 3. Show the folder path and the reading in your first reply,
then carry on.

**`browser: yes | no`** binds Phases 1–5: `no` → no browser tool and no browser script;
`yes` → browser work goes last in its phase. Phase 0 is exempt: it checks the running app
whenever the project has one.

## The project index

Cards in `docs/index/cards/*.md` describe each behaviour/system: what it does, the words
people use for it, its files, tables, connections, symptoms and saved checks. `bt index …`
answers questions from them and from a function list it rebuilds itself whenever the code
changes. **Always rewrite the question into the app's own words first** (use `bt index toc`).
The answer starts `mode: watch|trust · confident: yes|no`.

- **Watch mode** (a project's first runs): use the index *and* read the normal way; record
  whether the index pointed to the right place. After 5 right in a row it switches to trust.
- **Trust mode:** open only the functions the cards name. Read the normal way when
  `confident: no`, a card shows `CHANGED:` or `MISSING:`, or `Other code matching` names a
  file the task touches. A wrong card → `bt index record wrong` (back to watch).
- **No cards yet:** say so, give the rough one-time cost (about half to one normal run for a
  large project), write the cards as build-setup's *Index* step describes, then continue.

Maps in `docs/maps/` are reference: read a section when a card points there; never read
them whole, never edit them per run. **Never rely on a `[?]` claim** in `CLAUDE.md`, a card
or a map without checking it against the code; record new marks under *Ledger updates*.

## Changing the plan

You know the conversation and the code, so you may change *how* the work is done:

| Change | What you do |
|---|---|
| **Minor** — reorder, merge or split steps; skip a step that clearly does not apply; add checks; another way to write the code | Do it. One line in chat at that moment ("Changed: …, because …"), repeated in the report. |
| **Severe** — anything serious, not only data: deleting or overwriting work or data, touching a live database or service, changing what was asked, pushing live, sending anything out, spending money, anything hard to undo | **Stop and ask**, in plain everyday words: what you want to do, what could go wrong, whether and how it can be undone, and what you recommend. |
| **Skipping Phase 2 or Phase 3** | Never on your own. You may recommend it with reasons; the user decides. If skipped by agreement, the report says so plainly. |

Log every change: `bt plan-change <task-dir> minor|severe-asked|skip-agreed|afk-severe "<text>"`.

### When the user says they are away (AFK)

- **Severe and restorable:** `bt backup <task-dir> <paths>` (it verifies every copy and
  fails loudly if it can't — then do not go ahead); for data outside files, export it
  first and check the export is non-empty. Do the step, log it as `afk-severe`, and list it
  in the report under **Severe changes made while you were away** with the one-line way to
  restore it.
- **Severe and not restorable** (sending a message, paying, deleting in an outside service
  with no undo): do everything else; leave that step waiting with its plain-words question.
- **Pushing to a live app:** ask once when AFK starts whether pushing live is fine this
  time. Nobody said → hold the push.
- AFK ends when the user is back.

## Resuming an interrupted run

Keep `RESUME.md` current with `bt resume <task-dir> --phase P --done D --next N --half H`
at every phase boundary and after every commit (`--half` names a half-written file or says
"nothing"). If the task folder has phase files, do not start over: a phase whose file
exists is done — except `02-CHECK.md` and `03-REVIEW.md`, which count only if the commit
they name is `HEAD`; Phase 5 is done only when the folder is in `<doneFolder>/`. Check
`git status` and `git log -1` for an interrupted Phase 1, then continue from the first
incomplete phase. Folders started by older versions (with `05-HANDOFF.md`, without
`plan-changes.jsonl`) resume the same way.

## Use other skills

Skills installed on this machine carry expertise this procedure does not. Look at the
available-skills list at the start of a run and **load the ones that fit the task** —
never require one that is not installed (other people run this plugin with different
skills). Name each skill you load in the findings or the report.

| When | Look for a skill about |
|---|---|
| A project names skills in `build-task.config.json` (`"skills": ["…"]`) or `CLAUDE.md` | those — they come first |
| Phase 1 fixes a bug | systematic debugging (root cause before any fix) |
| A safeguard asks for a test first (D = 3) | test-driven development |
| The change is a screen, layout or animation | the project's frontend / design skill |
| The change touches a database, migration or query | that database's best practices |
| Phase 3 at blast radius or reversibility 3 | security review |
| Browser work | the Claude in Chrome skill |

A skill guides *how* you work. It never replaces a phase, and never overrides this
procedure's checks or the user's instructions. A subagent you dispatch (Phase 0, Phase 3,
a browser helper) gets the names of skills that fit its job, in its prompt.

## Models

Phase 0: **opus**, dispatched. Phase 1, 2, 4, 5: the session (run it on Opus; say so if
not). Phase 3: dispatched — **sonnet** at risk Low/Mid, **opus** at High. Hold effort at
one level; never lower it to save.

---

## Phase 0 — Explore and score the risk

**Dispatch a write-capable `general-purpose` subagent on `model: opus`.** Its prompt says
`01-FINDINGS.md`, `RISK.md` and `CHECKLIST.md` are the only files it may write, gives it
the `bt` path and the index mode, and asks it to return only the verdict and the risk line.

### Order of work

0. **Shared history:** `bt history --search <term>` (and `--repo <owner/name>`).
1. **Index:** `bt index toc`; rewrite the task into the app's words; `bt index ask
   "<rewrite>"` once per distinct sub-question. Open the functions the cards name. In
   watch mode also read the normal way (code-graph, LSP or grep: definitions and **every**
   reference to what will change) and end the findings with
   `Index check: right | wrong — <why>`.
2. **The code** — whatever the index left open; every caller of what will change.
3. **Library docs** when a fast-moving dependency's behaviour matters.
4. **See it running** whenever the project has an app that opens in a browser: start the
   dev server if needed, open a **new Claude in Chrome tab** (never the headless devtools
   browser), test every behaviour the prompt claims (confirmed / not reproduced / behaves
   differently), hunt for bugs on the touched screens and their callers, read the console.
   On a live site, only look — never save, delete, submit, pay, send or log in. Close the
   tab; stop a server you started. Chrome unreachable → say so and continue on the code.

**Stop** when you can say what this touches, where the cause or insertion point is, and
what check will prove it worked, **and** every risk dimension has evidence — a dimension
you cannot evidence scores 3. Try to disprove each conclusion. Label every claim `read`
(seen at the cited line) or `inferred` (Phase 1 confirms it first). Name your blind spots.

### 01-FINDINGS.md must contain

Every claim with `file.ext:line` and `read`/`inferred` · **What contradicted the prompt
file** (always; "nothing" if so) · **Ledger updates** · **What the shared history warned
about** · **Seen in the browser** (page and clicks cited; bugs outside the task listed,
never fixed) · **Every caller** when blast radius scores 2+ · **What I did not read, and
why** · **Cards used** (slugs) · `Index check` (watch mode) · `browser: yes|no` ·
**Verdict:** `feasible` / `blocked` / `needs a decision` · **The check** — the exact
command that will prove this worked, fixed now · **Scope level** · "I could not determine
X" wherever true. Far more than ten citations is a sign the task should be split.

**RISK.md:** scored with `phases/risk.md`, computed with `bt risk B R K T G D`.
**CHECKLIST.md:** Phase 1's steps as `- [ ]` boxes naming file/function and finding;
**Not in this task** (noticed, out of scope, browser bugs); last box: run the check.

### Handoff

In watch mode the main session runs `bt index record right|wrong` from the `Index check`
line. `feasible` → Phase 1. `blocked` / `needs a decision` → stop, report, wait. A better
alternative → old vs new, cost and risk of each, your recommendation; wait.

---

## Phase 1 — Implement

Open with one or two lines: which findings you implement against, the risk level, and the
safeguards `RISK.md` switched on; name any finding you deliberately do not act on, and why.

- Deliver what was asked at the scope intended. A better approach → say so in one sentence
  and continue as asked. Scope level defaults to `full` (the smallest solution that works).
- Work down `CHECKLIST.md` in order, ticking each box. A step added, dropped or changed →
  edit the checklist with the reason, declare it in the commit message and log it with
  `bt plan-change`.
- Re-read the lines an edit depends on before editing. Confirm every `inferred` finding you
  rely on. Safeguards from `RISK.md` are not optional. No stubs or placeholders. Re-check
  symbols after edits.
- Tests for calculation and logic — anything with a right answer that can drift silently.
- An assumption breaks → stop and report; never invent a new goal.
- Destructive change → follow *Changing the plan* (severe): back up first, plain-words
  explanation of what disappears, whether it comes back, and the undo command.

**Commit** locally when the code is written; declare any change of method in the message.
Do not push — Phase 5 does, only after both checks pass.

**Next: read `phases/prove-and-review.md`.**
