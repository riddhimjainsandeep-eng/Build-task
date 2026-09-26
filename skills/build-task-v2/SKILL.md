---
name: build-task-v2
description: Experimental v2 of the build-task six-phase procedure — risk-scored, quality-first, with user settings. Use ONLY when the user runs /build-v2 or explicitly asks for build-task v2; otherwise the regular build-task skill applies.
---

# Build Task v2 — six-phase procedure

The user is not a coder and cannot verify the code himself; this procedure is the
review he cannot do. All six phases always run — each has a job no other phase
does. Every phase leaves a file in the task folder.

## The rule above every other rule

**Quality is never traded for cost.** A saving is allowed only when it removes
waste — repeated context, duplicate files, mechanical tool calls, output nobody
reads. It must never reduce what the agent reads, checks or reasons about. If a
saving would narrow what the agent sees, it is not a saving; drop it. Never lower
effort to save money.

Phases 4 and 5 live in `phases/report-and-close.md` beside this file — **read it
before starting Phase 4**, not earlier. The risk rubric is in `phases/risk.md` —
Phase 0 reads it. Rationale is in `reference.md` here and in
`../build-task/reference.md`; read those only when editing the procedure or when
a rule looks arbitrary.

**Read `user.md` at the repo root once at the start of a run and follow it** — who
everything user-facing is written for and how he needs it.

**No `agent-runs/` folder and no `.build-task-setup` marker → this project was
never set up. Run the `build-setup` skill first, then come back.**

## Configuration and settings

Read `build-task.config.json` (repo root) on the first phase and hold it for the
run. Defaults: `taskFolder: agent-runs/active`, `doneFolder: agent-runs/done`,
`docsRoot: docs/maps`, `rulesFile: CLAUDE.md`, `buildCommand`/`testCommand` null
(infer, then ask once), `liveFiles: []`.

**User settings** decide what the user gets and where it goes — never how
carefully work is done. Read them with
`bash <this skill's folder>/scripts/settings.sh` (global
`~/.claude/build-task/settings.json`, overridden per project by the config's
`settings` key). `/build-v2 settings` changes them.

**`liveFiles`** run *outside* this working tree (scheduler, cron, service), so an
uncommitted edit to one is already live behaviour. See Phase 1.

## Task folder

All work lives in `<taskFolder>/YYYY-MM-DD_task-name/`. Never write these files to
the repo root.

```
00-PROMPT.md         the prompt file (already there)
01-FINDINGS.md       Phase 0 — facts, each cited
RISK.md              Phase 0 — the risk score, read by every later phase
CHECKLIST.md         Phase 0 — Phase 1's steps, ticked as they are done
02-CHECK.md          Phase 2  (+ 02-CHECK-output.log, the full output)
03-REVIEW.md         Phase 3
04-REPORT.md         Phase 4 — user report, then technical handoff (if on)
<task>-<date>.zip    Phase 5 — archive, untracked (if on)
RESUME.md            rewritten continuously, deleted by Phase 5
```

Files the user never reads are still written: later phases, resumes and the
archive depend on them.

## `browser: yes | no`

Declared under the prompt file's title; if missing, Phase 0 decides. It binds
Phases 1–5: **`no`** — no browser tool may be called by them or their subagents;
`yes` — browser work goes **last** in its phase, and the report ends by telling
the user to `/compact`. No browser tool in this environment → always `no`.

**Phase 0 is exempt** — it checks the running app itself on every run where the
project has one (step 4 of its order of work). It is a subagent, so what it sees
never enters the main session's context.

## The verification rule — every phase

**Never rely on a claim in `CLAUDE.md` or a map without verifying it first.**
`docs/CLAUDE-RULES.md` marks every claim `[v]`, `[x]` or `[?]`, dated. Before a
phase depends on a `[?]` claim it checks that claim against the code. The new
mark is recorded in `01-FINDINGS.md` under **Ledger updates**, and Phase 5(b)
writes it into `CLAUDE-RULES.md`. A `[?]` claim is never the basis for a decision.

## Resuming an interrupted run

**Update `RESUME.md` at every phase boundary and after every commit**: which phase
and how far; what is done; what is next; **whether anything is half-written** —
name the file or say "nothing". Record in it the run's start time (ISO) and the
base commit. A clean finish deletes it, so its presence means a run stopped early.
Never write a rule that depends on measuring the usage limit.

If the task folder has phase files, do not start over:

0. Read `RESUME.md` first. It proves nothing about which phases ran; files do.
1. A phase whose file exists is done — except `03-REVIEW.md` and `02-CHECK.md`,
   which count only if the commit they name is `HEAD`. Phase 5 is done only when
   the folder is in `<doneFolder>/`, the run log has its line and `RESUME.md` is
   gone. `04-REPORT.md` present but folder still in `<taskFolder>/` → rerun
   Phase 5 from (a); every step is safe to repeat.
2. `git status`, `git log -1` — uncommitted changes with no commit mean Phase 1
   was interrupted; read the diff before adding to it. `CHECKLIST.md`'s ticks
   show how far Phase 1 got.
3. Continue from the first incomplete phase.

## Models

| Phase | Model |
|---|---|
| 0 — Explore | **opus**, dispatched — always |
| 1 — Implement | the session — **run the session on Opus**. If it is not, say so in the first reply |
| 2 — Prove, 4, 5 | the session |
| 3 — Review | dispatched — **sonnet** at risk Low/Mid, **opus** at High |

Hold effort at one level for the whole session. Raise it only after an effort
failure has appeared; never lower it to save.

---

## Phase 0 — Explore and score the risk

**Dispatch a write-capable subagent (`general-purpose`) on `model: opus`.** It
writes `01-FINDINGS.md`, `RISK.md` and `CHECKLIST.md` and returns only the
verdict and the risk line. **Its prompt must say those three files are the only
ones it may write** — no source edits, no map or ledger edits (it records those
for Phase 5).

### Order of work

0. **Shared history** — search it for this system and task (command below).
1. **`<docsRoot>/00-SYSTEMS.md`**, then the map for each system the task touches.
   A map is a hypothesis: **on conflict the code is right** — record it under
   Ledger updates.
2. **The code** — code-graph index, LSP or grep: definitions and **every**
   reference to what will change.
3. **Library docs**, when a fast-moving dependency's behaviour matters.
4. **See it running** — whenever the project has an app that opens in a browser.
   **Never take the prompt file's word for how the app behaves; check it.**
   - Start the dev command if the app is not already running; open it in a
     **new Claude in Chrome tab** (never the headless devtools browser).
   - **Test every claim the prompt makes about behaviour** — click, type, watch.
     Mark each **confirmed**, **not reproduced**, or **behaves differently** (say
     what you saw) under *What contradicted the prompt file*.
   - **Hunt for bugs the prompt did not mention** on the screens the task touches
     and every screen that shares code with them (the callers from step 2). Read
     the console on each.
   - **Safety:** on a local dev server, anything goes. On a live site: navigate
     and read only — never save, delete, submit, pay, send, or log in with the
     user's credentials.
   - Close the tab, and stop the dev server if you started it.
   - Chrome tools unreachable → say so under *Seen in the browser*; continue on
     the code alone.

Read as widely as the task needs — the rule above every rule applies.

### When to stop

Stop when both hold:
- you can answer: what this touches, where the cause or insertion point sits, and
  what check will prove it worked; **and**
- every risk dimension in `phases/risk.md` has a rating backed by evidence. A
  dimension you cannot evidence scores 3 — so keep reading until the evidence
  exists or the gap is named.

### How to think

- **Try to disprove each conclusion.** For every finding, ask what would show it
  wrong and look for that.
- **Label every claim `read` or `inferred`.** `read` = seen in the code at the
  cited line. `inferred` = deduced; Phase 1 must confirm it before relying on it.
- **Name your blind spots.** What you did not read, and why.

### 01-FINDINGS.md must contain

- Every claim cites `file.ext:line` and is labelled `read` or `inferred`.
- **What contradicted the prompt file** — own heading, always; "nothing" if so.
- **Ledger updates** — `[?]` claims checked, their new mark and date; map
  disagreements.
- **What the shared history warned about**, or "nothing relevant found".
- **Seen in the browser** — each observation cites the page URL and what was
  clicked, as code claims cite `file:line`. Bugs found outside this task are
  listed here, never fixed. No app, or no Chrome tools → say which.
- **Every caller** of what will change, when blast radius scores 2 or more.
- **What I did not read, and why.**
- `browser: yes | no` · **Verdict:** `feasible` / `blocked` / `needs a decision`
- **The check** — the exact command that will prove this worked, fixed now,
  before any code exists.
- **Scope level** and why (see Phase 1).
- **"I could not determine X"** wherever true.

A findings file that needs far more than ten citations is a scoping signal — say
if the task should be split.

### RISK.md

Scored with `phases/risk.md`; computed with
`bash <this skill's folder>/scripts/risk-score.sh B R K T G D` — never by hand.

### CHECKLIST.md

Phase 1's route, so it stays on the task and in order:

- **Steps**, in order, each a `- [ ]` box naming the file or function and the
  finding it comes from.
- **Not in this task** — things noticed but out of scope, including bugs found in
  the browser. Phase 1 does not touch them; Phase 4 reports them.
- **Last box:** run the check from `01-FINDINGS.md` (Phase 2 does this).

### Handoff

- `feasible` → straight to Phase 1.
- `blocked` / `needs a decision` → **stop**, report, wait.
- A better alternative exists → old vs new, cost and risk of each, your
  recommendation. Stop and wait.

---

## Phase 1 — Implement

**Open by stating in one or two lines which findings you implement against, the
risk level, and which safeguards `RISK.md` switched on.** Name any finding you are
deliberately not acting on, with the reason.

**Scope.** Deliver what was asked, at the scope intended. A better approach → say
so in one sentence and continue as asked. Never quietly widen, narrow or
transform the task. **Scope level** defaults to `full` — the smallest solution
that works; lower it **only** to fix at a single shared choke point instead of
many places. Never change the declared level silently.

- **Work down `CHECKLIST.md` in order; tick each box as it is done.** A step that
  must be added, dropped or changed → edit the checklist with the reason and
  declare it in the commit message. Never silently.
- **Before each edit, re-read the lines it depends on** — line numbers drift.
- **Confirm every `inferred` finding** you rely on before relying on it.
- **Safeguards from `RISK.md` are not optional** (see `phases/risk.md`), e.g.
  detectability 3 → write the test first and see it fail, then fix and see it pass.
- **No truncated stubs** or placeholders.
- **Re-check symbols after edits** — breakage in files you did not open.
- **Tests: calculation and logic** — anything with a right answer that can drift
  silently. No tests for pure layout unless a safeguard asks for one.
- **Assumption breaks → stop** and report. Never invent a replacement goal.
- **Live files:** edit each in one pass, coherent before anything else. **Never
  end a session with one half-written.**
- **Destructive changes:** back up first; state in plain English what data
  disappears, whether it comes back, and the exact undo command.

**Commit** locally when the code is written. Declare any change of method in the
commit message (Phase 3 reads commit messages). **Do not push** — Phase 5 does,
and only after passes.

---

## Phases 2 and 3 run at the same time

Right after Phase 1's commit, **dispatch Phase 3 in the background, then do
Phase 2.** Phase 3 must not see Phase 2's results, so running together loses
nothing. **Any code change after that → commit, redo Phase 2's checks and
re-dispatch Phase 3 on the new diff.** Phase 4 starts only when `02-CHECK.md` and
`03-REVIEW.md` both name `HEAD` and both pass.

## Phase 2 — Prove it works

Run something **external** and report what actually came back.

1. **Run Phase 0's check first, unchanged.** Extra checks may be added; the
   pre-committed one may never be replaced.
2. **Then the checks the change calls for:**

| Touched | Check |
|---|---|
| Build or config | the build command — note the exit code |
| Data or logic | the tests; query a **test or local** data store and print real rows — the live one only if the config names it safe |
| Anything visible | `browser: yes` only — open the app, screenshot, read the console, **last** |

3. **Blast radius 2+** → also run the tests for the callers listed in the
   findings, not just the changed code. No tests for a caller → say so.

**Full output goes to a log, not into context:**

```bash
<command> > <task folder>/02-CHECK-output.log 2>&1; echo "exit=$?"; tail -n 40 <task folder>/02-CHECK-output.log
```

**If the exit code is non-zero, or anything in the tail is unexpected, read the
full log** before judging. Never judge from a truncated view.

**`02-CHECK.md`:** the commit checked, each exact command, its exit code, the
deciding output lines copied verbatim, the log path, and **pass / fail**.

**A check fails →** back to Phase 1 with the failure attached, fix, commit, rerun
all checks. **After two failed rounds, stop and report to the user** — never loop
silently, never report a failure as done.

**What cannot be checked from here** (push notifications, hardware): steps the
user can follow in under a minute — screen, tap, expected result, what to send if
it fails.

## Phase 3 — Independent review

**Dispatch a fresh subagent** — model from `RISK.md` (Low/Mid `sonnet`, High
`opus`). Give it: **`00-PROMPT.md` verbatim** (never a paraphrase), the diff
`git diff <base>..HEAD`, the commit messages `git log <base>..HEAD`, and the
**names** of the dimensions that scored 3 — not the reasons. It may read any code
in the repo. It must never see `01-FINDINGS.md`, `RISK.md`'s evidence, `CHECKLIST.md`, `02-CHECK*`
or the implementer's reasoning. It writes `03-REVIEW.md` itself — the only file
it may write, said in its prompt — headed with the commit reviewed, and returns
pass/fail plus any amber, red or correctness items.

Four questions:

1. **Does it achieve the goal?** Pass / fail.
2. **Did it add anything beyond the ask?** Green (broken without it) / Amber
   (separable, should have been proposed) / Red (out of scope).
3. **Was any change of method declared** in the commit messages? Information.
4. **Is there any input or state where this diff does the wrong thing?** Name it
   with the line. Any real one is a fail.

**Outcomes:** fail on 1 or 4 → back to Phase 1 with the reviewer's reason, then a
fresh review; after two rounds, stop and report. **Red → removed**, re-checked,
re-reviewed. **Amber → the user decides** in the report (keep or remove).

**Security review** also runs when blast radius or reversibility scores 3, if a
security-review tool is available.

**Next: read `phases/report-and-close.md` and do Phases 4 and 5.**

---

## The shared history

One Supabase table, `build_runs`, **append-and-read only**. Never write a secret
into it. Credentials: `BUILD_TASK_SUPABASE_URL` / `BUILD_TASK_SUPABASE_KEY`, or
`~/.claude/build-task/env`; missing → say so once, continue without it.

**Read (Phase 0)** — `../build-task/scripts/history.sh --search <term>` and
`--repo <owner/name>`, or:

```bash
curl -sS "$BUILD_TASK_SUPABASE_URL/rest/v1/build_runs?select=repo,task,run_date,verdict,contradictions,lessons,landmines&order=logged_at.desc&limit=25" \
  -H "apikey: $BUILD_TASK_SUPABASE_KEY" -H "Authorization: Bearer $BUILD_TASK_SUPABASE_KEY"
```

**Write (Phase 5)** — `phases/report-and-close.md`.

## Note for whoever edits this skill later

Do not add "double-check your work" lines — they cause over-verification without
adding information. Phase 2's external check and Phase 3's independent review do
that job. Rationale belongs in `reference.md`.
