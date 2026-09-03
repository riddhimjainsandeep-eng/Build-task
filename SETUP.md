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

There are two routes and they end in exactly the same place. Pick whichever suits
you.

### Route A — inside Claude Code (you get asked for the values)

```
/plugin marketplace add riddhimjainsandeep-eng/build-task
/plugin install build-task@riddhim-tools
```

Then open `/plugin`, find **build-task**, and choose configure. **A settings box
asks for the two values from Part 1.** Paste them in. The key field is masked as
you type.

Use this route if you would rather be asked than type the key into a command.

### Route B — from PowerShell or any terminal (you supply the values)

```powershell
claude plugin marketplace add riddhimjainsandeep-eng/build-task
claude plugin install build-task@riddhim-tools --config supabase_url=https://abcdefgh.supabase.co --config supabase_key=paste-the-anon-key-here
```

Be aware this route puts the key into your shell history, since you typed it as
part of a command. On a personal machine that is usually fine; if it bothers you,
use Route A.

### What you will actually see

Not much, and that is normal. No progress bars, no unzipping animation, no
questions. Roughly this:

```
Adding marketplace…Cloning via HTTPS: https://github.com/...
√ Successfully added marketplace: riddhim-tools
Installing plugin "build-task@riddhim-tools"...√ Successfully installed (scope: user)
```

**It does not ask whether to install globally or into one folder.** It installs
for your whole user account by default, which is what you want — available in
every project. Only pass `--scope project` if you ever deliberately want it in
one folder.

### After that, nothing is left to do by hand

The two values are stored by Claude Code itself: the URL in your settings, and
the key in your system's secure credential storage rather than a plain text file.
The first time a session starts, the plugin writes them to
`~/.claude/build-task/env` — locked so only your user account can read it — which
is where the history scripts look.

You can leave both fields blank if you want to try the procedure first. It works
fine without a shared history; it simply does not remember anything across
projects. Fill them in later through `/plugin`.

**Do this on each machine you use.** The iPad and your laptop are separate
installs, because a setting saved on one is not visible to the other.

### Checking it worked

```
claude plugin list
```

You want to see `Status: √ enabled`. If it says **failed to load**, the plugin
installed but is doing nothing — read the error line, which names the cause.

### If you ever need to write the file yourself

This is what the steps above produce, so you can create it by hand instead:

`~/.claude/build-task/env`

```
BUILD_TASK_SUPABASE_URL=https://abcdefgh.supabase.co
BUILD_TASK_SUPABASE_KEY=paste-the-anon-key-here
```

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
