# Upgrading to build-task 2.0

## For the person (2 minutes)

You don't need to understand any of this. Do these three things:

1. Open **Claude Code**.
2. Copy everything inside the grey box below (from `You are helping me upgrade` to the
   end of the box) and paste it into Claude Code as your message.
3. Answer its questions. It will ask you a few simple things about how you'd like
   reports written, and it will ask before installing anything.

When it's finished, **close Claude Code and open it again**. That's it.

**After the upgrade:**
- To get work done, type `/build-task:build` followed by what you want, in plain words.
  `/build-v1`, `/build-v2` and `/build-fast` no longer exist; `/build` does everything.
- If you are stepping away, type **"I'm going AFK"**. It will keep working, take a backup
  before anything risky, and tell you afterwards how to undo it.
- It will always ask you before doing anything serious, in plain words.

---

## For Claude Code — paste this whole box

```
You are helping me upgrade the "build-task" Claude Code plugin to version 2.0. I am not a
programmer: explain everything in short, plain sentences, never show me code unless I ask,
and ask me before installing anything or changing any file outside the steps below.

Do these steps in order and tell me in one line when each is done.

1. Python 3 (build-task 2.0 needs it; nothing else to install).
   Run: python --version ; python3 --version ; py -3 --version
   - If one prints "Python 3.x", note which one works and continue.
   - If none works: tell me plainly that Python is missing and ASK before installing it.
     On Windows, with my yes, run: winget install -e --id Python.Python.3.12
     Then ask me to close and reopen Claude Code, and start again from step 1.

2. Update the plugin.
   Run: claude plugin marketplace update riddhim-tools
   Then: claude plugin update build-task@riddhim-tools
   If "riddhim-tools" is not found, run first:
     claude plugin marketplace add riddhimjainsandeep-eng/build-task
     claude plugin install build-task@riddhim-tools
   Confirm the installed version is 2.0.0 (claude plugin list).
   If anything fails, stop and show me the exact error message in one line.

3. My projects. Ask me which folders I use build-task in (or look for folders that
   contain "agent-runs" and ".build-task-setup" and list them for me to confirm).
   For each one I confirm:
   a. Open its user.md. This file says who the work is for. If it describes someone
      else (for example it names "Riddhim Jain" or says "CA student"), it was copied
      from the plugin author's own profile by an older version and is wrong for me.
      Ask me these questions once, in plain words, and use my answers for every project:
        - Who is this work for (my name and role)?
        - Can I read and check code? (yes / a little / no)
        - How should reports be written for me? (short or detailed, language, tone)
        - Anything else I care about (cost, being asked before changes, privacy)?
      Then rewrite user.md from the plugin's template at
      <plugin folder>/skills/build-setup/templates/user.md, filled with my answers.
      Show me the result in a few lines and ask if it is right before saving.
   b. Do NOT build the project index now. The first time I run /build-task:build in a
      project, it will notice the index is missing, tell me the one-time cost, and make it.
   c. Commit only the user.md change, with the message "user.md: who this work is for".
      Do not push unless I say so.

4. Finish by telling me, in at most five short lines:
   - that the upgrade is done, and the version;
   - that I must close and reopen Claude Code;
   - how to run a task: /build-task:build <what I want, in plain words>;
   - that /build-v2 and /build-v1 are gone;
   - that I can say "I'm going AFK" when I step away.
```

---

## What changed in 2.0 (for anyone curious)

See the "2.0.0 — what changed" section of [README.md](README.md). In short: one build-task
instead of three, a per-project index so runs read only what they need, one helper command
that does the mechanical steps, and clear rules for when it may change its plan.
