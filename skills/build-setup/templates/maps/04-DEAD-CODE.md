# 04 — Dead code and deliberate leftovers

> What exists but is not used, and **why it is still here**. The reason matters
> more than the list: without it, every few months someone proposes deleting
> something that is load-bearing for a reason nobody wrote down.

*Last verified: YYYY-MM-DD*

## Not used, safe to remove

<Cite `file.ext:line`. Say how you established nothing calls it.>

## Not used, deliberately kept

<Why. Historical data, a dormant feature, something an external process still
touches.>

## Looks dead but is not

<The dangerous category. Anything called from outside the codebase — a scheduler,
a webhook, a database trigger, another machine — that a reference search will not
find.>

## Changelog

- YYYY-MM-DD — created during setup.
