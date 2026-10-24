# Why build-task is shaped this way

Read when editing the procedure or when a rule looks arbitrary. Measured on 24 real runs
(6 projects, Sept–Oct 2026) before this version.

**Where usage went:** ~43% after the code was written (proving, fix rounds, report, close —
in the main session), ~19% Phase 0, ~12% review helpers, ~12% writing code, ~10% before the
run. Every step re-sends the whole conversation, so whatever Phases 0–1 read is paid for
again on every later step. Reading less early is the biggest saving; it is why the index
exists and why Phase 2's browser judgement runs in a helper.

**Why an index, and why cards:** one large project's maps were ~190k tokens and were read
whole on every run; its full function list is ~10k tokens and a card is ~200. Finding the
pomodoro-saving code the old way cost ~40–100k tokens; through the index ~1.5–3.5k.
Cards are written per *behaviour* because one behaviour spans many files and people ask
about behaviours, not files.

**Why rewrite the question first:** keyword search matches words, not meaning. On 20 hard
questions, keyword search alone found the complete answer 12 times; with the question first
rewritten into the app's words, 19 times. Automatic spelling correction was tried and
removed — it turned real words into wrong ones (accounts → count).

**Why watch mode:** the index must never be trusted when it is wrong (a fix in the wrong
place). Five right answers in a row per project before trusting it costs a few runs of
savings and risks nothing.

**Why Phases 2 and 3 stay, at full strength:** of 14 logged code runs, 9 had a check or
review round fail and get fixed before the user saw it. The review caught bugs passing
checks missed (old data broken by a new rule; silently wrong answers; a proof that failed on
its second run). A self-check by the author shares the author's blind spots; the reviewer
sees only the user's words and the diff. Skipping review on low-risk tasks would have saved
under 1% (2 of 30 runs were low risk) — not worth any loss.

**Why one script (`bt`):** mechanical steps done by the AI cost tokens on every run and are
less reliable than code. The script is written once.

**Why chat-only reports:** the people this serves read the chat, not files. The text is
still saved to `04-REPORT.md` for the archive; the long technical handoff became the cards.

**Why the plan may change:** the session knows the conversation and the code; a fixed
script cannot. The limits (ask before anything severe; never drop Phase 2/3 alone) exist
because the AI is most tempted to skip a check exactly when it feels confident.

Do not add "double-check your work" lines: they cause over-verification without adding
information. Phase 2's external check and Phase 3's review do that job.
