# Logbook notation

Read this to make sense of a `.logbook` file opened directly. `scripts/logbook.sh` writes the notation, so writing never needs it.

A logbook is plain text. Each line is a node: indentation (two spaces per level) places it under its parent, then comes a marker, a space and the text. Top-level nodes are goals, which are todos like any other.

## Markers

| marker | node | meaning |
|---|---|---|
| `-` | todo | planned; comes after the `-` sibling above it |
| `=` | todo | planned; can run in any order with its `=` siblings |
| `>` | todo | in progress |
| `.` | todo | done |
| `x` | todo or option | dropped todo, or ruled-out option |
| `#` | note | one fact: context, source, justification |
| `!` | surprise | something unexpected, possibly a problem, with any steps to fix or bypass it underneath |
| `!!` | blocker | something in the way |
| `??` | question | something to find out |
| `?` | option | a candidate answer to a question or blocker |
| `=>` | decision | the answer chosen, or an option confirmed |

## What goes where

| parent | children it accepts |
|---|---|
| top level, todo | todo, note, surprise, blocker, question |
| question, blocker | todo, note, surprise, option, decision |
| option, decision, surprise | todo, note, surprise |
| note | nothing |

A question or blocker is resolved once it has a decision child. An option still `?` under a resolved question was not chosen but not ruled out either, so it could come back later. A ruled-out option carries a note saying why.

## What changes

Nodes are only ever appended, as the last child of their parent, so a node keeps its path (`2.1` = first child of the second goal) for the life of the file. Text never changes. Only markers do:

- todo: `-` or `=` to `>`, `.` or `x`; `>` to `.` or `x`
- option: `?` to `=>` (confirmed) or `x` (ruled out)

A todo becomes `>` as soon as work starts under it, and `.` only once none of its todo children is open.
