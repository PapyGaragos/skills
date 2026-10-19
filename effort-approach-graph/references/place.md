# Place one effort

The input is one effort: a line, a file, or a wanted state not framed yet. An effort extracted from another effort's criterion or limit arrives with the effort it came from.

A slug is built from the wording of its state, so two framings of one state come out as two slugs and the graph forks without anyone noticing. Finding these **duplicates** is most of the judgment here. Two nodes are duplicates when they name one state, even though their wording, word order or detail differ. A sharper wording counts: when one names the same state with a threshold or detail the other leaves open, so that it implies the other, they are one node. When each could hold while the other fails, they overlap and stay two nodes. A state that is part of another is a child of it, not its duplicate.

Every edit found here touches efforts that others may own, and a wrong edge spreads to every record that walks the graph. So propose the edits, and leave applying them to the user or the calling skill.

1. **Find its duplicate.** Look for a node that names the same state under any slug. An effort extracted from a limit line is that line's node, so it keeps that slug.

2. **Find its parents.** A parent is a node whose state this effort's state helps bring about. Judge it on the parent's intent, and on its definition of done when it has a file, since reaching this state should move what the parent counts as progress. Keep the direct parents and drop a node reached only through one of them. When the parent's file lists approaches, the edit adding the parent names the ones this effort serves, or none when it serves the parent whatever the approach. An effort extracted from a criterion already has the effort it came from as a parent. An effort extracted from a limit keeps its respects edge, which is the Limits line itself, and gets its parents like any other.

3. **Find its children.** A child is a node whose state helps bring this one about, by the same test turned around. A child without its own file has no `contributes-to:` to record the edge in, so it gets no edit.

Limits come from the request and from the efforts' own files. Record the respects edges found there, and add none, since a limit invented here would bind work nobody agreed to bind.

## Result

The result holds the duplicate, the parents, the children and the edits. `duplicate:` names the node that already carries this state, which for an effort extracted from a line is that line's own node. A parent or child that neither the input nor the files name is a guess. An edge a file already records is not. Edits change existing files, the placed effort's own file included when it has one, and each names one change someone could make without reading anything else: add `<slug>: []`, or `<slug>: [<approach>, ...]`, to `contributes-to:`, rename `<old>` to `<new>`, remove an entry. Take each edit's path and line from the script's output, which counts lines within each file.

Then pick how to give it from the Output section of this skill's SKILL.md.
