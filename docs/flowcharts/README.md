# Flowcharts — how this system works

Six diagrams. Read them in order the first time; after that, jump to whichever
one answers the question you have.

Every file is Markdown with a Mermaid diagram, so it renders in GitHub, in most
Markdown viewers, and on an iPad.

| # | File | The question it answers |
|---|---|---|
| 01 | [The whole system](01-the-whole-system.md) | What are the pieces, and what is shared between projects? |
| 02 | [First time in a project](02-first-time-in-a-project.md) | What happens when this lands in a project — new or existing? |
| 03 | [A task, start to finish](03-a-task-start-to-finish.md) | What actually happens when I run `/build`? |
| 04 | [How claims get checked](04-how-claims-get-checked.md) | How does it know the notes are still true? |
| 05 | [The shared notebook](05-the-shared-notebook.md) | What gets remembered across projects, and what can never happen to it? |
| 06 | [Two kinds of update](06-two-kinds-of-update.md) | Does this change belong to the procedure, or to one project? |

## The rules these follow

Kept deliberately, because a diagram that breaks them stops being faster to read
than the paragraph it replaced:

- **Plain everyday language.** If a box needs a technical term to make sense, the
  diagram is pitched at the wrong level. Where a term is unavoidable, it is
  explained immediately below the paragraph that uses it, marked with an
  asterisk — never in a glossary at the bottom.
- **Short boxes.** A few words. A box needing a sentence should be two boxes.
- **No crossing arrows.** If arrows have to cross, the layout is wrong.
- **One diagram per file.** A file needing two diagrams is two files.
- **Every diagram is followed by its reasoning** — not just what happens, but why
  it was built this way and what the rejected alternative would have cost.

These same rules apply to the flowcharts written inside each of your projects, in
`docs/maps/flowcharts/`.
