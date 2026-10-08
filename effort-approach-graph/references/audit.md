# Audit the graph

A slug is built from the wording of its state, so two framings of one state come out as two slugs and the graph forks without anyone noticing. Finding these **duplicates** is most of the judgment here. Two nodes are duplicates when they name one state, even though their wording, word order or detail differ. A sharper wording counts: when one names the same state with a threshold or detail the other leaves open, so that it implies the other, they are one node. When each could hold while the other fails, they overlap and stay two nodes. A state that is part of another is a child of it, not its duplicate.

Every edit found here touches efforts that others may own, and a wrong edge spreads to every record that walks the graph. So propose the edits, and leave applying them to the user or the calling skill.

1. **Settle each problem the script printed.**
   - **Several files carry one slug.** When they name the same state, propose the file to keep and what of the other's criteria, limits and approaches moves into it. When they name different states, propose a new slug for one.
   - **A slug is worded differently in two places.** Propose the file's wording everywhere, since the file is where the effort is defined. Between two lines without a file, propose the clearer wording.
   - **A `contributes-to:` slug names no effort.** It is a renamed or misspelled node, so rename the entry, or an effort nobody wrote, so propose removing the entry or writing the effort.
   - **A `contributes-to:` list names an approach its parent does not list.** The approach was renamed, or the child names one nobody wrote. Propose renaming it to the parent's approach it serves, or removing it from the list.
   - **An Approaches line names no approach file.** The approach was renamed, or nobody wrote it. Propose renaming the line to the approach file it meant, or writing the approach. Never propose removing the line: it records the effort's decision on that approach.
   - **An effort lists an approach whose `contributes-to:` does not name it.** Propose adding the effort to the approach's `contributes-to:`, with a `### <effort>` heading under its Covers naming what it covers there. Adding an effort changes nothing for the efforts already served, so it needs no decision, even when another effort has chosen the approach.
   - **An approach shares its slug with an effort or another approach file.** Propose a new slug for the approach, and the same rename on every line naming it.
   - **A step's `(<effort>, ...)` names an effort that does not cover it.** The step names a renamed effort, or one that serves none of the approach's efforts through this approach or whatever the approach. Propose naming the effort that covers the step, or adding the approach to that effort's `contributes-to:` list for one of the approach's efforts.
   - **A Serves entry names a criterion its parent lacks.** The parent's criterion was renamed or removed. Propose renaming the entry to the parent criterion it now moves, or removing the entry when it moves none.
   - **A cycle.** Find the edge whose child does not help bring about its parent and propose removing it.
2. **Find the duplicates.** Compare every node with every other, and put each pair of duplicates in one group, testing every pair for overlap. For each group, keep the slug that has a file, or else the one that appears in the most places, and propose renaming every other place to it. When two members of a group both have files, the user decides how they merge, so the group's line reads `- <slug>, <slug>: merge to decide`, and no edit renames or moves anything between them.

## Output

The answer is this block alone, with no sentence before or after it, and every line in its template's shape.

```
duplicates:
- <kept slug>: <the other slugs>
edits:
- <path>[:<line>]: <the change>
```

Write `none` as the whole value of an empty field, as in `edits: none`. Edits change existing files, and each names one change someone could make without reading anything else: add `<slug>: []`, or `<slug>: [<approach>, ...]`, to `contributes-to:`, rename `<old>` to `<new>`, remove an entry. Take each edit's path and line from the script's output, which counts lines within each file.
