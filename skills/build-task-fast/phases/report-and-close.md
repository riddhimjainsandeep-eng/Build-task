# Phases 4 and 5

Read this only once `03-REVIEW.md` names `HEAD`.

## Phase 4 — Report

Write **one file, `04-REPORT.md`**: the user report first, then a
`## Technical handoff` section (what used to be `05-HANDOFF.md` — where a
project's `user.md` mentions that file, it means this section). Print only the
user report in chat.

**Small mode is decided here, by the system, not by the user.** Measure the real
diff: **under roughly 20 lines and touching no data, schema or logic** → the
technical handoff may be short. Otherwise write it in full. Borderline counts as
not small. **Say which mode you chose and why, in one line, in the report and in
chat.** Nothing earlier is ever shortened, `RESUME.md` included.

### User report

Plain English, per `user.md`. No code, no file paths. Where a technical word is
unavoidable, explain it immediately below that paragraph, never in a glossary at
the end. Give the reasoning, not just the conclusion — what the alternative was
and why you did not take it.

**If the report explains how something works, draw it** — a small Mermaid diagram
in the report, and when it is worth keeping, a numbered file in
`<docsRoot>/flowcharts/`.

1. What was asked — one line
2. What was done
3. Evidence — the command and what it returned
4. **What contradicted what you believed** — own heading, always present
5. Anything added beyond the ask — green/amber/red with your reasoning
6. What could not be checked from here — exact steps, or "nothing"
7. **Effort signal** — own heading, always present. Did any phase skip a file it
   should have read, not run its check, or stop partway? One line; if nothing of
   the kind happened, say that. Report the signal only — never raise, lower or
   recommend an effort level.
8. `browser: yes` or `no`, and which report mode was used. If `yes`, close by
   telling the user to `/compact` before continuing.

### Technical handoff

For a reader who has never seen this repo and never will. Dense and factual, no
narrative; precision over readability.

1. Files changed — full path, one line each
2. New or changed functions and routes — exact names, what they take and return
3. Data changes — table, columns, types, migrations actually run
4. Verified vs assumed — split explicitly, label anything unverified
5. Corrections to reality — every place the codebase contradicted the prompt file
6. Conventions observed
7. Landmines — anything fragile noticed and deliberately not touched
8. The reusable check — command and output
9. Left undone — deliberate omissions, known limits, open threads

**NO SECRETS** anywhere in the file — it gets pasted into chat windows. Names are
fine; values of keys, tokens, connection strings or `.env` entries never are.

Phase 5 appends its cost section at the end.

---

## Phase 5 — Close out

Mechanical, and most likely to be dropped when a session ends early. Do (a) to
(h) in order; every step is safe to repeat, so a resume starts again at (a).

### a) Documents

Update every map this run made wrong, under `<docsRoot>/`, with a dated changelog
line. No map existed for the system this task worked on → create one from what
Phase 0 established.

- **Only the parts you actually verified this session.** Never rewrite a whole map
  from a partial view.
- **Never touch the map of a system this task only brushed past.**
- **A map is a hypothesis; on conflict the code is right.**

`<docsRoot>/flowcharts/` holds every plain-language diagram, one per file,
numbered. A task that produces or invalidates one puts it there with the next
number and adds its line to that folder's README.

**"No map changes required" is a real answer.**

### b) The rules file, with a budget

`CLAUDE.md` is loaded on every turn of every session.

- **Correct** what this run *proved* wrong, with this run's evidence.
- **Add** only what a future run would get wrong without it.
- **Anything added must be paid for** by tightening or merging something else; if
  it genuinely cannot be, add it and flag that in the report.
- **Never remove a rule** to make room — tighten wording, merge duplicates, cut
  explanation, never instructions.
- Superseded facts: `~~the old claim~~ **RESOLVED <date> — what changed.**`
- **"No `CLAUDE.md` changes required" is a real answer.**

**`docs/CLAUDE-RULES.md` is the inventory.** If this run changed `CLAUDE.md`, or
verified or disproved any claim, update it in the same commit.

**Commit (a) and (b) before running the script below.**

### c)–g) The close-out script

Write the archive's `README.md` first, to a temporary file **outside the repo** —
for the user, plain English per `user.md`: what the run did, what is in each
archive folder, anything he has to do himself, and "no docs changed" if none did.

Then one call, from the repo root:

```bash
bash "<this skill's folder>/scripts/close-out.sh" \
  --task-dir <taskFolder>/<date>_<task> --task <task> --base <base commit> \
  --readme <temp README> --outcome "<outcome>. <prose>" \
  [--backups <dir>] \
  -- --verdict feasible --phases 0,1,2,3,4,5 --browser no --effort-signal none \
     [--small-mode] [--cost-usd N] [--files-changed N] \
     [--contradictions "..."] [--lesson "..."] [--landmine "..."]
```

Everything after `--` goes to `log-run.sh` unchanged. `lessons` and `landmines`
are what another project reads back — write them so a stranger could act on them.
**Never put a secret value in any field.**

It does, in order, printing one line per step:

- **c)** move the folder to `<doneFolder>/`, append
  `- YYYY-MM-DD — <task> — <outcome>` (one physical line, newest last) to
  `<doneFolder>/README.md`, commit
- **d)** build `<task>-<date>.zip` inside the run folder, left untracked:
  `README.md`, `code-changes.diff` (`<base>..HEAD`), `run/` (phase files and
  `RESUME.md`), `docs/` (maps and flowcharts changed under `<docsRoot>`),
  `backups/`
- **e)** log one row to the shared history — skipped if this repo/task/date is
  already there. **Never blocks the run:** a warning here goes into the report as
  one line, and close-out carries on
- **f)** push, unless `push: false` in the config
- **g)** delete `RESUME.md` **last**, commit, push

A step that prints `FAILED` → do it by hand, then rerun the script; it skips what
is already done.

### h) Report Phase 5's own cost

Append to `04-REPORT.md` under its own heading: Phase 5's wall time and tool-call
count separately from the rest of the run, how many documents were updated, the
archive's size, and a line telling the user to run `/cost` and note the figure.
Say plainly this is an estimate, not a controlled measurement.
