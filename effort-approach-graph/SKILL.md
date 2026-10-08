---
name: effort-approach-graph
description: Place an effort in the graph that efforts and their approaches form through `contributes-to:` and limits, counting the slugs named inside effort files as well as the files. Finds the node that already names the same state, the efforts it serves and the efforts that serve it, with the parent's approaches each one serves, shows which approaches each effort has and with what status, and which efforts serve each approach, or audits the whole graph for duplicate slugs, cycles and broken links, approach files included, and proposes the edits without making them. Use when an effort is filed or extracted from another effort's criterion or limit, when the user asks what an effort serves or what serves it, which approaches an effort has, or which children an approach relies on, suspects two slugs name the same effort, or wants effort or approach files checked for problems, fixed or cleaned up, and whenever another skill needs an effort's parents, children, approaches or existing slug.
---

# Effort graph

Efforts form a graph whose nodes are slugs. A slug is a node whether it has its own `<slug>-effort.md` or only appears as a line in another effort's Limits. An approach, a way to reach efforts written in its own `<slug>-approach.md`, is a node too. Three kinds of edge join them:

- **Contributes.** The child helps bring about the parent. The child's `contributes-to:` entry draws it, and lists the approaches of the parent's `## Approaches` it serves, `[]` when it serves the parent whatever approach is taken.
- **Respects.** An effort's Limits line names a state that must hold while the effort is pursued. A limit bounds the effort rather than serving it, so it stays out of `contributes-to:`.
- **Reaches.** The approach's `contributes-to:` list names the efforts it serves, and its `## Covers` section the criteria it covers in each. Each effort's `## Approaches` section gives the approach its status there: `chosen`, `candidate` or `dropped`, several possibly chosen.

The graph lives in the files. Rebuild it from them on every run, since a stored copy goes stale as soon as one file changes.

## Read the graph

Run `scripts/effort-approach-graph.sh` from this skill's directory, with `--root DIR` when the efforts live outside the working directory. It prints every node with each place it appears, its chosen approaches and the criteria none of them covers, each approach with its lead line and its children (the efforts whose `contributes-to:` names it), every edge with the approaches it serves or the status its effort gives the approach, the children serving each criterion of an effort's definition of done, and the problems a script can find. A child counts toward its parent's criteria when it serves the parent whatever the approach, or serves one of the chosen ones, or, with none chosen, one not dropped. A criterion no chosen approach covers is a gap of the effort, not a problem. A child serving only another approach is listed apart under `serves another approach`: it is no problem and gets no edit, since efforts, approaches and logbooks stay so that a switch back finds what was already done. An approach reaching an effort whose section does not list it yet shows as `proposed`: the effort has not considered it yet, which is no problem either and gets no edit. Whether two slugs name the same state is left to you.

## Place or audit

This skill, with refined-approach-efforts, is responsible for plugging efforts and approaches correctly into the rest of the graph. To place one effort in the graph, finding its duplicate, parents and children, read `references/place.md` and follow it. To audit the graph, settling each problem the script prints and finding the duplicates, or to judge whether two slugs name one state, read `references/audit.md` and follow it. Each gives the output for its mode.
