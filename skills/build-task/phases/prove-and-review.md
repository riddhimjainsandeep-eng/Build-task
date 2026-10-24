# Phases 2 and 3 — prove it works, independent review

Right after Phase 1's commit, **dispatch Phase 3 in the background, then do Phase 2.**
Phase 3 must not see Phase 2's results, so running them together loses nothing. Any code
change after that → commit, redo Phase 2's checks and re-dispatch Phase 3 on the new diff.
Phase 4 starts only when `02-CHECK.md` and `03-REVIEW.md` both name `HEAD` and both pass.

Neither phase is ever skipped on your own judgement. You may recommend skipping one, with
reasons; only the user can agree (`bt plan-change <task-dir> skip-agreed "<why>"`).

## Phase 2 — Prove it works

Run something **external** and report what actually came back. Every command goes through
`bt check <task-dir> -- <command>`: full output to `02-CHECK-output.log`, the exit code and
last 40 lines on screen. A non-zero exit or anything unexpected → read the full log before
judging.

1. **Phase 0's check first, unchanged.** Extra checks may be added; the pre-committed one
   is never replaced.
2. **Saved checks** for every card this task touched: `bt saved-checks <task-dir> <slug …>`
   — catches a new change breaking an old screen.
3. **What the change calls for:**

| Touched | Check |
|---|---|
| Build or config | the build command — note the exit code |
| Data or logic | the tests; query a **test or local** data store and print real rows — the live one only if the config names it safe |
| Blast radius 2+ | also the callers' tests from the findings; no tests for a caller → say so |
| Anything visible (`browser: yes` only, last) | see below |

**Browser checks:**
- **Measurable** (positions, sizes, colours, text present, a flow completing): write a
  small script that drives its own browser (a self-started headless Chrome is fine here),
  save it in the project, run it through `bt check`, and add it to the card's `checks:` line
  so later runs re-run it for free.
- **Judgement** ("looks like the design", "feels smooth"): dispatch a helper that uses
  **Claude in Chrome** (never the headless devtools MCP), saves screenshots into the task
  folder and returns a short verdict. Screenshots never enter the main conversation.

**`02-CHECK.md`:** the commit checked, each exact command, its exit code, the deciding
output lines copied verbatim, the log path, and **pass / fail**.

**A check fails →** back to Phase 1 with the failure, fix, commit, rerun all checks. After
two failed rounds, stop and report — never loop silently, never report a failure as done.
**What cannot be checked from here** (a phone notification, hardware) → steps the user can
follow in under a minute: screen, tap, expected result, what to send if it fails.

## Phase 3 — Independent review

**Dispatch a fresh subagent** — **sonnet** at risk Low/Mid, **opus** at High. Give it:
`00-PROMPT.md` verbatim, the diff `git diff <base>..HEAD`, the commit messages
`git log <base>..HEAD`, the **names** of the dimensions that scored 3, and the full text of
the cards in `Cards used` (shared project knowledge, so it finds callers without exploring
from scratch). It may read any code. It must never see `01-FINDINGS.md`, `RISK.md`'s
evidence, `CHECKLIST.md`, `02-CHECK*` or your reasoning. It writes `03-REVIEW.md` — the only
file it may write, said in its prompt — headed with the commit reviewed, and returns
pass/fail plus any amber, red or correctness items.

1. **Does it achieve the goal** as `Your words` state it? Pass / fail.
2. **Did it add anything beyond the ask?** Green (broken without it) / Amber (separable,
   should have been proposed) / Red (out of scope).
3. **Was any change of method declared** in the commit messages? Information.
4. **Is there any input or state where this diff does the wrong thing?** Name it with the
   line. Any real one is a fail.

Fail on 1 or 4 → back to Phase 1 with the reason, then a fresh review; after two rounds,
stop and report. **Red → removed**, re-checked, re-reviewed. **Amber → the user decides**
in the report. A **security review** also runs when blast radius or reversibility scores 3,
if a security-review tool is available.

**Next: read `phases/report-and-close.md`.**
