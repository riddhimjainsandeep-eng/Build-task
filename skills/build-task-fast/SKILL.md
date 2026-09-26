---
name: build-task-fast
description: Experimental faster variant of the build-task six-phase procedure — same phases and checks, fewer tokens and tool calls. Use ONLY when the user runs /build-fast or explicitly asks for the fast build procedure; otherwise build-task-v2 applies.
---

# Build Task (fast) — six-phase procedure

The same procedure as `build-task`, with the same phases, checks and outputs,
arranged to cost less: Phase 3 runs alongside Phase 2, Phases 4–5 load only when
reached, the technical handoff is a section of the report, check output goes to
a log file, and Phase 5's mechanical steps are one script.

The user is not a coder and cannot verify the code himself; this procedure is the
review he cannot do. Every phase produces a file in the task folder. Never skip a
phase because a task looks small.

Phases 4 and 5 live in `phases/report-and-close.md` beside this file — **read it
before starting Phase 4**, not earlier. Rationale and worked examples are in
`../build-task/reference.md`, plus `reference.md` beside this file for what the
fast variant changes; read them only when editing the procedure or when a rule
looks arbitrary.

**Read `user.md` at the repo root once at the start of a run and follow it** — who
everything user-facing is written for and how he needs it. It binds every phase
that writes something he reads, Phase 4 most of all.

**No `agent-runs/` folder and no `.build-task-setup` marker → this project was
never set up. Run the `build-setup` skill first, then come back.**

## Per-project configuration

Read `build-task.config.json` (repo root) on the first phase and hold its values
for the run. Defaults: `taskFolder: agent-runs/active`,
`doneFolder: agent-runs/done`, `docsRoot: docs/maps`, `rulesFile: CLAUDE.md`,
`buildCommand`/`testCommand` null (infer, then ask once), `liveFiles: []`,
`push: true`.

**`liveFiles`** run *outside* this working tree (scheduler, cron, background
service), so an uncommitted edit to one is already live behaviour. See Phase 1.

## Task folder

All work lives in `<taskFolder>/YYYY-MM-DD_task-name/`. Create it if missing.
Never write these files to the repo root.

```
00-PROMPT.md         the prompt file (already there)
01-FINDINGS.md       Phase 0
02-CHECK.md          Phase 2  (+ 02-CHECK-output.log, the full command output)
03-REVIEW.md         Phase 3
04-REPORT.md         Phase 4 — user report, then technical handoff; Phase 5 appends its cost
<task>-<date>.zip    Phase 5 — the run archive, untracked
RESUME.md            rewritten continuously, deleted by Phase 5
```

## `browser: yes | no`

Declared on its own line under the prompt file's title; if missing, Phase 0
decides. Phase 0 records it and it binds the run:

- **`no`** — **no browser tool may be called at any point**, by any phase or
  subagent. `02-CHECK.md` and `04-REPORT.md` both state `browser: no`.
- **`yes`** — do browser work **as late in its phase as possible**.
  `04-REPORT.md` closes by telling the user to `/compact` — he can type it, the
  agent cannot.

No browser tool in this environment → `browser` is always `no`.

## The verification rule — every phase

**Never rely on a claim in `CLAUDE.md` or a map without verifying it first.**
`docs/CLAUDE-RULES.md` marks every claim `[v]` verified, `[x]` false or `[?]`
unverified, each dated. Before a phase depends on a `[?]` claim, check that one
claim against the code and update its mark and date in the same run. A `[?]`
claim may never be the basis for a decision.

## Resuming an interrupted run

**Update `RESUME.md` at every phase boundary and after every commit.** Four
things: which phase and how far in; what is done; what is next, in order;
**whether anything is half-written** — name the file, or say "nothing" in those
words. A clean finish deletes it (Phase 5), so its presence means a run stopped
early. Small mode does not exempt it.

**Do not write a rule that depends on measuring the usage limit.** The
context-warn hook does the only measurable warning; do not duplicate it.

If the task folder already has phase files, do not start over:

0. Read `RESUME.md` first if present. It proves nothing about which phases ran;
   the phase files do.
1. A phase whose file exists is done — except `03-REVIEW.md`, which counts only
   if the commit it names is `HEAD` (Phase 3 runs alongside Phase 2, so it can
   predate a fix). Phase 5 leaves no file: it is done only when the folder is in
   `<doneFolder>/`, the run log has its line, the archive exists, the run is in
   the shared history and `RESUME.md` is gone. `04-REPORT.md` present but the
   folder still in `<taskFolder>/` → restart Phase 5 at (a); every step is safe
   to repeat.
2. `git status`, `git log -1` — uncommitted changes with no commit mean Phase 1
   was interrupted mid-write; read the diff before adding to it.
3. Continue from the first incomplete phase. Re-run a complete phase only if its
   file contradicts what is on disk, and say why in the report.

## Models and effort

Only dispatched phases carry their own model; pass it inline (`model: opus`), not
in an agent file.

| Phase | Model |
|---|---|
| 0 — Explore | **opus**, on the dispatch |
| 3 — Review | **sonnet**, on the dispatch |
| 1, 2, 4, 5 | inherit the session (run the session on Opus) |

**Do not set effort anywhere.** Pick one level at session start and hold it.
**Raise it only after an effort failure has appeared** — a phase skipped a file,
didn't run its check, bailed partway — never pre-emptively, then for the whole
session. Had the context, clearly tried, still wrong is a *model* problem. Phase 4
surfaces the signal; it does not act on it.

---

## Phase 0 — Explore

**Dispatch a write-capable subagent (`general-purpose`, not read-only) on
`model: opus`.** It writes `01-FINDINGS.md` itself and returns only its verdict.
**Its prompt must say that file is the only one it may write** — no source edits,
no fixes, no "while I'm here" changes.

### Order of work

0. **The shared history** — one read near the start (command under "The shared
   history" below). Read-only: never write to it here. Nothing found is normal;
   say so in one line.
1. **The map for this system** — `<docsRoot>/<system>.md` when one exists. Start
   there. **On conflict the code is right** — record the disagreement in
   `01-FINDINGS.md` and fix the mark in `docs/CLAUDE-RULES.md`.
2. **This project's code-search tooling** — code-graph index, LSP, or grep.
   Definitions and all references for the symbols involved. Skip silently past
   tools the project doesn't have.
3. **Library docs lookup** — only if the task depends on how a fast-moving
   dependency behaves in a version newer than training data.

**Stop reading** once you can answer: what this touches, where the cause or
insertion point sits, and what check will prove it worked.

### 01-FINDINGS.md must contain

- **Every claim cites `file.ext:line`**; an uncited claim is labelled a guess.
- **What contradicted the prompt file** — own heading, always present; "nothing"
  if nothing did. Do not bury it.
- **Which `[?]` claims you verified**, and what they turned out to be.
- **Anything the shared history warned about**, or "nothing relevant found".
- **`browser: yes | no`**, and a provisional small-task call (Phase 4 decides).
- **Verdict:** `feasible` / `blocked` / `needs a decision`
- **The check** — the exact command that will prove this worked
- **Scope level** and why (see Phase 1)
- **"I could not determine X"** wherever true — never invent an answer.

Roughly ten citations. **More than ten → the task is too big; stop and say it
should be split.**

### Handoff

- `feasible` → straight to Phase 1. Do not wait.
- `blocked` / `needs a decision` → **stop.** Report and wait.
- A better alternative exists → old vs new, cost and risk of each, your
  recommendation. Stop and wait.

---

## Phase 1 — Implement

**Open by stating in one or two lines which findings you are implementing
against**, and name any you are deliberately not acting on, with the reason.

**Scope.** Deliver what was asked, at the scope intended. Make routine judgment
calls yourself. A better approach → say so in one sentence and continue as asked.
Never quietly widen, narrow or transform the task.

**Scope level.** Default `full` — the smallest solution that works. Lower it
**only** when the fix would otherwise be applied in more than one place; then fix
it at the single shared choke point. Never change the declared level silently.

- **No truncated stubs** or placeholders of any kind.
- **Re-check symbols after edits** — catch breakage in files you did not open.
- **Tests: calculation and logic only** — intervals, rates, projections, money,
  state transitions. No tests for UI, layout or buttons.
- **Assumption breaks → stop** and report. Do not invent a replacement goal.
- **Live files:** edit each in one pass and leave it coherent before anything
  else. **Never end a session, planned or abrupt, with one half-written.** Not
  touching one is better still — say so in `RESUME.md` and verify with
  `git status --porcelain <path>`.
- **Destructive changes** (schema, deletion, migration, data rewrite): back up
  first, then state in plain English what data disappears, whether it comes back,
  and the exact undo command. Never work around a backup hook.

**Commit** locally when the code is written — a rollback marker. **Do not push**;
that is Phase 5. Update `RESUME.md` after each commit, and record in it the commit
Phase 1 started from (the run's base) — Phase 3 and Phase 5 need it.

---

## Phases 2 and 3 run at the same time

Right after Phase 1's commit, **dispatch Phase 3 in the background, then do
Phase 2 in the foreground.** Phase 3 needs only the goal and the diff, which both
exist now. **If Phase 2 leads to any code change, commit it and re-dispatch
Phase 3 on the new diff** — a review counts only for the commit it reviewed. Do
not start Phase 4 until `03-REVIEW.md` names `HEAD`.

## Phase 2 — Prove it works

Not self-checking. Run something **external** and report what actually came back.

| Touched | Check |
|---|---|
| Build or config | the project's build command — note the exit code |
| Data or logic | query the real data store and print the real rows; run the tests |
| Anything visible | open the app, screenshot it, read the console |

Row three applies **only on `browser: yes`**; otherwise command checks alone, and
say so in `02-CHECK.md`. When it applies, the browser step goes **last**.

**Send full output to a file, not into context:**

```bash
<command> > <task folder>/02-CHECK-output.log 2>&1; echo "exit=$?"; tail -n 40 <task folder>/02-CHECK-output.log
```

If the tail doesn't show what decides the result, `grep` the log for it — never
judge from a truncated view.

**`02-CHECK.md` contains the exact command, its exit code, the real output lines
that prove or disprove the result — copied verbatim, not summarised — and the
path to the full log.** Never "verified working".

**What genuinely cannot be checked from here** (push notifications, home-screen
behaviour, hardware): steps the user can follow in under a minute — the screen,
the tap, what he should see, what to send if it fails (`../build-task/reference.md` has the
example). Never a bare "verify it yourself".

## Phase 3 — Goal review

**Dispatch a fresh subagent on `model: sonnet`** that sees only the goal from
`00-PROMPT.md` and the diff (`git diff <base>..HEAD`). **Never your reasoning.**
It writes `03-REVIEW.md` itself — the only file it may write, said explicitly in
its prompt — headed with the commit it reviewed, and returns only pass/fail plus
any amber or red items.

Not a code quality review. Three questions:

1. **Does it achieve the goal?** Pass or fail.
2. **Did it add anything beyond what was asked?**
   - **Green** — completes the asked-for feature; broken without it
   - **Amber** — separable and useful; should have been *proposed*, not built
   - **Red** — unrelated or out of scope
3. **Was any method deviation declared?** Information only.

Only 1 and 2 can fail.

**A security review runs only when the task touched auth, permissions, secrets or
externally-reachable routes.**

**Next: read `phases/report-and-close.md` and do Phases 4 and 5.**

---

## The shared history

One Supabase table, `build_runs`, shared by every project with this plugin. It is
**append-and-read only** — the database has no update or delete policy. Never
write a secret value into it.

Credentials: `BUILD_TASK_SUPABASE_URL` / `BUILD_TASK_SUPABASE_KEY`, or
`~/.claude/build-task/env`. Neither exists → say so once and continue without it.

**Read (Phase 0)** — `../build-task/scripts/history.sh`, or:

```bash
curl -sS "$BUILD_TASK_SUPABASE_URL/rest/v1/build_runs?select=repo,task,run_date,verdict,contradictions,lessons,landmines&order=logged_at.desc&limit=25" \
  -H "apikey: $BUILD_TASK_SUPABASE_KEY" -H "Authorization: Bearer $BUILD_TASK_SUPABASE_KEY"
```

Narrow with `&or=(lessons.cs.{"term"},landmines.cs.{"term"})` or
`&repo=eq.owner/name`.

**Write (Phase 5)** — `phases/report-and-close.md` covers it.

## Note for whoever edits this skill later

Do not add "double-check your work"-style instructions — they cause
over-verification and burn tokens. Phase 2's external check and Phase 3's
independent review replace them. This file is charged on every turn; rationale
belongs in `reference.md`.
