# build-task-v2 — what differs from v1, and why

The rationale for the procedure itself is in `../build-task/reference.md`. This
file covers only what v2 changes. v1 (`build-task`, `/build`) is untouched and
stays the default.

## The rule above every rule

The user writes most of his code himself and uses this procedure to repair and
extend it; code written well is the goal. Early cost ideas — narrower reading,
stopping once a dimension looked safe, pulling fewer history rows, Sonnet for
implementation — each saved tokens by shrinking what the agent sees. That is a
quality cut dressed as a saving, so v2 states the rule first: only waste may be
cut.

## Where the tokens actually went (measured, not estimated)

21 real sessions across CAprep, Notebook digitalizer, pomodoro and Rapid revision,
34 Phase 0 and 31 Phase 3 subagents:

| Part | Median per run | Share of re-read tokens |
|---|---|---|
| Phase 0 (Opus) | 17 turns · 118k new · 1.5M re-read | ~10% |
| Phase 3 (Sonnet) | 9 turns · 100k new · 0.6M re-read | ~5% |
| Main session | 154 turns · 25.7M re-read per session | ~86% |

Main-session turns re-sent 100k–226k tokens each, because sessions held several
tasks. Every subagent paid 57k–130k before doing any work (system prompt, tools,
plugin injections). Both are waste; neither touches quality — hence the
fresh-session recommendation in `/build-v2`, and nothing in v2 narrows reading.

## Risk instead of size

v1 decided "small mode" from line count at Phase 4 — after the expensive phases
had run, and on a measure that misses the point: one line in a shared helper can
break forty screens. v2 scores six dimensions from evidence and multiplies them,
because risks compound: Impact (B×R) × Chance ((K+T+G)/3) × Escape (D). One high
dimension alone does not force High; several together do. Missing evidence
scores 3, so ignorance is never rated safe. `risk-score.sh` does the arithmetic so
it is never done by hand.

Each dimension switches on its own safeguard, so a Low overall still gets, for
example, the test-first rule when detectability is 3. The level only picks the
reviewer's model. Implementation stays on Opus at every level.

The bands (≤6, 7–20, >20) are a starting calibration. Every run's score and
outcome go to `~/.claude/build-task/risk-log.jsonl`; tune the bands from runs
rated Low that failed, never from opinion.

## Phase 0

- **Writes `RISK.md` too.** It is the only phase that has just read everything;
  every later phase reads ten lines instead of the findings.
- **No ledger edits.** v1 told Phase 0 that `01-FINDINGS.md` was the only file it
  could write *and* to fix marks in `CLAUDE-RULES.md` — impossible together. v2
  records them under Ledger updates; Phase 5(b) applies them in the same run.
- **Stops only when every dimension has evidence**, not merely when three
  questions have answers — the reading scales with what the risk needs.
- **Disprove, label, name the gaps.** Each conclusion is tested against what
  would prove it wrong; every claim is `read` or `inferred`; blind spots are
  listed. Same reading, fewer confident mistakes.

## Phase 2

- **Runs Phase 0's check first, unchanged.** The check is fixed before code
  exists, so it cannot be swapped for an easier one afterwards.
- **Callers' tests when blast radius is 2+.** Proving the new thing works is not
  proving the old things still do.
- **Failure has a path:** back to Phase 1, at most two rounds, then stop and tell
  the user. v1 was silent here.
- **Test or local data store** unless the config names the live one safe.
- **Full log read on any failure or surprise** — the tail is for passing runs.

## Phase 3

- **The prompt file verbatim**, never a paraphrase — a paraphrase leaks the
  implementer's reading into the "independent" review.
- **Commit messages included,** so "was a change of method declared" is
  answerable (v1 asked it of a reviewer that could not see the declaration).
- **May read the code, never the reasoning.** Independence is about withholding
  the implementer's thinking, not the codebase.
- **Question 4 — correctness:** any input or state where the diff does the wrong
  thing. v1 had no independent correctness check at all.
- **Outcomes act:** fail loops back, red is removed, amber goes to the user.
- **Model and security review follow the score,** not a category list.

## Phases 4 and 5

- **No size-based small mode.** What the report contains follows settings; how
  carefully it is written never changes.
- **Evidence quoted verbatim, review verdict and risk shown** — the report is the
  user's code review, so it cannot be rosier than `02-CHECK.md`.
- **Push only after both passes.** v1's Phase 5 pushed regardless.
- **A failed run is held, not closed.** Moving it to `done/` would leave its
  commits unpushed on the branch, where the next run's push would ship them.
- **Cost is measured** from the transcript (`run-cost.sh`), not estimated.

## Settings

`settings.sh` merges global and project settings. Everything a setting touches
is either the user's own output (zip, handoff, cost section, printing) or a
decision that is genuinely his (push, whether maps and rules are applied or only
proposed, shared history). Phases, checks, the review and commits are not
settings. v1's `push: false` still means never.

## Tests

`scripts/test-v2.sh` — risk arithmetic and its band edges, settings merging and
validation, cost measurement against a synthetic transcript, and close-out: a
failed run held, a passing run, a rerun, `ask`/`never`, zip and history off, and
refused bad input. Throwaway repos and a fake history server only.
