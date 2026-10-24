# Risk rubric (general) — read by Phase 0

Same six letters and arithmetic as v2, so `<scripts>/risk-score.sh`
computes it. Each scores **1, 2 or 3** by *what happens if the result is wrong*,
citing evidence from `01-FINDINGS.md`. **No evidence → 3.**

| Dimension | 1 | 2 | 3 |
|---|---|---|---|
| **B — Reach**: what a wrong result affects | One small thing, easily ignored | A decision the user will act on, or several outputs | Money, health, safety, other people, or a note many later decisions build on |
| **R — Reversibility** | Only new files | An existing file changed (backup restores it), or advice the user may already act on | Something outside the project — money spent, a message sent, anything deleted without a copy |
| **K — Knowledge** | Rests on the user's own data or a measured fact, or established sources | Partly sourced, partly inferred | No source, sources disagree, or a field new to this project |
| **T — Completeness**: were all the inputs found? | Every relevant file and fact found and read | Found by search; one could be missing | Inputs in photos or videos not fully seen, or facts only the user knows |
| **G — Goal clarity** | `Your words` state exactly what done looks like | Needs some interpretation | Vague, or several readings give different results |
| **D — Detectability**: would a wrong result be noticed? | Plainly — a script fails, an image looks wrong, a rule is broken | Only on a careful look | Silently — a wrong number, a misremembered fact, plausible advice |

```
Score = (B × R) × ((K + T + G) / 3) × D      Low ≤ 6 · Mid 7–20 · High > 20
```

The level picks Phase 3's model: Low/Mid `sonnet`, High `opus`.

## What each dimension switches on

| | At 2 | At 3 |
|---|---|---|
| B | Findings list everything that relies on this; Phase 2 re-checks it | Also: Phase 3 told reach is high |
| R | Back up every changed file (always, without git) | Nothing irreversible is done by the agent; the report gives the user the exact step |
| K | Confirm each `inferred` claim before use | Every fact in the output carries its source or is labelled an estimate, with how it was made |
| T | Search for inputs again after Phase 1 | List what could not be seen; a missing fact that decides the result is `needs a decision` |
| G | Phase 1's first line restates the goal it works to | `needs a decision` — ask before doing |
| D | Phase 2 recomputes every number independently | The check is run on a case with a known answer first, and must get it right |

Safeguards only add work; none is skipped because the level is low.

## RISK.md format

```
Score: 20 — MID   (Impact 4 × Chance 1.67 × Escape 3)
B 2 — the palette decides what gets bought (findings #4)
R 2 — PROFILE.md is edited; backed up
K 1 — skin tone measured from the test photo (findings #2)
T 2 — found by listing the folder; video frames not all viewed
G 2 — "suits me" needs interpreting
D 3 — a wrong colour call would look plausible
Phase 3 model: sonnet
Safeguards: list what relies on the palette · backup · re-search inputs · recompute numbers · run on a known case first
```
