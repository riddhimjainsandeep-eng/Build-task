---
name: build-setup
description: First-run setup for a project that will use the build-task procedure. Creates the standard folders and documents, reads and verifies CLAUDE.md against the real code, writes the system maps, and asks the user any open questions in writing. Use the first time this plugin is used in a project, when the user asks to set up or initialise a project for build-task, or when build-task reports that a project has never been set up.
---

# Build Setup — first run in a project

This runs **once per project**, before any task work. It leaves
`.build-task-setup` at the repo root as the marker that it has run. If that file
already exists, do not run again unless the user explicitly asks — instead say
when it last ran and offer to re-run.

The user is not a coder. Everything you write here is read by him, not just by a
future session, and every question you ask him has to be answerable without
opening a code file.

## Step 1 — Work out which branch you are on

Count the real source files (exclude `node_modules`, `.git`, lockfiles, build
output) and check `git log --oneline | wc -l`.

- **New project** — little or no code, few or no commits.
- **Old project** — an existing codebase with real history.

Say which one you picked and why, in one line. If it is genuinely ambiguous, treat
it as **old**: the old path does strictly more work, and doing more work on a
small project is cheap, while doing less on a large one leaves false documents
behind.

## Step 2 — Create the structure (both branches, identical)

```
agent-runs/
  upcoming/    tasks written but not started
  active/      the task being worked on right now
  done/        finished tasks, each with its archive
  README.md    the run log — one line per finished run, newest last

docs/
  maps/
    00-SYSTEMS.md     what connects to what
    01-FRONTEND.md    screens and components
    02-BACKEND.md     routes, jobs, server logic
    03-DATABASE.md    tables and columns
    04-DEAD-CODE.md   what exists but is not used any more
    flowcharts/
      README.md       the chart rules, and the numbered index
  CLAUDE-background.md   history and provenance — why things are the way they are
  CLAUDE-RULES.md        the numbered claim inventory and verification ledger

CLAUDE.md               the project's rules (created here if absent)
user.md                 who the user is, and how he wants to be spoken to
build-task.config.json  this project's settings for the procedure
.build-task-setup       the marker: date, branch taken, what was verified
```

Templates for every one of these are in `templates/` beside this skill. Copy them
and fill them in — do not invent a different shape.

**On a new project, create the maps as honest stubs**: "Empty — this project has
no backend yet." A stub that says what it is beats an absent file, because the
next session knows where the answer belongs. Never write a map that describes
code which does not exist.

Add `agent-runs/done/**/*.zip` to `.gitignore` (archives stay untracked), and
`.build-task-setup` stays tracked.

## Step 3 — Read what is already there

Read `CLAUDE.md` in full if one exists — all of it, not a skim. Also read any
`README.md`, and any existing docs folder. On a new project this may be nothing at
all, and that is a normal outcome.

## Step 4 — the branches diverge

### New project

There is nothing to verify, so the work is to establish the facts rather than
check them.

1. Write a first `CLAUDE.md` from the template, filling in only what you can
   actually see — the language, the framework, how it is run, how it is deployed
   if that is visible. **Leave anything you do not know as an explicit open
   question**, never as a plausible guess.
2. Write `docs/CLAUDE-RULES.md` with each claim numbered and marked `[v]` where
   you verified it from a file you read, `[?]` where you are recording the user's
   intention rather than something checked.
3. Collect everything you could not determine into one written questions file
   (Step 5).

### Old project

The point of this branch is that the documents and the code have probably drifted
apart, and nobody knows by how much.

1. **Verify `CLAUDE.md` against the code, claim by claim, structurally.** For
   every claim, check the mechanical version of it: does this file exist, does
   this route exist, does this table exist, is this command still in
   `package.json`. Mark each one in `docs/CLAUDE-RULES.md`:
   - `[v]` verified true, with `file.ext:line` and today's date
   - `[x]` verified false — say what is actually true instead
   - `[?]` could not be determined mechanically, with one line on what checking it
     properly would take
   **Do not try to verify claims of judgment or intent this way** — "we chose X
   because Y" is not checkable against code and belongs in
   `docs/CLAUDE-background.md`, marked `[?]`.
2. **Correct `CLAUDE.md` where you found it false.** Use the resolved-with-history
   form so nothing is silently rewritten:
   `~~the old claim~~ **RESOLVED <date> — what is actually true.**`
3. **Write the maps from the code**, not from `CLAUDE.md`: `00-SYSTEMS` (what
   connects to what), `01-FRONTEND`, `02-BACKEND`, `03-DATABASE`, `04-DEAD-CODE`.
   Every claim in a map cites `file.ext:line`. Anything you did not actually open
   goes in as "not yet mapped" rather than as a guess.
4. **Stay inside a budget.** This is a survey, not an audit: aim for the
   structural shape of the project, and stop when a further hour would add detail
   rather than change the picture. What you did not cover is written down as "not
   yet mapped", and the first task that touches that area maps it properly. Say in
   the report roughly how much of the project you covered.

**The `[?]` marks are the whole point.** From here on, the build-task procedure
forbids relying on a `[?]` claim without verifying it first, so an honest `[?]`
today is what makes every later task safe. A `[v]` you did not really check is
worse than useless.

## Step 5 — Ask your questions, in writing

Whatever you could not determine, ask. Not in chat as a wall of text — **write a
file** (`SETUP-QUESTIONS.md` in the repo root, or a PDF if he prefers) so he can
answer at his convenience.

Rules for that file, because he is not a coder:

- One question per numbered item, in plain English, no file paths or jargon.
- Say **why it matters** in one line — what changes depending on his answer.
- **Give your recommendation** where you have one, so he can reply "yes" instead
  of composing an answer.
- Never ask him something you could determine yourself by reading the code. Check
  first; ask only about intent, preference, and things outside the repo.
- **If you need a key, secret or connection string, name it exactly and say what
  it is for.** He will paste it in. Never guess one, never proceed as if you had
  it, and never write its value into any file that gets pasted into a chat.

Then **stop and wait.** Setup is not finished until he has answered — folding his
answers back into `CLAUDE.md` and the maps is the last part of this step, not a
follow-up task.

## Step 6 — Connect the shared history

The procedure logs one row per finished run to a shared Supabase table, so
projects can learn from each other. Check whether `BUILD_TASK_SUPABASE_URL` and
`BUILD_TASK_SUPABASE_KEY` are set (environment, or `~/.claude/build-task/env`).

- **Both present** — do a single read to confirm they work, and say so.
- **Missing** — say so plainly in the report, point him at the plugin's
  `SETUP.md`, and continue. It is not a blocker: the procedure works without it
  and just doesn't remember across projects.

## Step 7 — Write the marker and report

`.build-task-setup` records: the date, which branch was taken, how many claims
were marked `[v]`/`[x]`/`[?]`, roughly how much of the project was mapped, and
whether the shared history is connected.

Then report to the user in plain English:

1. Which branch this was, and why
2. What was created — the folder list, in words
3. **What was found to be untrue** — its own heading, always present. On an old
   project this is the most valuable output of the whole setup: the things his
   own documents claimed that the code does not do. Write "nothing" if nothing
   was.
4. What was left unverified, and roughly how much of the project that is
5. What you need from him — the questions file, and any keys
6. Whether the shared history is connected

Commit everything with a clear message. **Do not push** unless he asks — setup on
an old project can touch a lot of files, and he should see it first.
