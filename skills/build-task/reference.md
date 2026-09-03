# build-task — background and evidence

Everything here is *why*, not *what to do*. `SKILL.md` carries the rules and is
charged on every turn; this file is charged only when someone opens it. Read it
when editing the procedure, when a rule looks arbitrary, or when you are about to
re-propose something that was already tried and rejected.

---

## Why the procedure exists at all

The user is not a coder. He cannot read the code, cannot spot a stub, and cannot
tell a passing check from a plausible-sounding sentence. The six phases are the
substitute for the code review he cannot perform: Phase 0 makes the agent state
what it believes *before* editing, Phase 2 makes an external system answer, and
Phase 3 lets a reader who never saw the reasoning judge the result.

This is also why every phase writes a file. A file is checkable later; a claim in
chat scrolls away.

## Why `RESUME.md` is written continuously

A run gets no warning that it is about to end. Writing the file only "when
stopping" would mean never writing it in the cases that matter — a usage limit, a
power cut, a closed laptop. Written at every boundary it costs a few lines and
covers all three identically.

## Why the verification rule is progressive rather than all-at-once

The obvious design is to verify every claim in `CLAUDE.md` against the code the
moment the plugin is installed. On a large project that is the most expensive
thing the system would ever do, and most of it would be wasted: the majority of
claims are about parts no upcoming task will touch.

The rule in `SKILL.md` splits it. Setup verifies the **structural** claims —
does this file exist, does this route exist, does this table exist — because
those are mechanical, bounded, and the ones most likely to have rotted. Every
task afterwards verifies the claims it is actually about to rely on, and marks
them. The result converges on the same place as full verification, spends the
cost only where it buys something, and never lets a task act on an unverified
belief. `[?]` is not a soft warning: it means *stop and check this one thing
first*.

## Why each phase gets the model it gets

| Phase | Model | Why |
|---|---|---|
| 0 — Explore | opus, on the dispatch | Ambiguous, unfamiliar code; needs recognition of patterns not present in the repo. The clearest case for the larger model |
| 1 — Implement | inherits the session | Touches live code and makes design calls |
| 2 — Prove | inherits the session | The commands are mechanical, but the browser half is not — a past run screenshotted a page containing neither element it had just edited, and catching that took judgment |
| 3 — Review | sonnet, on the dispatch | One narrow, well-specified question against a diff |
| 4 — Report | inherits the session | Two documents written from what already happened. Writing quality matters; deep reasoning does not |
| 5 — Close out | inherits the session | Mechanical: docs, archive, move, log, push |

## What the effort levels are for, so nobody guesses

- `max` — absolute maximum capability, no constraint on token spend
- `xhigh` — long-horizon work: agentic tasks running over 30 minutes with token
  budgets in the millions. **Not** a general "try harder" setting
- `high` — the default. Complex reasoning, difficult coding, agentic tasks
- `medium` — balanced, moderate savings
- `low` — most efficient; subagents are the typical case

Effort affects all tokens, not just thinking. At lower levels the model makes
fewer tool calls, combines operations, and goes straight to action; at higher
levels it reads more, verifies more, and explains its plan first.

Model and effort fix different failures. Had the context, clearly tried, still
wrong → larger model. Skipped a file, didn't run the tests, bailed partway →
higher effort. Neither fixes a context or prompt problem, which is the usual real
cause.

## Why Phase 0's subagent writes its own findings file

Handing the file back through the main session wastes a round-trip and has
already introduced mis-cited line numbers once. It also doubles the cost: the
findings would sit in the subagent's output *and* in the main session's context.

## Why Phase 0 stops early and stays short

Reading past the three answers is procrastination, not thoroughness. And a
findings file needing more than ten citations is a scoping signal: the task is too
big and should be split, not explored harder.

## Why Phase 1 opens by naming the findings

A claim the user can check beats an instruction he has to trust. If the agent
cannot name in two lines what it is building against, it did not read the file —
and that is visible to a non-coder in a way that bad code is not.

## Why Phase 2 must run something external

The model already checks its own reasoning, so a phase that asked it to check
again would buy nothing. The reasoning can be flawless and still be wrong about
what the real system does. Only an external answer — an exit code, a real row, a
screenshot — carries information the model did not already have.

### The worked example of a "you must check this yourself" instruction

Some things genuinely cannot be tested from a coding session — push
notifications, home-screen behaviour, hardware. The instruction that replaces the
check must be followable in under a minute:

> Open the app from the iPad home screen → Settings → tap Enable Notifications →
> expect a test push within 10 seconds. If nothing arrives, send me the console
> output.

Screen named, tap named, expected result named, failure path named. "Verify it
yourself" is not a substitute.

## Why Phase 3 sees only the goal and the diff

The agent that wrote the code knows what it meant and reads that intent back into
its own work. A reader with only the goal and the result sees the gap. Give it the
reasoning and it stops being an independent reader.

## Why small mode is decided by the system, not typed by the user

A separate `/small-build` command would ask the user to judge the size of a change
before it exists — which is precisely the judgment he cannot make, and the whole
reason this procedure exists. So the system measures the real diff at Phase 4 and
decides. It must still *announce* the call: the user should be able to disagree
with a decision he can see, and the failure mode worth catching is a run quietly
shortening its own reporting.

Borderline counts as not small, because the cost of writing the extra file is a
few hundred tokens and the cost of missing a handoff is a future session starting
blind.

## Why close-out is its own phase

Phase 4 used to do two unrelated jobs: writing up what happened, and the
housekeeping afterwards. Splitting them buys two things, neither of them tidiness.

Close-out is mechanical, so it is the obvious candidate for a cheaper model the
moment a non-dispatched phase can carry one. And close-out is what gets dropped
when a session ends early — buried inside Phase 4, a run that had written
`04-REPORT.md` looked finished. As its own phase with no output file of its own,
the outstanding work is visible: the folder is still in `agent-runs/active/`, or
`RESUME.md` is still there.

## Why the `CLAUDE.md` budget rule exists

`CLAUDE.md` is loaded on every turn of every session, so a line added there is
paid for forever. Grown unchecked, one such file reached seventeen internal
contradictions before it was trimmed. The budget — anything added is paid for by
tightening something else, and no rule is ever removed to make room — is what
stops that recurring.

`docs/CLAUDE-RULES.md` exists because "nothing was removed" was previously an
impression rather than a fact. It now does double duty as the verification
ledger.

## Why the shared history is append-only at the database level

The user asked for cross-project memory that is "strictly read-only, no edit".
That could have been an instruction in this file. Instead the Supabase table has
an insert policy and a select policy and **no update or delete policy**, so the
constraint is enforced by the database rather than by a rule a session might
reason its way around. An instruction is a hope; a missing policy is a wall.

The cost of that choice: a wrong entry cannot be corrected, only superseded by a
later one. That is the right trade for a log whose value is that it is trustworthy
history.

## Why the shared history holds lessons and not diffs

A row is meant to be read months later by a session working on a different
project. Diffs, file paths and function names do not transfer; "the sync script
runs from the working tree, so an uncommitted edit is live behaviour" does. Hence
`lessons` and `landmines` as short prose lines rather than anything structured —
and hence the rule to write them for a stranger, since a stranger is exactly who
reads them.

It also holds no secrets, ever. The table is reachable by anyone holding the anon
key, and the key sits in a config file on a laptop. Build metadata is an
acceptable thing to keep there. A connection string is not.

---

## What a run actually costs — the patterns worth knowing

Measured on real runs of this procedure. Exact figures vary by project; these are
the shapes, not targets.

- **Long sessions cost disproportionately more, even cached.** Around 70% of usage
  in one measured period came from turns above 150k context. `/clear` between
  unrelated tasks is worth more than any single file trim.
- **A skill file is a real recurring cost** when it is re-charged on every turn of
  every phase — roughly 23% of usage in that same period. Hence keeping `SKILL.md`
  short and pushing rationale into this file, which is read once.
- **An idle connected tool costs almost nothing** — tool search defers schemas, so
  an unused server contributes only its tool names. The real cost of a browser
  tool is its **results**: screenshots and page dumps persist for the rest of the
  session. That is why `browser: no` is a discipline rule and `browser: yes` means
  "as late as possible, then `/compact`".
- **Dispatched subagents are around 14%** — the price of Phases 0 and 3 doing
  their job, and working as intended.

## What cannot be measured, and was checked

- **Usage-limit spend.** No CLI subcommand and no environment variable reports it.
  `~/.claude.json` → `cachedUsageUtilization` holds five-hour and seven-day
  percentages, but it is a client-side cache with a `fetchedAtMs` stamp, refreshed
  on the client's own schedule — not a live counter. Any rule keyed to it would
  read as protection while measuring something stale.
- **Context size from hook stdin.** No hook payload carries context-window size,
  token counts or usage percentage; the *statusline* payload does. That asymmetry
  is why `context-warn.sh` reads `transcript_path` instead: every hook payload
  carries that path, the transcript's last `message.usage` block holds the same
  four token counts the statusline sums, and subagent turns live in their own
  transcript files, so a main-session hook sees the main session's real number
  rather than a mixture.
