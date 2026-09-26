# Phases 4 and 5

Start only when `02-CHECK.md` and `03-REVIEW.md` both name `HEAD` and both pass —
or when two failed rounds stopped the run. Then Phase 4 reports the failure
plainly, and Phase 5 does only (e): the close-out script logs the outcome and
**holds** — the run stays in `<taskFolder>/`, nothing is moved or pushed. Tell the
user its commits are local only, that a later push would ship them, and that he
decides: fix, revert (`git revert --no-edit <base>..HEAD`), or accept.

Read the settings first: `bash <this skill's folder>/scripts/settings.sh`.

## Phase 4 — Report

One file, **`04-REPORT.md`**: the user report, then — if `handoff` is on — a
`## Technical handoff` section (what used to be `05-HANDOFF.md`; a project's
`user.md` that mentions that file means this section). Print the user report in
chat if `printReport` is on. Size of the diff never changes what is written.

### User report

Plain English, per `user.md`. No code, no file paths. Explain an unavoidable
technical word right below its paragraph. Give reasons, not only conclusions. If
it explains how something works, draw it — a small Mermaid diagram.

1. What was asked — one line
2. What was done
3. **Evidence** — the check command and its deciding output, **quoted verbatim
   from `02-CHECK.md`**, never paraphrased
4. **Independent review** — pass or fail on the goal, and any correctness issue
   it found, in plain English
5. **How risky this was, and what protected it** — the risk level, the one or two
   dimensions that drove it, and the safeguards that ran
6. **What contradicted what you believed** — own heading, always
7. **Anything added beyond the ask** — green/amber/red. **For each amber, ask the
   user: keep or remove?**
8. **Other bugs found, not fixed** — `CHECKLIST.md`'s *Not in this task*, each
   one line with where it shows up, so the user can make it its own task; or
   "none"
9. What could not be checked from here — exact steps, or "nothing"
10. **Effort signal** — own heading, always. Did any phase skip a file, not run its
   check, or stop partway? Report only; never recommend an effort level.
11. `browser: yes` or `no`. If `yes`, end by telling the user to `/compact`.

### Technical handoff (if on)

Dense, factual, for a reader who has never seen this repo: files changed (full
path, one line each) · new or changed functions and routes with inputs and
outputs · data changes actually run · verified vs assumed · corrections to
reality · conventions observed · landmines left alone · the reusable check with
its output · left undone.

**NO SECRETS** anywhere in the file. Names are fine; values never are.

---

## Phase 5 — Close out

Do (a) to (h) in order; every step is safe to repeat.

### a) Maps

Update every map this run proved wrong or incomplete, under `<docsRoot>/`, with a
dated changelog line. Knowledge scored 3 → the map for this system **must** be
updated or created. Only the parts verified this run; never a map this task only
brushed past; on conflict the code is right. Diagrams go to
`<docsRoot>/flowcharts/`, numbered, indexed in its README.

Setting `maps: propose` → write the changes as a proposal at the end of
`04-REPORT.md` instead of editing the map. They are never skipped.

### b) Rules file and ledger

Apply `01-FINDINGS.md`'s **Ledger updates** to `docs/CLAUDE-RULES.md`. For
`CLAUDE.md`: correct what this run proved wrong; add only what a future run
would get wrong without it; pay for any addition by tightening something else;
never remove a rule; mark superseded facts
`~~old~~ **RESOLVED <date> — what changed.**`

Setting `rulesFile: propose` → propose `CLAUDE.md` changes in the report instead
of applying them. Ledger marks are always applied — they are facts, not rules.

**Commit (a) and (b).**

### c)–g) The close-out script

**Note the run's start time from `RESUME.md` now, and the time Phase 5 began** —
step (g) deletes the file and (h) needs both.

If `zip` is on, write the archive README first, to a temp file **outside the
repo** — plain English: what the run did, what each archive folder holds,
anything the user must do.

```bash
bash "<this skill's folder>/scripts/close-out.sh" \
  --task-dir <taskFolder>/<date>_<task> --task <task> --base <base commit> \
  --outcome "<outcome>. <prose>" [--readme <temp README>] [--backups <dir>] \
  --check pass|fail --review pass|fail [--push-approved] \
  --risk "B R K T G D" --rounds <failed rounds, 0–2> \
  -- --verdict feasible --phases 0,1,2,3,4,5 --browser no --effort-signal none \
     [--small-mode] [--cost-usd N] [--files-changed N] \
     [--contradictions "..."] [--lesson "..."] [--landmine "..."]
```

It reads the settings itself and prints one line per step:

- **c)** move the folder to `<doneFolder>/`, append the run-log line, commit
- **d)** zip archive — if `zip` is on
- **e)** one row to the shared history — if `history` is on; skipped if already
  logged. Also always appends the risk score and outcome to the local
  calibration log `~/.claude/build-task/risk-log.jsonl`
- **f)** push — **only if check and review both passed**, and then per `push`:
  `auto` pushes; `ask` holds until the user says yes (rerun with
  `--push-approved`); `never` holds
- **g)** delete `RESUME.md` last, commit, push under the same rule

`lessons` and `landmines` are what other projects read back: each names the
situation, what happened, and what to do instead. Never a secret value.

A step printing `FAILED` → do it by hand, then rerun; done steps are skipped.

### h) The run's own cost (if `costSection` is on)

```bash
bash "<this skill's folder>/scripts/run-cost.sh" --since <run start from RESUME.md>
bash "<this skill's folder>/scripts/run-cost.sh" --since <Phase 5 start>
```

Append both lines to `04-REPORT.md` under their own heading. These are measured
from the session transcript, not estimated.
