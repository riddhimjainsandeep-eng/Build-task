---
description: Set up this project for the build-task procedure (first run only)
---

Set this project up using the **build-setup** skill.

If `.build-task-setup` already exists, do not run again — say when it last ran,
what it recorded, and ask whether the user actually wants a re-run before doing
anything.

Otherwise follow the skill in order: work out whether this is a new or an old
project and say which, create the standard folders and documents from the
templates, read and verify `CLAUDE.md` against the real code, write the maps from
what the code actually does, and collect everything you could not determine into
a written questions file for the user — numbered, plain English, each with your
recommendation.

Then stop and wait for his answers. Setup is not finished until they are folded
back in.

Commit the work with a clear message. **Do not push** unless he asks.
