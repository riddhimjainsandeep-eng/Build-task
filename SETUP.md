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

Keep both values on your clipboard or somewhere handy — Part 2 asks you for them.

> **What this key can do, plainly.** Anyone holding it can add rows to this one
> table and read them back. It cannot touch anything else, and it cannot edit or
> delete what is already there. That is why the history holds only run
> descriptions and lessons — **never a password, a key, or a connection string.**
> The procedure has a standing rule against writing secrets into it.

---

## Part 2 — Install the plugin

In Claude Code, run these two lines:

```
/plugin marketplace add riddhimjainsandeep-eng/build-task
/plugin install build-task@riddhim-tools
```

**A settings box will come up asking for the two values from Part 1** — the
project URL and the anon key. Paste them in. The key field is masked as you type
and is stored in your system's secure storage, not in a plain settings file.

That is the whole setup. You do not have to create or edit any file by hand.

You can leave both fields blank if you want to try the procedure first — it works
fine without a shared history, it simply does not remember anything across
projects. Re-open the plugin's settings later to fill them in.

**Do this on each machine you use.** The iPad and your laptop are separate
installs and each asks once, because a setting saved on one is not visible to the
other.

### If the settings box does not appear

Some versions may not prompt. In that case create the file yourself — this is
exactly what the box would have written:

`~/.claude/build-task/env`

```
BUILD_TASK_SUPABASE_URL=https://abcdefgh.supabase.co
BUILD_TASK_SUPABASE_KEY=paste-the-anon-key-here
```

Both routes end in the same place, and the procedure reads whichever it finds.

---

## Part 3 — Using it in a project

**The first time, in each project**, run:

```
/build-task:build-setup
```

This creates the standard folders, reads your `CLAUDE.md` against the actual code
to find out which parts are still true, writes the system maps, and then asks you
— in a written file, in plain English — about anything it could not work out for
itself. It only ever runs once per project.

**From then on**, every task is:

```
/build-task:build <task-name>
```

And to look at what has happened across all your projects:

```
/build-task:build-history
/build-task:build-history summary
/build-task:build-history sync
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

- **`/build-task:build-history` says the history is not set up** — the two values in Part 1
  step 4 are missing or misspelled in whichever environment you are in. Remember
  that the laptop and the iPad need them set separately.
- **A run finishes but nothing appears in the history** — that is by design: the
  logging step never blocks a run. The report will contain one line saying it
  could not write, and why.
- **`/build-task:build` says the project has never been set up** — run `/build-task:build-setup` first.
