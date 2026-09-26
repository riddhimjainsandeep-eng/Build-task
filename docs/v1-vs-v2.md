# build-task v1 vs v2

v2 is the default: `/build`, `/build-v2`, and any request to change code run it.
v1 is unchanged and still available as `/build-v1`. v2 is built on one rule: **quality is never
traded for cost — only waste is cut.** Full reasoning:
`skills/build-task-v2/reference.md`.

| | v1 `build-task` | v2 `build-task-v2` |
|---|---|---|
| Instruction tokens, Phases 0–3 | 6,120 | 4,685 (incl. the risk rubric) |
| Extra when Phase 4 starts | 0 | 1,535 (loaded only then) |
| How much care a task gets | Size: "small mode" at Phase 4, by line count | **Risk score** from six evidenced dimensions, at Phase 0 |
| Phase 0 output | `01-FINDINGS.md` | + `RISK.md` + `CHECKLIST.md` (Phase 1 ticks it off); claims labelled read/inferred; blind spots named; checks the running app in Claude in Chrome itself |
| Phase 0 contradiction | "only write findings" *and* "fix CLAUDE-RULES marks" | Marks recorded in findings, applied by Phase 5 |
| Phase 2's check | Any check | **Phase 0's pre-committed check first**; callers' tests when blast radius ≥ 2 |
| Check fails | Unspecified | Back to Phase 1, max two rounds, then stop and tell the user |
| Phase 3 sees | Goal (maybe paraphrased) + diff | Prompt **verbatim** + diff + commit messages; may read code, never reasoning |
| Phase 3 asks | Goal? Extras? Deviation? | + **Is there any input where this is wrong?** |
| Phase 3 model | Always Sonnet | Sonnet, Opus at High risk |
| Phase 2 ↔ 3 | One after the other | Together (reviewer never sees check results anyway) |
| Report | Two files | One file; handoff optional; evidence quoted verbatim; review verdict and risk shown; amber asks you |
| Push | Always, even after a failed review | **Only after check and review pass**, then auto / ask / never |
| Failed run | Closed like any other | **Held** in active — its commits would otherwise ship with the next push |
| Phase 5 steps c–g | ~10 manual tool calls | One script, safe to rerun, no duplicate history rows |
| Cost section | Estimated | Measured from the transcript |
| Settings | Config file by hand | `/build-v2 settings` checkbox menu; global + per project |
| Tests | — | `scripts/test-v2.sh`, 40 checks |

**Measured on 21 real sessions:** the main session is ~86% of all tokens re-read,
at 100k–226k per turn when several tasks share one session. v2's biggest saving
is advising a fresh session per run — which costs no quality at all.
