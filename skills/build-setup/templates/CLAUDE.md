# CLAUDE.md — <project name>

> **Single source of truth. Read fully before writing code.** Every claim here is
> numbered and marked in `docs/CLAUDE-RULES.md` as verified, false, or unverified.
> **A claim marked `[?]` may not be relied on until it has been checked against
> the code.** History and provenance live in `docs/CLAUDE-background.md`.

---

## WHAT IS THIS PROJECT?

<One paragraph, plain English: what it does and who it is for. If this is a new
project, write the intention and mark it `[?]` — it is not yet a fact about code.>

---

## TECH STACK

<Language, framework, versions. Only what is actually in the dependency file —
never what a project of this kind usually uses.>

### Environment variables

```
<NAME>    what it is for
```

**Names only. Never a value.**

---

## HOW TO RUN IT

- **Install:** <command>
- **Develop:** <command>
- **Build:** <command>
- **Test:** <command>

---

## PROJECT STRUCTURE

```
<the real tree, trimmed to what matters>
```

---

## HOW THINGS ARE DONE HERE

<Conventions a new session would otherwise get wrong: naming, patterns, where
things go, what is deliberately not done. Add only what would actually be got
wrong without it — this file is charged on every turn of every session.>

---

## LANDMINES

<Anything fragile. Things that look wrong but are deliberate. Things that break
silently. Each one with the evidence for why it is here.>

---

## WHAT NOT TO BUILD

<Explicit non-goals, so they are not re-proposed every few months.>

---

## Build procedure

Any task that modifies this codebase runs through the **build-task** skill — all
six phases, in order, no exceptions. Invoke with `/build-task:build <task-name>`.

## Working conventions

- Task artifacts live in `agent-runs/active/<date>_<task>/`. Never in the repo
  root.
- Commit freely during a task; **Phase 5 pushes**, not before.
- Never put a secret value in any file that gets pasted into chat.
