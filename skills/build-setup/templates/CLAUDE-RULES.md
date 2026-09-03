# Claim inventory and verification ledger

Every claim in `CLAUDE.md`, numbered, with whether it has actually been checked
against the code.

**This file has two jobs.** It makes "nothing was removed" verifiable when
`CLAUDE.md` is trimmed, and it is the ledger the build procedure reads before
relying on anything.

## The marks

| Mark | Meaning |
|---|---|
| `[v]` | Verified against the code. Cite `file.ext:line` and the date checked. |
| `[x]` | Checked and **false**. Say what is actually true. `CLAUDE.md` should already be corrected. |
| `[?]` | Not verified. **May not be relied on until checked.** |

**The rule that makes this worth maintaining:** when a phase is about to depend on
a `[?]` claim, it verifies that one claim first and updates the mark and date in
the same run. Setup marks the structural claims; every task afterwards verifies
what it actually touches.

A `[v]` written without really checking is worse than a `[?]` — it converts an
open question into a false certainty, and nothing downstream will ever re-check
it.

---

## Inventory

| # | Claim (short) | `CLAUDE.md` line | Mark | Evidence | Date |
|---|---|---|---|---|---|
| 1 | <claim> | L12 | `[v]` | `src/app.ts:40` | YYYY-MM-DD |
| 2 | <claim> | L18 | `[?]` | would need a live run to confirm | YYYY-MM-DD |

## Summary

- Verified: 0
- False (corrected): 0
- Unverified: 0
- Last full pass: YYYY-MM-DD (setup)
