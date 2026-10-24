# Phases 4 and 5 (general)

Start only when `02-CHECK.md` and `03-REVIEW.md` both pass — or when two failed
rounds stopped the run: then Phase 4 reports the failure plainly, Phase 5 does
only (c) and (d), and the folder stays in `active/`. The user decides: fix,
restore from `backups/`, or accept.

Read the settings first: `bash <v2>/settings.sh` (`<v2>` as defined in SKILL.md).

## Phase 4 — Report

**`04-REPORT.md`**, printed in chat if `printReport` is on. Written per
`user.md`, or plain English. Reasons, not only conclusions. A Mermaid diagram
when it explains how something works.

1. What was asked — one line, in the user's words
2. **How I read it** — one line, and anything assumed
3. What was done, and where the outputs are
4. **Evidence** — the check and its deciding result, **quoted verbatim from
   `02-CHECK.md`**
5. **Independent review** — pass or fail, and any problem it found
6. **How risky this was, and what protected it** — level, the driving
   dimensions, the safeguards that ran
7. **What contradicted what you believed** — own heading, always
8. **Anything added beyond the ask** — for each amber: keep or remove?
9. **Noticed, not done** — `CHECKLIST.md`'s *Not in this task*, or "none"
10. **What you need to do** — every step the agent must not take itself (buy,
    send, book), exactly; and what could not be checked from here
11. **Effort signal** — did any phase skip something, not run its check, or stop
    partway? Report only.
12. `browser: yes` → end by suggesting `/compact`.

If `handoff` is on, add `## Technical handoff`: outputs (full path, one line
each), sources used, verified vs assumed, the reusable check, what is left
undone. **No secrets anywhere.**

## Phase 5 — Close out

Every step is safe to repeat. Note the run's start time from `RESUME.md` first.

**a) Living notes.** Apply `01-FINDINGS.md`'s *Notes updates* and this run's
results to the project's living notes, each change marked with the date; mark
superseded facts `~~old~~ **updated <date> — what changed**`, never silently
delete. Back up first. Setting `maps: propose` → write the changes at the end of
`04-REPORT.md` instead. Never skipped.

**b) File the run.** Move the task folder to `agent-runs/done/` and append to
`agent-runs/README.md`:
`- YYYY-MM-DD — <task> — <outcome>. <one sentence of plain English>`

**c) Shared history** (if `history` is on), from the project root:

```bash
bash <v2>/log-run.sh --task <task> --verdict feasible \
  --phases 0,1,2,3,4,5 --browser no --effort-signal none \
  [--contradictions "..."] [--lesson "..."] [--landmine "..."]
```

Lessons name the situation, what happened, and what to do instead — useful to
another project. Never a secret or anything private about the user.

**d) Risk log** — append one line:

```bash
jq -nc --arg date "$(date +%F)" --arg repo "$(basename "$PWD")" --arg task <task> \
  --arg kind general --argjson risk "$(bash <v2>/risk-score.sh --json B R K T G D)" \
  --arg outcome "<pass|fail>" '{date:$date,repo:$repo,task:$task,kind:$kind,risk:$risk,outcome:$outcome}' \
  >> ~/.claude/build-task/risk-log.jsonl
```

**e) Git repo only** — commit (a) and (b); push per the `push` setting, only if
check and review both passed.

**f)** Delete `RESUME.md` last.

**g) Cost** (if `costSection` is on) —
`bash <v2>/run-cost.sh --since <run start>`, appended to
`04-REPORT.md`.
