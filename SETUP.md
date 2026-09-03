# Setting this up

Written for someone who does not want to think about code. Follow it in order;
it should take about fifteen minutes, once, ever.

There are two halves: **the notebook** (a small free database that every project
writes its history into) and **the plugin** (the procedure itself).

---

## Part 1 — Make the notebook

### 1. Create a new Supabase project

1. Go to **supabase.com** and sign in.
2. Click **New project**.
3. Name it something obvious — `build-task-history`.
4. It will ask you to set a database password. Set one and save it somewhere.
   You will not need it for this, but you would need it later if you ever wanted
   to connect directly.
5. Pick the region closest to you and create it. It takes a minute or two to
   finish setting itself up.

This is deliberately **separate from CAprep's database**. Your study data and your
build history have nothing to do with each other and should not share a home.

### 2. Create the table

1. In the left sidebar of your new project, open the **SQL Editor**.
2. Click **New query**.
3. Open `db/schema.sql` from this repository, copy all of it, and paste it in.
4. Click **Run**.

You should see a success message. That has created one table, `build_runs`, and
locked it so that rows can be **added and read but never edited or deleted**. That
is on purpose — it is what makes the history trustworthy rather than something a
session could quietly tidy up.

### 3. Copy the two values you need

1. In the left sidebar, open **Project Settings**, then the **API** section — the
   page that shows your **Project URL** and your **API keys**.
2. Copy the **Project URL**. It looks like `https://abcdefgh.supabase.co`.
3. Copy the **anon / public** key (sometimes now labelled *publishable*). It is
   the long one explicitly marked as safe to use in a client. **Do not use the
   service role / secret key** — that one can do anything, and nothing here needs
   it.

### 4. Save them where Claude Code can find them

**On your own machine**, create a file at `~/.claude/build-task/env` containing
exactly two lines:

```
BUILD_TASK_SUPABASE_URL=https://abcdefgh.supabase.co
BUILD_TASK_SUPABASE_KEY=paste-the-anon-key-here
```

**For remote sessions (the iPad)**, add those same two as environment variables in
your Claude Code environment settings, since a file on your laptop is not visible
from there. Both halves have to be done for the history to work from both places.

> **What this key can do, plainly.** Anyone holding it can add rows to this one
> table and read them back. It cannot touch anything else, and it cannot edit or
> delete what is already there. That is why the history holds only run
> descriptions and lessons — **never a password, a key, or a connection string.**
> The procedure has a standing rule against writing secrets into it.

---

## Part 2 — Install the plugin

In Claude Code, run:

```
/plugin marketplace add riddhimjainsandeep-eng/build-task
/plugin install build-task@riddhim-tools
```

That is it. It is now available in every project, and updates to it reach every
project the same way.

---

## Part 3 — Using it in a project

**The first time, in each project**, run:

```
/build-setup
```

This creates the standard folders, reads your `CLAUDE.md` against the actual code
to find out which parts are still true, writes the system maps, and then asks you
— in a written file, in plain English — about anything it could not work out for
itself. It only ever runs once per project.

**From then on**, every task is:

```
/build <task-name>
```

And to look at what has happened across all your projects:

```
/build-history
/build-history summary
/build-history sync
```

---

## The two kinds of update

- **Global** — a change to the procedure itself: a new phase, a changed rule, a
  better way of working. That lives in this repository, and reaches every project
  when the plugin updates.
- **Internal** — a change to one project's own rules, maps or config. That lives
  in that project's own `CLAUDE.md`, `docs/` and `build-task.config.json`, and
  affects nothing else.

Keeping them apart is the point. A lesson you learn in one project should not
quietly rewrite the procedure for all of them, and a fix to the procedure should
not need copying into six repositories by hand.

---

## If something does not work

- **`/build-history` says the history is not set up** — the two values in Part 1
  step 4 are missing or misspelled in whichever environment you are in. Remember
  that the laptop and the iPad need them set separately.
- **A run finishes but nothing appears in the history** — that is by design: the
  logging step never blocks a run. The report will contain one line saying it
  could not write, and why.
- **`/build` says the project has never been set up** — run `/build-setup` first.
