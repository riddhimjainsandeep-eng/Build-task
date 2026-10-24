---
name: build-task-general
description: Six-phase procedure for any task that is NOT a change to a codebase — research, analysis, decisions, advice, planning, writing, or making files, images or data (a style profile, a gym plan, a study schedule, a purchase decision). Use whenever the user gives such a task, in a prompt file or typed straight into chat, even if they don't name this skill, and for /build-general. Not for a quick question answerable in a few lines — answer that directly. A task whose main output is a code change uses build-task-v2. Never skip a phase and never reorder them.
---

# Build Task — general (any task, not only code)

The same six phases as build-task-v2, for work whose output is an answer, a
decision, a document, an image or a plan instead of a code change. The procedure
channels the thinking: find out before deciding, fix the check before doing,
prove it from outside, let a fresh reader judge it against the user's own words.
All six phases always run. Every phase leaves a file in the task folder.

## The rule above every other rule

**Quality is never traded for cost.** A saving may only remove waste — repeated
context, duplicate files, mechanical tool calls, output nobody reads. It must
never reduce what the agent reads, checks or reasons about. Never lower effort to
save money.

Phases 4 and 5 are in `phases/report-and-close.md` beside this file — **read it
before Phase 4**, not earlier. The risk rubric is `phases/risk.md` — Phase 0
reads it. Scripts are shared with v2: `<v2>` below means `<plugin>/skills/build-task-v2/scripts`, where `<plugin>` is `${CLAUDE_PLUGIN_ROOT}` (empty → `~/.claude/skills/build-task`).

**`user.md` at the project root, if there is one, says who everything
user-facing is written for — read it once and follow it.** None → plain English,
no jargon, reasons not only conclusions.

## Which procedure

| Main output of the task | Procedure |
|---|---|
| A change to a codebase | build-task-v2 |
| Anything else — scripts written as tools along the way included | this one |
| A quick question, a few lines of answer | neither — answer directly |

## Setup

None needed. No `agent-runs/` folder → create `agent-runs/upcoming/`,
`agent-runs/active/` and `agent-runs/done/`, and an `agent-runs/README.md` holding
only `# Run log`. `build-task.config.json` is optional (same keys and defaults as
v2; `docsRoot`, `rulesFile`, `buildCommand`, `testCommand` do not apply).
Settings: `bash <v2>/settings.sh` — here `maps` means the
project's living notes (below) and `zip` does not apply: the folder in `done/` is
the record.

**Git.** Not a git repo → **back up every existing file before changing it**, to
`<task folder>/backups/` with the same relative path. A git repo → also commit
locally at the end of Phase 1 and Phase 5; push only per the `push` setting and
only after Phase 2 and Phase 3 both pass.

## Task folder

`<taskFolder>/YYYY-MM-DD_task-name/` (default `agent-runs/active/`):

```
00-PROMPT.md       the prompt — the user's file, or written from chat (below)
01-FINDINGS.md     Phase 0 — facts, each cited
RISK.md            Phase 0 — the risk score
CHECKLIST.md       Phase 0 — Phase 1's steps, ticked as done
02-CHECK.md        Phase 2  (+ 02-CHECK-output.log when a command ran)
03-REVIEW.md       Phase 3
04-REPORT.md       Phase 4
backups/           Phase 1 — originals of every changed file (no git)
RESUME.md          rewritten at every phase boundary, deleted by Phase 5
```

The work itself — documents, images, scripts, data — goes where it belongs in
the project, never inside the task folder, unless it is scratch.

## No prompt file — the task was typed in chat

Write `00-PROMPT.md` before Phase 0:

```
# <title>
browser: yes | no          (leave out if unclear — Phase 0 decides)

## Your words
<the user's message copied exactly — typos, slang and all. If the task came
over several messages, each one, in order. Attachments: name each file>

## How I read it
- **Goal:** what the user wants to end up with
- **Now:** what is wrong, missing or undecided today
- **Done looks like:** what the user will have, see or be able to do
- **Not in this task:** anything the words rule out
- **Assumed:** each thing the words do not state that this reading relies on
- **Could also mean:** each other reasonable reading, and why this one was picked
```

- **`Your words` is the goal; `How I read it` is an interpretation.** Where they
  disagree, the words win. Phase 0 tests the reading and lists any gap under
  *What contradicted the prompt*. A `Could also mean` that changes the result
  scores Goal clarity 3.
- In the first reply, show the folder path and `How I read it`, then carry on.

## `browser: yes | no`

Whether Phases 1–5 may drive a browser (Claude in Chrome — never the headless
devtools browser). Web search and page fetches are not browser use. `yes` →
browser work goes **last** in its phase and the report ends by suggesting
`/compact`. Phase 0 may always use it to look at something the task depends on.
**On any site: read only — never buy, submit, send, save or log in.**

## The verification rule — every phase

**Never rely on a note without checking it.** The project's living notes (a
profile, a plan, a README — whatever records facts and decisions the user relies
on) are hypotheses like v2's maps: on conflict, the source wins — the photo, the
data, the user's own words, a primary reference. Record the conflict under
**Notes updates** in `01-FINDINGS.md`; Phase 5 applies it. The user's stated
rules (budgets, "never X") are not hypotheses — they are constraints every
output must pass.

## Resuming an interrupted run

Same as v2 without git: read `RESUME.md` first; a phase whose file exists is
done; `CHECKLIST.md` ticks show how far Phase 1 got; compare `backups/` with the
live files to see what Phase 1 changed. Continue from the first incomplete phase.
`RESUME.md` always names any half-written file, or says "nothing".

## Models

Phase 0 **opus**, dispatched. Phase 1 the session — **on Opus**; say so if not.
Phase 3 dispatched: **sonnet** at risk Low/Mid, **opus** at High.

---

## Phase 0 — Explore and score the risk

**Dispatch a write-capable subagent (`general-purpose`, `model: opus`).** It
writes `01-FINDINGS.md`, `RISK.md` and `CHECKLIST.md` — **its prompt must say
those are the only files it may write** — and returns only the verdict and the
risk line.

### Order of work

0. **Shared history** — `bash <plugin>/skills/build-task/scripts/history.sh --search <term>`.
1. **The project** — its living notes, earlier runs' `04-REPORT.md` in
   `agent-runs/done/` that bear on this task, and every file the task touches:
   documents, data, scripts, **photos and videos — look at them**, don't go by
   their names.
2. **The user's rules** — collect every stated constraint into one list.
3. **Outside sources** — when a fact decides the result: primary or reputable
   sources, each cited by URL. Library docs when a script depends on one.
4. **Try it** — run the existing scripts the task depends on; open the images.
   Never take the prompt's word for how something is; check it.

### When to stop

When you can say what the result has to be, what it rests on, and what check
will prove it — **and** every dimension in `phases/risk.md` has evidence. No
evidence scores 3, so keep reading until it exists or the gap is named.

### How to think

- **Try to disprove each conclusion** — ask what would show it wrong; look for it.
- **Label every claim** `read` (seen in a file, photo or the user's words),
  `sourced` (from a cited outside source) or `inferred` (deduced — Phase 1 must
  confirm it before relying on it).
- **Name your blind spots** — what you could not see, and why.

### 01-FINDINGS.md must contain

- Every claim cited — `file:line`, the photo's file name, a URL, or "your
  message" — and labelled.
- **What contradicted the prompt** — own heading, always; "nothing" if so.
  Includes any gap between *Your words* and *How I read it*.
- **The user's rules** that bind this task.
- **Notes updates** — facts in the living notes this run proved wrong or stale.
- **What the shared history warned about**, or "nothing relevant found".
- **Everything that relies on this** — other notes, decisions or files built on
  what will change, when reach scores 2 or more.
- **What I did not read or see, and why.**
- `browser: yes | no` · **Verdict:** `feasible` / `blocked` / `needs a decision`
- **The check** — fixed now, before any work: what will prove the result right.
  A command, a recomputation, each output tested against the rules list, a known
  case with a known answer.
- **"I could not determine X"** wherever true — and whether X decides the result.

### RISK.md

Scored with `phases/risk.md`, computed with
`bash <v2>/risk-score.sh B R K T G D` — never by hand.

### CHECKLIST.md

- **Steps** in order, each a `- [ ]` box naming the output and the finding it
  comes from.
- **Not in this task** — things noticed but out of scope. Phase 4 reports them.
- **Last box:** run the check (Phase 2).

### Handoff

`feasible` → Phase 1. `blocked` / `needs a decision` → **stop**, ask, wait. A
better approach exists → old vs new, cost and risk of each, a recommendation;
stop and wait. **A fact only the user knows that decides the result is always
`needs a decision`** — never guess it.

---

## Phase 1 — Do the work

**Open with one or two lines: which findings you work from, the risk level, the
safeguards `RISK.md` switched on,** and any finding you are deliberately not
acting on, with the reason.

- Deliver what was asked, at the scope asked. A better idea → one sentence, then
  continue as asked. Never quietly widen, narrow or change the task.
- **Work down `CHECKLIST.md` in order; tick each box.** A step added, dropped or
  changed → edit the checklist with the reason.
- **Confirm every `inferred` finding** before relying on it.
- **Safeguards from `RISK.md` are not optional.**
- **Every output passes the user's rules list.** One that cannot → stop and say so.
- **Back up before changing any existing file** (no git). Deleting anything →
  say in plain English what disappears and how to get it back.
- **Never do anything irreversible outside the project** — buy, send, submit,
  post, book. Prepare it; the report tells the user the exact step.
- No placeholders, no "etc." standing in for work. Estimates are labelled as
  estimates, with how they were made.
- **An assumption breaks → stop** and report. Never invent a replacement goal.

---

## Phases 2 and 3 run at the same time

When Phase 1 is done, **dispatch Phase 3 in the background, then do Phase 2.**
Any change to the outputs after that → redo Phase 2 and re-dispatch Phase 3.
Phase 4 starts only when both pass.

## Phase 2 — Prove it

Something **outside** the work itself, and what actually came back.

1. **Run Phase 0's check first, unchanged.** Checks may be added, never swapped.
2. **Then what the outputs call for:**

| Output | Check |
|---|---|
| Numbers, calculations | recompute independently — a script, not by reading them over |
| Scripts | run them; compare against a case with a known answer |
| Images, documents | open them and look; confirm each says what the report will claim |
| Facts and advice | each traced to its citation; each tested against the user's rules list |
| Anything visible in a browser | `browser: yes` only, **last** |

3. **Reach 2+** → also check that everything listed as relying on this still
   holds.

Command output goes to `02-CHECK-output.log`; read the tail, and the whole log
if anything is unexpected. **`02-CHECK.md`:** each check, what came back
(deciding lines verbatim), and **pass / fail**. A fail → back to Phase 1, then
all checks again. **After two failed rounds, stop and report.** What cannot be
checked from here → steps the user can follow in under a minute.

## Phase 3 — Independent review

**Dispatch a fresh subagent** (model from `RISK.md`). Give it **`00-PROMPT.md`
verbatim**, the list of outputs (with `backups/` for changed files), and the
**names** of dimensions that scored 3. It may read anything in the project. It
must never see `01-FINDINGS.md`, `RISK.md`'s evidence, `CHECKLIST.md`, `02-CHECK*`
or the worker's reasoning. It writes `03-REVIEW.md` — the only file it may
write, said in its prompt — and returns pass/fail plus any amber, red or
correctness items.

1. **Does it achieve what `Your words` asked?** Judge against the user's words,
   not the reading. Pass / fail.
2. **Anything beyond the ask?** Green (needed) / Amber (separable) / Red (out of
   scope).
3. **Does any output break a stated rule, rest on an unsupported claim, or give
   the wrong answer for some case?** Name it. Any real one is a fail.
4. **Anything a careful expert in this field would say is wrong or missing?**

Fail on 1 or 3 → back to Phase 1, then a fresh review; after two rounds, stop
and report. **Red → removed**, re-checked, re-reviewed. **Amber → the user
decides** in the report.

**Next: read `phases/report-and-close.md` and do Phases 4 and 5.**
