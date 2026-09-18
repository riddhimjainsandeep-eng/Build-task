# build-task-fast — what differs, and why

The rationale for the procedure itself is in `../build-task/reference.md`. This
file covers only what the fast variant changes. Nothing here removes a phase, a
check or a rule; each change alters *how* the work is done.

## Phase 3 runs alongside Phase 2

Phase 3 reads only the goal and the diff, and both exist the moment Phase 1
commits. Nothing Phase 2 learns may reach the reviewer anyway, so waiting bought
only wall time. The one real dependency — Phase 2 prompting a code fix — is
covered by the rule that a review counts only for the commit it names.

## Check output goes to a log file

`02-CHECK.md` still holds the real deciding lines verbatim. The full output stays
on disk and in the archive, instead of riding along in context for every later
turn.

## Phases 4–5 live in a separate file

`SKILL.md` is in context on every turn once loaded. A run that stops at
`blocked` or `needs a decision` never needs the close-out rules, and a full run
doesn't need them while exploring or implementing.

## One report file

`04-REPORT.md` holds the user report and, below it, the technical handoff that
used to be `05-HANDOFF.md`. Same nine items, same audiences; only the user part
is printed in chat.

## Close-out is a script

Steps (c)–(g) were about ten tool calls, each re-sending the whole context. The
script does them in one, in the same order, and is idempotent so a resume reruns
it. Two things it adds that the manual steps lacked:

- **No duplicate history rows.** The shared table is append-only, so a resumed
  Phase 5 that logged twice could never be cleaned up. `log-run.sh` here checks
  for the repo/task/date first.
- **Windows `jq` output is stripped of `\r`**, which otherwise corrupts config
  values like `doneFolder`.

`scripts/test-close-out.sh` covers a full run, a rerun, a resume, `push: false`,
a custom `doneFolder` and a missing history config — against a throwaway repo and
a fake history server, never the real ones.
