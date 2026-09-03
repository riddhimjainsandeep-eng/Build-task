---
name: build-task
description: Mandatory six-phase procedure for any change to a codebase. Use whenever the user asks to execute a prompt file, run a task from agent-runs/, fix a bug, add a feature, or otherwise modify code — even if they don't name this skill. Never skip a phase and never reorder them.
---

# Build Task — six-phase procedure

The user is not a coder and cannot verify the code himself; this procedure is the
review he cannot do. Every phase produces a file in the task folder. Never skip a
phase because a task looks small — small mode merges two Phase 4 files, nothing
else.

Rationale, worked examples and the effort glossary are in `reference.md` beside
this file. Read it when editing the procedure or when a rule looks arbitrary —
not on every run. This file is charged on every turn of every phase, so anything
explanatory belongs there, not here.

**Read `user.md` at the repo root once at the start of a run and follow it.** It
says who everything user-facing is written for and how he needs it — plain
English, the reasoning as well as the conclusion, jargon explained where it
appears, and a diagram wherever you are explaining how something works. Phase 4
is where it matters most, but it binds every phase that writes something he
reads.

**If this project has no `agent-runs/` folder and no `.build-task-setup` marker,
it has never been set up. Run the `build-setup` skill first, then come back.**

## Per-project configuration

Read `build-task.config.json` (repo root) on the first phase of every run and
hold its values for the whole run. Defaults if absent:
`taskFolder: agent-runs/active`, `doneFolder: agent-runs/done`,
`docsRoot: docs/maps`, `rulesFile: CLAUDE.md`, `buildCommand`/`testCommand`
null (infer, then ask once), `liveFiles: []`, `push: true`.

**`liveFiles`** are paths that run *outside* this working tree — under a
scheduler, a cron job, a background service — so an uncommitted edit to one is
already live behaviour, not a pending change. Phase 1 has a rule for them.

## Task folder

All work lives in `<taskFolder>/YYYY-MM-DD_task-name/`. Create it if missing.
Never write these files to the repo root.

```
00-PROMPT.md     the prompt file (already there)
01-FINDINGS.md   Phase 0
02-CHECK.md      Phase 2
03-REVIEW.md     Phase 3
04-REPORT.md     Phase 4 — for the user, plain English
                 (Phase 5 appends its own cost section)
05-HANDOFF.md    Phase 4 — technical (omitted in small mode)
<task>-<date>.zip  Phase 5 — the run archive, untracked
RESUME.md        not a phase output — rewritten continuously, deleted by Phase 5
```

## What a prompt file declares

`00-PROMPT.md` is freeform markdown with one required declaration on its own line
under the title: **`browser: yes | no`** — does this task need a
browser-automation tool to verify a visible change?

If missing, Phase 0 decides. Either way Phase 0 records it and it binds the run:

- **`no`** — **no browser tool may be called at any point**, by any phase or
  subagent. Phase 2 uses command checks only. `02-CHECK.md` and `04-REPORT.md`
  both state the run was `browser: no`.
- **`yes`** — do the browser work **as late in its phase as possible**, so its
  results sit in context for fewer turns. `04-REPORT.md` then closes by telling
  the user to `/compact` — he can type it, the agent cannot.

If this environment has no browser tool at all, `browser` is always `no`.

## The verification rule — applies to every phase

Documents drift. Code does not lie. So:

**Never rely on a claim in `CLAUDE.md` or a map without verifying it first.**

`docs/CLAUDE-RULES.md` marks every claim `[v]` verified, `[x]` false, or `[?]`
unverified, each with a date. When a phase is about to depend on a `[?]` claim,
it checks that one claim against the code *before* using it, and updates the mark
and date in the same run. A `[?]` claim may never be the basis for a decision.

This is deliberately progressive: setup verifies the structural claims, and every
task afterwards verifies the ones it actually touches. Over time everything real
gets checked, and nothing is checked twice for show.

## Resuming an interrupted run

### Write `RESUME.md` as you go

**Update it at every phase boundary and after every commit**, not only when
stopping — a run gets no warning that it is about to end. Four things: which
phase and how far into it; what is done; what is next, in order; and **whether
anything is currently half-written** — name the file, or say "nothing" in those
words.

**A clean finish deletes it** (Phase 5, last step), so its presence is itself the
signal that a run stopped early. Small mode does not exempt it.

**Do not write a rule that depends on measuring the usage limit.** Nothing
reports limit spend live. The context-warn hook shipped with this plugin does the
only warning that is actually measurable; do not duplicate its logic.

### Picking up

If the task folder already has phase files, do not start over.

0. Read `RESUME.md` first if there is one. It maps to no phase, so its presence
   proves nothing about which phases ran; trust the phase files for that.
1. Report which phases completed — a phase whose file exists is done. Two
   exceptions: `05-HANDOFF.md` is legitimately absent in small mode, and Phase 5
   leaves no file of its own, so it is finished only when the folder has moved to
   `<doneFolder>/`, the run log has its line, the archive exists, the run is
   logged to the shared history and `RESUME.md` is gone. A run whose
   `04-REPORT.md` exists but which still sits in `<taskFolder>/` stopped inside
   Phase 5 — restart it at step (a); every step is safe to repeat.
2. Check the working tree — `git status`, `git log -1` — for whether Phase 1's
   commit landed. Uncommitted changes with no commit mean Phase 1 was interrupted
   mid-write; read the diff before adding to it.
3. Continue from the first incomplete phase. Re-run a complete phase only if its
   file contradicts what is now on disk, and say why in the report.

## Models and effort

**Only a phase dispatched as a subagent can carry its own model.** Phases 0 and 3
are dispatched; 1, 2, 4 and 5 run in the main session and inherit it. Pass the
model inline on the dispatch — `model: opus` — not in a separate agent file.

| Phase | Model |
|---|---|
| 0 — Explore | **opus**, on the dispatch |
| 1 — Implement | inherits the session (run the session on Opus) |
| 2 — Prove | inherits the session |
| 3 — Review | **sonnet**, on the dispatch |
| 4 — Report | inherits the session |
| 5 — Close out | inherits the session |

**Do not set effort anywhere.** It cannot be set per phase, it is session-level,
and changing it between requests invalidates prompt caching. Pick one level at
session start and hold it. **Raise it only when an effort failure has already
appeared** — a phase skipped a file, didn't run its check, bailed partway — never
pre-emptively, and then for the whole session. Had the context, clearly tried,
still wrong is a *model* problem instead. Phase 4 surfaces the signal; it does not
act on it. Glossary in `reference.md`.

---

## Phase 0 — Explore

**Dispatch a write-capable subagent (`general-purpose`, not read-only) on
`model: opus`.** It writes `01-FINDINGS.md` into the task folder itself and
returns only its verdict. **That file is the only one it may write** — say so
explicitly in its prompt, because the restriction is carried by instruction, not
by permission. Everything else is read-only: no source edits, no fixes, no
"while I'm here" changes.

### Order of work

0. **The shared history** — one read, near the start. Other projects may have hit
   this before (see "The shared history" below). Read-only, always: never write to
   it here, never edit or delete a past entry. Nothing found is a normal result;
   say so in one line and move on.
1. **The map for this system** — `<docsRoot>/<system>.md` when one exists. Start
   there instead of exploring from scratch. **A map is a hypothesis, never
   authority: when map and code disagree, the code is right** — record the
   disagreement in `01-FINDINGS.md` and fix the mark in `docs/CLAUDE-RULES.md`.
2. **Whatever code-search tooling this project actually has** — a code-graph
   index, an LSP, or plain grep. Definitions and all references for the symbols
   involved: what else calls this, mechanically rather than by guessing. Skip
   silently past tools this project doesn't have; absence is not a blocker.
3. **Library docs lookup**, only if the task depends on how a fast-moving
   dependency behaves in a version newer than training data. Look it up rather
   than stating it from memory.

### Stopping rule

Stop reading as soon as you can answer three things: what this task touches,
where the cause or insertion point actually sits, and what check will prove the
change worked. Reading beyond that is procrastination.

### 01-FINDINGS.md must contain

- **Every claim cites `file.ext:line`.** An uncited claim is a guess and must be
  labelled one.
- **What contradicted the prompt file** — its own heading, always present. If the
  prompt file assumed something the code does not do, say so plainly; write
  "nothing" if nothing did. This is how the user learns what his own project
  actually does, so do not bury it.
- **Which `[?]` claims you verified**, and what they turned out to be.
- **Anything the shared history warned about**, or "nothing relevant found".
- **`browser: yes | no`**, and a provisional call on whether this looks like a
  small task (Phase 4 makes the binding decision from the real diff).
- **Verdict:** `feasible` / `blocked` / `needs a decision`
- **The check** — the exact command that will later prove this worked
- **Scope level** and why (see Phase 1)
- **"I could not determine X"** wherever true. Saying you do not know is correct
  here; inventing a plausible answer is not.

Roughly ten citations. **If you need more than ten, the task is too big — stop
and say it should be split.** A bloated findings file is a scoping signal.

### Handoff

- `feasible` → continue straight to Phase 1. Do not wait.
- `blocked` or `needs a decision` → **stop.** Report and wait for the user.
- A better alternative exists → old vs new, the cost and risk of each, your
  recommendation. Stop and wait.

---

## Phase 1 — Implement

**Read `01-FINDINGS.md` and open Phase 1 by stating, in one or two lines, which
findings you are implementing against** — and name anything in them you are
deliberately not acting on, with the reason. If you cannot write those two lines,
you have not read the file.

**Scope.** Deliver what was asked, at the scope intended. Make routine judgment
calls yourself. If a better approach exists, say so in one sentence and continue
with the task as asked. Do not quietly widen, narrow, or transform it.

**Scope level.** Default `full` — the smallest solution that works. Lower it
**only** when the fix would otherwise be applied in more than one place; then
find the single shared choke point and fix it there instead. The level was
declared in `01-FINDINGS.md`; never change it silently.

### Standing rules

- **No truncated stubs.** Never write `// rest of implementation here` or any
  placeholder. The user cannot see that a stub is a stub.
- **Re-check symbols after edits** — catch breakage in files you did not open.
- **Tests: calculation and logic only.** Anything with a right answer that can
  silently drift wrong — intervals, rates, projections, money, state
  transitions. No tests for UI, layout or buttons.
- **Assumption breaks → stop.** If something in the prompt file turns out to be
  false mid-build, stop and report. Do not invent a replacement goal.
- **Live files.** Anything in `liveFiles` runs outside this working tree, so an
  uncommitted edit to one **is the machine's live behaviour**. Edit any such file
  in one pass and leave it coherent before starting anything else. **Never end a
  session, planned or abrupt, with one of them half-written.** Not touching one
  at all is better still — say so in `RESUME.md` and verify with
  `git status --porcelain <path>`.
- **Destructive changes** (schema change, deletion, migration, data rewrite):
  back up first, then state in plain English what data disappears, whether it
  comes back, and the exact command to undo it. If a hook enforces the backup, do
  not work around it.

**Commit** locally when the code is written, with a descriptive message — a
rollback marker. **Do not push:** in most projects pushing deploys, and that
happens in Phase 5, not before. Update `RESUME.md` after each commit.

---

## Phase 2 — Prove it works

Not self-checking. Run something **external** and report what actually came back:
the reasoning can be flawless and still be wrong about the real system.

| Touched | Check |
|---|---|
| Build or config | the project's build command — note the exit code |
| Data or logic | query the real data store directly and print the real rows; run the tests |
| Anything visible | open the app, screenshot it, read the console |

The third row applies **only on a `browser: yes` run**; otherwise use command
checks alone and say so in `02-CHECK.md`. When it does apply, the browser step
goes **last in the phase**.

**`02-CHECK.md` contains the exact command run and the actual output it
returned.** Not a summary. Not "verified working". The real text.

**When something genuinely cannot be checked from here** — push notifications,
home-screen behaviour, hardware — that is a real limit, not laziness. Write steps
the user can follow in under a minute, naming the screen, the tap and what he
should see (`reference.md` has the worked example). Never end with a bare "verify
it yourself".

---

## Phase 3 — Goal review

**Dispatch a fresh subagent on `model: sonnet`** that sees only two things: the
goal from `00-PROMPT.md`, and the diff. **Never your reasoning** — that is what
makes it an independent reader.

Deliberately narrow: not a code quality review. Three questions:

1. **Does it achieve the goal?** Pass or fail. This catches working code that
   solves the wrong problem — every check can pass and the result still be wrong.
2. **Did it add anything beyond what was asked?** Classify:
   - **Green** — completes the asked-for feature; it would be broken without it
   - **Amber** — separable and useful, but the feature works without it. This
     should have been *proposed*, not built. The idea may be good; the user never
     got to say no
   - **Red** — unrelated or out of scope
3. **Was any method deviation declared?** Doing it differently is often fine.
   Doing it differently *silently* is not.

Only 1 and 2 can fail. 3 is information.

**A security review runs only when the task touched auth, permissions, secrets or
externally-reachable routes.** Not every task.

---

## Phase 4 — Report

**Small mode is decided here, by the system, not by the user.** Measure the real
diff: **under roughly 20 lines and touching no data, schema or logic** → write one
file, `04-REPORT.md`, user-facing report first and a short technical section
after, and skip `05-HANDOFF.md`. Otherwise write both. Borderline counts as not
small. **Say which mode you chose and why, in one line, in the report and in
chat** — the user never has to judge the size himself, but he does get to see the
call. Nothing earlier is ever shortened, `RESUME.md` included.

### 04-REPORT.md — for the user

Plain English, per `user.md`. No code, no file paths. Where a technical word is
unavoidable, explain it immediately below that paragraph, never in a glossary at
the end. Give the reasoning, not just the conclusion — what the alternative was
and why you did not take it.

**If the report explains how something works, draw it.** A small Mermaid diagram
in the report itself, and — when it is worth keeping — a numbered file in
`<docsRoot>/flowcharts/`. He reads a diagram far faster than the paragraph it
replaces.

1. What was asked — one line
2. What was done
3. Evidence — the command and what it returned
4. **What contradicted what you believed** — own heading, always present
5. Anything added beyond the ask — green/amber/red with your reasoning
6. What could not be checked from here — exact steps, or "nothing"
7. **Effort signal** — own heading, always present. Did any phase skip a file it
   should have read, not run its check, or stop partway? One line is enough; if
   nothing of the kind happened, say that. Report the signal only — do not raise,
   lower or recommend an effort level. A human decides that at session launch.
8. Whether the run was `browser: yes` or `no`, and which report mode was used.
   If `yes`, close by telling the user to `/compact` before continuing.

Phase 5 appends one further section — its own cost. Leave room for it.

Print this in chat as well as writing it to the folder.

### 05-HANDOFF.md — for the next session

For a reader who has never seen this repo and never will. Dense and factual, no
narrative; precision over readability.

1. Files changed — full path, one line each
2. New or changed functions and routes — exact names, what they take and return
3. Data changes — table, columns, types, migrations actually run
4. Verified vs assumed — split explicitly, label anything unverified
5. Corrections to reality — every place the codebase contradicted the prompt file
6. Conventions observed — how this codebase does things
7. Landmines — anything fragile noticed and deliberately not touched
8. The reusable check — command and output
9. Left undone — deliberate omissions, known limits, open threads

**NO SECRETS.** This file gets pasted into chat windows. Never include the value
of any key, token, connection string or `.env` entry. Names are fine; values
never are.

---

## Phase 5 — Close out

Mechanical, and the phase most likely to be dropped when a session ends early —
which is why it is its own phase. Do (a) to (h) in order; every step is safe to
repeat, so a resume can start again at (a).

### a) Documents

Update every map this run made wrong, under `<docsRoot>/`. Add a dated changelog
line. If no map existed for the system this task worked on, create one from what
Phase 0 established. Three limits:

- **Only the parts you actually verified this session.** Do not rewrite a whole
  map from a partial view — that makes maps worse over time, not better.
- **Never touch the map of a system this task only brushed past.**
- **A map is a hypothesis; on conflict the code is right.**

`<docsRoot>/flowcharts/` holds every plain-language diagram, one per file,
numbered so they read straight through. A task that produces or invalidates one
puts it there with the next number and adds its line to that folder's README.

**"No map changes required" is a real and useful answer.**

### b) The rules file, with a budget

`CLAUDE.md` is loaded on every turn of every session, so a line added there is
paid for forever.

- **Correct** what this run *proved* wrong, with this run's evidence.
- **Add** only what a future run would get wrong without it — not what is merely
  true.
- **Anything added must be paid for** by tightening or merging something else. If
  it genuinely cannot be, add it and flag that in the report.
- **Never remove a rule** to make room. Tighten wording, merge duplicates, cut
  explanation — never instructions.
- Mark a superseded fact resolved-with-history rather than deleting it:
  `~~the old claim~~ **RESOLVED <date> — what changed.**`
- **"No `CLAUDE.md` changes required" is a real answer.**

**`docs/CLAUDE-RULES.md` is the inventory** — every claim, numbered, with its
`[v]`/`[x]`/`[?]` mark and date. It is what makes "nothing was removed"
verifiable instead of an impression. **If this run changed `CLAUDE.md`, or
verified or disproved any claim, update the inventory in the same commit.**

### c) Move and log

Move the folder from `<taskFolder>/` to `<doneFolder>/`, then append one line to
`<doneFolder>/README.md` — `- YYYY-MM-DD — <task> — <outcome>. <prose>`, em
dashes, one physical line, newest last.

### d) Build the archive

One zip per run, written **inside the run folder** as
`<doneFolder>/<date>_<task>/<task-name>-<YYYY-MM-DD>.zip`, left untracked.

```
├── README.md              what this run did, and what is in here
├── code-changes.diff      the full diff of this run's commits
├── run/                   00-PROMPT … 05-HANDOFF, plus RESUME.md if one existed
├── docs/                  every map or flowchart created or changed
└── backups/               any backup this run took, if any
```

`README.md` is written for the user, not a machine: what the run did in plain
English, what is in each folder, and anything he has to do himself. If nothing
under `docs/` changed, say so rather than shipping an empty folder.

### e) Log to the shared history

One row, to the shared Supabase notebook, so other projects can learn from this
run. See "The shared history" below for the command and the fields.

**This step never blocks the run.** If the keys are missing or the request fails,
note it in one line in the report and carry on. A missed row is not worth failing
Phase 5 over. **Never write a secret value into it.**

### f) Push

**Now push**, unless `push: false` in the config. Committing was a rollback
marker; this is the deployment.

### g) Delete `RESUME.md` — last

A finished run leaves no resume file: a stale one tells a later session that work
was interrupted when it was not. It is already in the archive as a record. Keep
it only when a run stops early. Commit the deletion and push it.

### h) Report Phase 5's own cost

Append to `04-REPORT.md` under its own heading: Phase 5's wall time and tool-call
count separately from the rest of the run, how many documents were updated, the
archive's size, and a line telling the user to run `/cost` and note the figure.
Say plainly this is an estimate, not a controlled measurement.

---

## The shared history

One Supabase table, `build_runs`, shared by every project with this plugin
installed. It is **append-and-read only** — the database itself has no update or
delete policy, so a past entry cannot be edited or removed, by you or by anyone.

Credentials come from `BUILD_TASK_SUPABASE_URL` and `BUILD_TASK_SUPABASE_KEY`, or
from `~/.claude/build-task/env`. If neither exists, say so once and continue
without it — the procedure still works, it just doesn't remember across projects.

**Read (Phase 0)** — most recent runs, or a keyword search:

```bash
curl -sS "$BUILD_TASK_SUPABASE_URL/rest/v1/build_runs?select=repo,task,run_date,verdict,contradictions,lessons,landmines&order=logged_at.desc&limit=25" \
  -H "apikey: $BUILD_TASK_SUPABASE_KEY" -H "Authorization: Bearer $BUILD_TASK_SUPABASE_KEY"
```

Add `&or=(lessons.cs.{"term"},landmines.cs.{"term"})` or `&repo=eq.owner/name` to
narrow it. The helper `scripts/history.sh` beside this file does the same thing.

**Write (Phase 5)** — one row, via `scripts/log-run.sh`, or directly:

```bash
curl -sS -X POST "$BUILD_TASK_SUPABASE_URL/rest/v1/build_runs" \
  -H "apikey: $BUILD_TASK_SUPABASE_KEY" -H "Authorization: Bearer $BUILD_TASK_SUPABASE_KEY" \
  -H "Content-Type: application/json" -H "Prefer: return=minimal" \
  -d '{"repo":"...","task":"...","run_date":"YYYY-MM-DD","verdict":"feasible",
       "phases_completed":["0","1","2","3","4","5"],"small_mode":false,"browser":false,
       "effort_signal":"none","cost_usd":null,"files_changed":3,
       "contradictions":"one or two lines, or null",
       "lessons":["at most three short lines"],
       "landmines":["fragile things noticed and not touched"]}'
```

`cost_usd` is a rough estimate and may be null — this is for spotting trends, not
for accounting. `lessons` and `landmines` are the parts another project reads
back, so write them as something a stranger could act on, not as private
shorthand.

## Note for whoever edits this skill later

Do not add instructions like "double-check your work" or "add a final
verification step". The model already self-verifies; those lines cause
over-verification and burn tokens for no gain. Phase 2's external check and Phase
3's independent review replace them, precisely because they are *not* the model
re-checking itself.

Length here is charged repeatedly. Background and evidence belong in
`reference.md`, which is read once and only when needed.
