# Risk rubric — read by Phase 0

Each dimension scores **1, 2 or 3**, judged by *what happens if this change is
wrong*. Every score cites evidence from `01-FINDINGS.md`. **No evidence → 3.**
Size of the diff is never a factor: one line can break everything.

| Dimension | 1 | 2 | 3 |
|---|---|---|---|
| **B — Blast radius**: what breaks if wrong | One place: a single screen, component or function | Several places in one feature (≈2–10 uses) | Many features, every user or request, or saved data |
| **R — Reversibility**: does `git revert` undo it all? | Yes, completely | Code reverts but something lingers — a cache, stored settings, something users saw | No — data written or deleted, an outside service called, a live file run |
| **K — Knowledge**: how well is this area known? | Map exists, needed claims `[v]`, code follows a known pattern | Map partial, or claims were `[?]` and checked only now | No map, map proved wrong, or a pattern or library new to the project |
| **T — Traceability**: are all connections found? | Every use found through types, imports or the language server | Found by text search only; could hide a miss | Hidden: string-built names, config wiring, other languages, generated code |
| **G — Goal clarity** | The prompt states exactly what done looks like | Needs some interpretation | Vague or has several reasonable readings |
| **D — Detectability**: if wrong, would anything notice? | Tests cover it, the build fails, or a screenshot shows it plainly | Only a manual look, or partial tests | Would fail silently — a wrong number, date or background job; no tests |

## The arithmetic

```
Impact  = B × R                 (1–9)
Chance  = (K + T + G) / 3       (1–3)
Escape  = D                     (1–3)
Score   = Impact × Chance × Escape    (1–81)
Level   = Low ≤ 6 · Mid 7–20 · High > 20
```

Risks multiply, so several mid scores compound; one high score alone does not
force High. Compute with `scripts/risk-score.sh B R K T G D` — never by hand.

The bands are a starting calibration. Phase 5 logs every score with its outcome
so the bands can be tuned from real runs, not opinion.

## What the score switches on

The **level** sets Phase 3's model: Low/Mid `sonnet`, High `opus`.

**Each dimension switches on its own safeguard** — at the score shown or above:

| Dimension | At 2 | At 3 |
|---|---|---|
| B | Findings list every caller; Phase 2 runs the callers' tests | Also: Phase 3 told blast radius is high; security review |
| R | Phase 1 states the undo command in the report | Back up before editing; security review |
| K | Phase 1 confirms each `inferred` claim before use | Phase 5 must update or create the map for this system |
| T | Phase 1 re-runs the reference search after editing | Also: search strings and config for the names, not only code references |
| G | Phase 1 writes its reading of the goal as the first line of the commit | `needs a decision` — ask the user before building |
| D | Phase 1 adds a test for the changed logic | Test written **first**: fails before the fix, passes after |

Safeguards only add work. None is ever skipped because the overall level is low.

## RISK.md format

```
Score: 15 — MID   (Impact 3 × Chance 1.67 × Escape 3)
B 3 — formatDate used in 38 places (findings #3)
R 1 — code only; git revert restores it
K 2 — map claim #12 was [?], verified today (findings #9)
T 2 — found by grep; 2 calls build the name from a string (findings #5)
G 1 — prompt gives the exact expected output
D 3 — no test covers formatDate (findings #7)
Phase 3 model: sonnet
Safeguards: list all 38 callers · run callers' tests · re-run reference search after edit · test first (fails, then passes)
```
