# Phases 4 and 5 — report, close out

Start only when `02-CHECK.md` and `03-REVIEW.md` both name `HEAD` and both pass — or when
two failed rounds stopped the run. Then the report says so plainly, and Phase 5 runs only
the close-out script, which **holds**: nothing is moved or pushed. Tell the user the
commits are local only, that a later push would ship them, and that they decide: fix,
revert (`git revert --no-edit <base>..HEAD`), or accept.

Read the settings first: `bt settings`.

## Phase 4 — Report, in chat

Write the report **in chat**, plain language for the person in `user.md`, no code. Explain
an unavoidable technical word right below it. Include each item below **only when it has
something to say** — a quiet run reads in about ten lines, a busy one is as long as it
needs:

1. What was asked — one line · 2. What was done, with reasons
3. **Evidence** — the check command and its deciding output, quoted from `02-CHECK.md`
4. **Independent review** — pass or fail, and any correctness issue it found
5. **Risk** — the level, the dimension(s) that drove it, the safeguards that ran
6. **What contradicted what you believed** (always present; "nothing" if so)
7. **Added beyond the ask** — each amber: ask "keep or remove?"
8. **Other bugs found, not fixed** — one line each with where it shows up
9. **What could not be checked from here** — the exact steps
10. **Plan changes** — each minor change; anything **skipped by agreement**, said plainly
11. **Severe changes made while you were away** (AFK) — each with its restore line
12. **Effort signal** — did any phase skip a file, not run its check, or stop partway?
13. `browser: yes` → end by telling the user to `/compact`

Then save the same text: pipe it into `bt report <task-dir>`. No other report file.
**No secrets** anywhere — names are fine, values never.

## Phase 5 — Close out

Every step is safe to repeat.

**a) Cards.** `bt index stale --since <base>` lists the cards whose files this run changed.
Rewrite only the lines of those cards that this run proved wrong or incomplete — what it
does, files, tables, connections, symptoms, watch-outs. A gap the run hit (code no card
covered, a search that missed) → add the missing words or a new card. Knowledge scored 3 →
the card for this system **must** be updated or created. Then mark every card `stale`
listed as checked against today's code — `bt index checked <slug …>` (this clears its
`CHANGED` flag; never mark a card you did not compare with the code) — and run
`bt index build` (it refuses a card that looks like it holds a secret). Maps are not edited.

**b) Rules file and ledger.** Apply `01-FINDINGS.md`'s *Ledger updates* to
`docs/CLAUDE-RULES.md`. In `CLAUDE.md`: correct what this run proved wrong; add only what a
future run would get wrong without it; pay for any addition by tightening something else;
never remove a rule; mark superseded facts `~~old~~ **RESOLVED <date> — what changed.**`
Setting `rulesFile: propose` → put the proposal in the report instead.

**Commit (a) and (b).**

**c)–g) The close-out script.** Note the run's start time from `RESUME.md` first (step g
deletes it). If `zip` is on, write the archive README to a temp file outside the repo.

```bash
bt close --task-dir <taskFolder>/<date>_<task> --task <task> --base <base commit> \
  --outcome "<outcome>. <prose>" [--readme <temp README>] [--backups <dir>] \
  --check pass|fail --review pass|fail [--push-approved] \
  --risk "B R K T G D" --rounds <failed rounds, 0–2> \
  -- --verdict feasible --phases 0,1,2,3,4,5 --browser no --effort-signal none \
     [--files-changed N] [--contradictions "..."] [--lesson "..."] [--landmine "..."]
```

It moves the folder to `<doneFolder>/`, logs the run, zips (if on), writes one shared
history row (if on), pushes **only if check and review both passed** and per the `push`
setting (`auto` / `ask` → rerun with `--push-approved` after the user's yes / `never`),
and deletes `RESUME.md`. AFK: pushing follows the decision made when AFK started; nobody
decided → hold. A step printing `FAILED` → do it by hand, then rerun.

`lessons` and `landmines` are what other projects read back: the situation, what happened,
what to do instead. Never a secret value.

**h) Cost** (if `costSection` is on): `bt cost --since <run start>` and
`bt cost --since <Phase 5 start>`; add both lines to the end of the chat report and to
`04-REPORT.md`.
